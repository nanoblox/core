local Agent = {}
Agent.__index = Agent

local main = require(game.Nanoblox)
local Buff = require(script.Buff)
local Maid = main.modules.Maid
local sortBuffsByTimeCreatedFunc = function(buffA, buffB)return buffA.timeCreated > buffB.timeCreated() end
local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local effects = require(script.Buff.Effects)



-- LOCAL FUNCTIONS
local function getDifferenceKey(instanceName, propertyName)
	return instanceName.."-"..propertyName
end

local function isSuperiorWeight(baseBuff, toCompareBuff)
	if baseBuff == nil then
		return true
	end
	local baseWeight = baseBuff.weight
	local toCompareWeight = toCompareBuff.weight
	if toCompareWeight > baseWeight or (toCompareWeight == baseWeight and toCompareBuff.timeCreated > baseBuff.timeCreated) then
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

	maid:give(player.CharacterAdded:Connect(function()
		if reapplyBuffsOnRespawn then
			self:reduceAndApplyEffects()
			return
		end
		self:assassinateBuffs()
	end))

	return self
end



-- METHODS
function Agent:buff(effect, weight)
	local buff = Buff.new(effect, weight)
	local buffId = buff.buffId
	local additional = buff.additional
	buff.agent = self
	buff.destroyed:Connect(function()
		---------------
		self.buffs[buffId] = nil
		---------------
		-- This re-applies the original value (if necessary)
		local groupedBuffs = self.groupedBuffs
		local additionalTable = groupedBuffs[effect]
		local additionalString = tostring(additional)
		local buffsInGroup = (additionalTable and additionalTable[additionalString])
		if buffsInGroup then
			local defaultGroup = self:getDefaultGroup(effect)
			local defaultValue = defaultGroup[additionalString]
			local instancesAndProperties = effects[effect](self.player, defaultValue, additional)
			for _, group in pairs(instancesAndProperties) do
				local instance = group[1]
				local instanceName = tostring(instance)
				local propertyName = group[2]
				if #buffsInGroup == 0 and not self.silentlyEndBuffs then
					-- This reverts non-numerical items
					instance[propertyName] = defaultValue
				end
				local key = getDifferenceKey(instanceName, propertyName)
				local differenceTable = buff:_getDifferenceValueTable(effect)
				local currentDifference = differenceTable[key]
				if currentDifference then
					-- This reverts numerical items
					instance[propertyName] -= currentDifference
				end
			end
			defaultGroup[additionalString] = nil
		end
		if not self.silentlyEndBuffs then
			self:reduceAndApplyEffects(effect)
		end
		---------------
	end)
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
	table.sort(buffs, sortBuffsByTimeCreatedFunc)
	return buffs
end

function Agent:getBuffsWithEffect(effect)
	local buffs = {}
	for buffId, buff in pairs(self.buffs) do
		if buff.effect == effect then
			table.insert(buffs, buff)
		end
	end
	table.sort(buffs, sortBuffsByTimeCreatedFunc)
	return buffs
end

function Agent:updateBuffsGroup()
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

function Agent:getDefaultGroup(effect)
	local defaultGroup = self.defaultValues[effect]
	if defaultGroup == nil then
		defaultGroup = {}
		self.defaultValues[effect] = defaultGroup
	end
	return defaultGroup
end

function Agent:reduceAndApplyEffects(specificEffect)
	self:updateBuffsGroup()
	for effect, additionalTable in pairs(self.groupedBuffs) do
		if not(specificEffect == nil or effect == specificEffect) then
			continue
		end
		local defaultGroup = self:getDefaultGroup(effect)
		for additional, buffs in pairs(additionalTable) do
		
			-- The default value should only be for only remembering non-numerical values (such as colors, materials, etc)
			-- This is due to numerical based properties having a greater tendency to change on their own (such as Health regeneration)
			-- For numerical values we instead records its 'difference' to deterine the previous value when a buff is removed
			
			-- This determines what buffs should be reduced and applied
			local additionalString = tostring(additional)
			local overrrideBuff
			local totalBuffs = 0
			local incrementBuffs = {}
			for _, buff in pairs(buffs) do
				if buff.override and isSuperiorWeight(overrrideBuff, buff) then
					overrrideBuff = buff
				elseif not buff.override then
					table.insert(incrementBuffs, buff)
				end
				totalBuffs += 1
			end

			-- This calculates the final value
			local finalValue = 0
			local isIncremental = false
			local isNumerical = true
			local numericalBuffs = {}
			local superiorBuff
			if overrrideBuff then
				finalValue = overrrideBuff.valueReducer(finalValue)
				if tonumber(finalValue) then
					table.insert(numericalBuffs, overrrideBuff)
				else
					isNumerical = false
				end
				superiorBuff = overrrideBuff
			else
				isIncremental = true
				for _, buff in pairs(incrementBuffs) do
					table.insert(numericalBuffs, buff)
					finalValue = buff.valueReducer(finalValue)
					if isSuperiorWeight(superiorBuff, buff) then
						superiorBuff = buff
					end		
				end
			end
			
			local finalValueTweenInfo = superiorBuff.tweenInfo
			local tweenReference = tostring(effect)..tostring(additional)
			local reduceTweenMaid = self.reduceMaids[tweenReference]
			if reduceTweenMaid then
				reduceTweenMaid:clean()
			elseif tweenReference then
				reduceTweenMaid = self._maid:give(Maid.new())
				self.reduceMaids[tweenReference] = reduceTweenMaid
			end
			local instancesAndProperties = effects[effect](self.player, finalValue, additional)
			for _, group in pairs(instancesAndProperties) do
				local instance = group[1]
				local instanceName = tostring(instance)
				local propertyName = group[2]
				local propertyValue = instance[propertyName]

				if isNumerical then
					-- This records the difference between a buffs value and the props value for numerical items
					for _, buff in pairs(numericalBuffs) do
						local key = getDifferenceKey(instanceName, propertyName)
						local differenceTable = buff:_getDifferenceValueTable(effect)
						local currentDifference = differenceTable[key]
						if currentDifference then
							finalValue -= currentDifference
						end
						local difference = buff.value
						if buff.override then
							difference = buff.value - propertyValue
						end
						differenceTable[key] = difference
					end
				elseif not defaultGroup[additionalString] then
					-- This records the default (original) value for non-numerical items
					defaultGroup[additionalString] = propertyValue
				end

				-- This applies the final value
				local absoluteFinalValue = finalValue
				if isIncremental then
					absoluteFinalValue = propertyValue + finalValue
				end
				if propertyValue ~= absoluteFinalValue then
					if not finalValueTweenInfo then
						instance[propertyName] = absoluteFinalValue
					else
						-- It's important tweens are auto-completed if another effect of same additional value is called before its tween has completed
						local tween = tweenService:Create(instance, finalValueTweenInfo, {[propertyName] = absoluteFinalValue})
						tween:Play()
						reduceTweenMaid:give(function()
							if tween.PlaybackState ~= Enum.PlaybackState.Completed then
								tween:Pause()
								tween:Destroy()
								instance[propertyName] = absoluteFinalValue
							end
						end)
					end
				end
				
			end

		end
	end
	
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