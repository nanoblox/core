-- This is responsible for handling player effects which can stack and/or where the original value needs to be remembered

local Agent = {}
Agent.__index = Agent

local main = require(game.Nanoblox)
local Buff = require(script.Buff)
local Maid = main.modules.Maid
local sortBuffsByTimeUpdatedFunc = function(buffA, buffB) return buffA.timeUpdated > buffB.timeUpdated end
local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local effects = require(script.Buff.Effects)
local bodyUtilPathway = script.Buff.BodyUtil



-- LOCAL FUNCTIONS
local function isSuperiorWeight(baseBuff, toCompareBuff)
	if baseBuff == nil then
		return true
	end
	local baseWeight = baseBuff.weight
	local toCompareWeight = toCompareBuff.weight
	if toCompareWeight > baseWeight or (toCompareWeight == baseWeight and toCompareBuff.timeUpdated > baseBuff.timeUpdated) then
		return true
	end
	return false
end



-- CONSTRUCTOR
function Agent.new(player, reapplyBuffsOnRespawn)
	local self = {}
	setmetatable(self, Agent)
	
	local maid = Maid.new()
	self._maid = maid
	self.reduceMaids = {}
	self.buffs = {}
    self.defaultValues = {}
	self.reapplyBuffsOnRespawn = reapplyBuffsOnRespawn
	self.silentlyEndBuffs = false
	self.player = player
	self.groupedBuffs = {}
	self.humanoidDescriptionCount = 0
	self.humanoidDescription = nil
	self.applyingHumanoidDescription = false

	maid:give(player.CharacterAdded:Connect(function(char)
		if reapplyBuffsOnRespawn then
			self:clearDefaultValues()
			self:reduceAndApplyEffects()
		else
			self:assassinateBuffs()
		end
	end))

	maid:give(players.PlayerRemoving:Connect(function(leavingPlayer)
		if leavingPlayer == player then
			self:destroy()
		end
	end))

	return self
end



-- METHODS
function Agent:buff(effect, weight)
	local buff = Buff.new(effect, weight)
	local buffId = buff.buffId
	buff.agent = self
	buff.updated:Connect(function(specificEffect)
		self:reduceAndApplyEffects(specificEffect)
	end)
	self.buffs[buffId] = buff
	return buff
end

function Agent:getBuffs()
	local buffs = {}
	for buffId, buff in pairs(self.buffs) do
		table.insert(buffs, buff)
	end
	table.sort(buffs, sortBuffsByTimeUpdatedFunc)
	return buffs
end

function Agent:getBuffsWithEffect(effect)
	local buffs = {}
	for buffId, buff in pairs(self.buffs) do
		if buff.effect == effect then
			table.insert(buffs, buff)
		end
	end
	table.sort(buffs, sortBuffsByTimeUpdatedFunc)
	return buffs
end

function Agent:updateBuffGroups()
	-- This organises buffs into groups by effect and additonal value
	local groupedBuffs = {}
	for buffId, buff in pairs(self.buffs) do
		local group = groupedBuffs[buff.effect]
		if not group then
			group = {}
			groupedBuffs[buff.effect] = group
		end
		local additionalString = tostring(buff.additional)
		local additionalTable = group[additionalString]
		if not additionalTable then
			additionalTable = {}
			group[additionalString] = additionalTable
		end
		table.insert(additionalTable, buff)
	end
	self.groupedBuffs = groupedBuffs
end

function Agent:_getDefaultGroup(effect, instance)
	local defaultParentGroup = self.defaultValues[effect]
	if defaultParentGroup == nil then
		defaultParentGroup = {}
		self.defaultValues[effect] = defaultParentGroup
	end
	if instance.ClassName == "HumanoidDescription" then
		-- HDs constantly change therefore we reference the Humanoid instead to remember the values
		instance = self.player.Character.Humanoid
	end
	local defaultGroup = defaultParentGroup[instance]
	if defaultGroup == nil then
		defaultGroup = {}
		defaultParentGroup[instance] = defaultGroup
	end
	return defaultGroup
end

function Agent:clearDefaultValues()
	self.defaultValues = {}
	local buffs = self:getBuffs()
	for _, buff in pairs(buffs) do
		buff.appliedValueTables = {}
	end
	for tweenReference, reduceMaid in pairs(self.reduceMaids) do
		reduceMaid:destroy()
		self.reduceMaids[tweenReference] = nil
	end
end

