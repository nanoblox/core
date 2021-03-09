local Agent = {}
Agent.__index = Agent

local main = require(game.Nanoblox)
local Buff = require(script.Buff)
local Maid = main.modules.Maid
local sortBuffsByTimeCreatedFunc = function(buffA, buffB)return buffA.timeCreated > buffB.timeCreated() end
local players = game:GetService("Players")



-- CONSTRUCTOR
function Agent.new(player, clearBuffsOnRespawn)
	local self = {}
	setmetatable(self, Agent)
	
	local maid = Maid.new()
	self._maid = maid
	self.buffs = {}
    self.baseValues = {}
	self.clearBuffsOnRespawn = clearBuffsOnRespawn

	maid:give(player.CharacterAdded:Connect(function()
		if clearBuffsOnRespawn then
			self:clearBuffs()
		end
	end))

	return self
end



-- METHODS
function Agent:buff(effect, weight)
	local buff = Buff.new(effect, weight)
	local buffId = buff.buffId
	buff.agent = self
	buff.destroyed:Connect(function()
		self.buffs[buffId] = nil
	end)
	buff.changed:Connect(function(specificEffect)
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

function Agent:reduceAndApplyEffects(specificEffect)
	local groupedBuffs = {}
	for buffId, buff in pairs(self.buffs) do
		if specificEffect == nil or buff.effect == specificEffect then
			local group = groupedBuffs[buff.effect]
			if not group then
				group = {}
				groupedBuffs[buff.effect] = group
			end
			table.insert(group, buff)
		end
	end
	--
	for effect, buffs in pairs(groupedBuffs) do
		local baseValue = self.baseValues[effect]
		if not baseValue then
			--!!! DETERMINE BASE VALUE
		end
		local overrideValue
		for _, buff in pairs(buffs) do
			if buff.override then
				
			end
		end
	end
	--
end

function Agent:clearBuffs()
	for buffId, buff in pairs(self.buffs) do
		buff:destroy()
	end
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