function Agent:reduceAndApplyEffects(specificEffect)
	self:updateBuffGroups()
	local humanoidDescription
	local humanoidDescriptionInstance
	local changedDescProperty
	for effect, additionalTable in pairs(self.groupedBuffs) do
		if not(specificEffect == nil or effect == specificEffect) then
			continue
		end
		
		for additionalString, buffs in pairs(additionalTable) do
			
			-- This retrieves a nonincremental buff with the greatest weight. If only incremental buffs exist, the one with the highest weight is chosen.
			-- The boss then determines how other buffs will be applied (if at all)
			local bossBuff
			local totalBuffs = #buffs
			for _, buff in pairs(buffs) do
				if (not buff.isDestroyed or totalBuffs <= 1) and (bossBuff == nil or (not buff.incremental and bossBuff.incremental) or (buff.incremental == bossBuff.incremental and isSuperiorWeight(bossBuff, buff))) then
					bossBuff = buff
				end
			end
			if bossBuff == nil then
				for _, buff in pairs(buffs) do
					if isSuperiorWeight(bossBuff, buff) then
						bossBuff = buff
					end
				end
			end

			local isIncremental = bossBuff.incremental
			local isNumerical = type(bossBuff.value) == "number"
			
			-- This determines whether to tween the final value and cancels any other currently tweening values
			local finalValueTweenInfo = bossBuff.tweenInfo
			local tweenReference = tostring(effect)..additionalString
			local reduceTweenMaid = self.reduceMaids[tweenReference]
			local forcedBaseValue
			if reduceTweenMaid then
				reduceTweenMaid:clean()
				local validUntilTime = reduceTweenMaid.forcedBaseValueValidUntilTime
				if validUntilTime then
					if os.clock() < validUntilTime then
						forcedBaseValue = reduceTweenMaid.forcedBaseValue
					end
					rawset(reduceTweenMaid, "forcedBaseValueValidUntilTime", nil)
					rawset(reduceTweenMaid, "forcedBaseValue", nil)
				end
			elseif tweenReference then
				reduceTweenMaid = self._maid:give(Maid.new())
				self.reduceMaids[tweenReference] = reduceTweenMaid
			end
			
			-- This retrieves the associated instances then calculates and applies a final value
			-- The default value should only be for only remembering non-numerical values (such as colors, materials, etc)
			-- This is due to numerical based properties having a greater tendency to change on their own (such as Health regeneration)
			-- For numerical values we instead records its 'difference' to deterine the previous value when a buff is removed
			local instancesAndProperties
			local effectData = effects[effect]
			if effectData then
				instancesAndProperties = effectData(self.player, additionalString)
			else
				-- If an effect is not found, instead reference the player's HumanoidDescription
				-- It's important HumanoidDescription values are classed as non-numerical since
				-- the H.D. is only applied once.
				if not humanoidDescriptionInstance then
					local humanoid = self.player.Character and self.player.Character:FindFirstChildOfClass("Humanoid")
					humanoidDescriptionInstance = humanoid and humanoid:FindFirstChildOfClass("HumanoidDescription")
				end
				instancesAndProperties = {}
				if humanoidDescriptionInstance then
					table.insert(instancesAndProperties, {humanoidDescriptionInstance, effect})
				end
				isNumerical = false
			end
			for _, group in pairs(instancesAndProperties) do
				
				local instance = group[1]
				local isAHumanoidDescription = instance.ClassName == "HumanoidDescription"
				local propertyName = group[2]
				local propertyValue = forcedBaseValue or (isAHumanoidDescription and humanoidDescription and humanoidDescription[propertyName]) or instance[propertyName]
				local finalValue = propertyValue
				local activeAppliedTables = {}

				if not isNumerical then
					-- For nonnumerical items we simply 'remember' the original value if the first time setting
					-- This original value is then reapplied when all buffs are removed
					local defaultGroup = self:_getDefaultGroup(effect, instance)
					local defaultAdditionalString = (isAHumanoidDescription and tostring(additionalString) == "nil" and propertyName) or additionalString
					local defaultValue = defaultGroup[defaultAdditionalString]
					if defaultValue == nil then
						defaultGroup[defaultAdditionalString] = propertyValue
						defaultValue = propertyValue
					end
					if bossBuff.isDestroyed then
						finalValue = defaultValue
						defaultGroup[defaultAdditionalString] = nil
						self.buffs[bossBuff.buffId] = nil
						--
						local BodyUtil = require(bodyUtilPathway)
						BodyUtil.clearFakeBodyParts(self.player, effect, additionalString)
						--
					else
						finalValue = bossBuff.value
					end

				else
					-- For numerical items we instead remember the incremental value, only apply it once, the take it off when the buff is destroyed
					if not isIncremental then
						-- Since 'set' was called, only 1 buff needs to be applied (i.e. the boss buff)
						local previousDifference = 0
						for _, setBuff in pairs(buffs) do
							if not setBuff.incremental then
								local appliedTable = setBuff:_getAppliedValueTable(effect, instance)
								local currentAppliedValue = appliedTable[propertyName]
								if currentAppliedValue then
									previousDifference += currentAppliedValue
									appliedTable[propertyName] = nil
								end
							end
						end
						local bossAppliedTable = bossBuff:_getAppliedValueTable(effect, instance)
						bossAppliedTable[propertyName] = bossBuff.value - propertyValue + previousDifference
						finalValue = bossBuff.value
						table.insert(activeAppliedTables, bossAppliedTable)
					else
						
						for _, incrementalBuff in pairs(buffs) do
							if incrementalBuff.incremental then
								local appliedTable = incrementalBuff:_getAppliedValueTable(effect, instance)
								local currentAppliedValue = appliedTable[propertyName]
								local incrementValue = incrementalBuff.value
								if currentAppliedValue == nil then
									-- If a value has never been applied
									finalValue += incrementValue
									appliedTable[propertyName] = incrementValue
									table.insert(activeAppliedTables, appliedTable)
								elseif currentAppliedValue ~= incrementValue then
									-- If a value was previously applied but has changed
									finalValue -= currentAppliedValue + incrementValue--buff.valueReducer(finalValue)
									appliedTable[propertyName] = incrementValue
									table.insert(activeAppliedTables, appliedTable)
								end
							end
						end
					end

					-- This accounts for destoyed buffs in the finalValue then forgets them
					for _, buff in pairs(buffs) do
						if buff.isDestroyed then
							local appliedTable = buff:_getAppliedValueTable(effect, instance)
							local currentAppliedValue = appliedTable[propertyName]
							if currentAppliedValue then
								finalValue -= currentAppliedValue
							end
							appliedTable[propertyName] = nil
							self.buffs[buff.buffId] = nil
							--
							local BodyUtil = require(bodyUtilPathway)
							BodyUtil.clearFakeBodyParts(self.player, effect, additionalString)
							--
						end
					end

				end

				-- This applies the final value
				if (propertyValue ~= finalValue or isAHumanoidDescription) and not self.silentlyEndBuffs then
					local function updateActiveAppliedTables()
						local difference = finalValue - instance[propertyName]
						for _, appliedTable in pairs(activeAppliedTables) do
							if type(appliedTable[propertyName]) == "number" then
								appliedTable[propertyName] -= difference
							end
						end
					end

					if not finalValueTweenInfo then
						if isAHumanoidDescription then
							self:modifyHumanoidDescription(propertyName, finalValue)
						else
							
							instance[propertyName] = finalValue
						end
						if isNumerical then
							updateActiveAppliedTables()
						end
						
					else
						-- It's important tweens are auto-completed if another effect of same additional value is called before its tween has completed
						local completeTime = os.clock() + finalValueTweenInfo.Time
						local tween = tweenService:Create(instance, finalValueTweenInfo, {[propertyName] = finalValue})
						if isNumerical then
							tween.Completed:Connect(function()
								updateActiveAppliedTables()
							end)
						end
						tween:Play()
						reduceTweenMaid:give(function()
							if tween.PlaybackState ~= Enum.PlaybackState.Completed then
								tween:Pause()
								if type(finalValue) == "number" then
									rawset(reduceTweenMaid, "forcedBaseValueValidUntilTime", completeTime)
									rawset(reduceTweenMaid, "forcedBaseValue", finalValue)
								end
							end
							tween:Destroy()
						end)
					end
				end
				
			end

		end
	end
end

function Agent:modifyHumanoidDescription(propertyName, value)
	-- humanoidDescriptionInstances do this weird thing where they don't always apply, especially when applying as soon as a player respawns
	-- or right after applying another description. The following code is designed to prevent this.
	self.humanoidDescriptionCount += 1
	local myCount = self.humanoidDescriptionCount
	local humanoid = self.player.Character.Humanoid
	if not self.humanoidDescription then
		self.humanoidDescription = humanoid:GetAppliedDescription()
	end
	self.humanoidDescription[propertyName] = value
	coroutine.wrap(function()
		main.RunService.Heartbeat:Wait()
		if self.humanoidDescriptionCount == myCount and not self.applyingHumanoidDescription then
			local iterations = 0
			self.applyingHumanoidDescription = true
			local appliedDesc
			repeat
				main.RunService.Heartbeat:Wait()
				pcall(function() humanoid:ApplyDescription(self.humanoidDescription) end)
				iterations += 1
				appliedDesc = humanoid and humanoid:GetAppliedDescription()
			until (appliedDesc and self.humanoidDescription and appliedDesc[propertyName] == self.humanoidDescription[propertyName]) or iterations == 10
			self.applyingHumanoidDescription = false
			self.humanoidDescription = nil
		end
	end)()
end

function Agent:clearBuffs()
	for buffId, buff in pairs(self.buffs) do
		buff:destroy()
	end
end

function Agent:assassinateBuffs()
	self.silentlyEndBuffs = true
	self:clearBuffs()
	self.silentlyEndBuffs = false
end

function Agent:clearBuffsWithEffect(effect)
	for buffId, buff in pairs(self.buffs) do
		if buff.effect == effect then
			buff:destroy()
		end
	end
end

function Agent:destroy()
	self:clearBuffs()
	self._maid:clean()
end
Agent.Destroy = Agent.destroy



return Agent