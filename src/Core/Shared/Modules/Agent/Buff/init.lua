local main = require(game.Nanoblox)
local httpService = game:GetService("HttpService")
local Maid = main.modules.Maid
local Signal = main.modules.Signal
local Effects = require(script.Effects)
local Buff = {}
Buff.__index = Buff



-- CONSTRUCTOR
function Buff.new(effect, property, weight)
    local self = {}
	setmetatable(self, Buff)

	local effectModule = Effects[effect]
    if not effectModule then
        error(("'%s' is not a valid Buff Effect!"):format(tostring(effect)))
    end

    local buffId = httpService:GenerateGUID(true)
    self.buffId = buffId
    self.timeUpdated = os.clock()
    local maid = Maid.new()
    self._maid = maid
    self.isDestroyed = false
    self.effect = effect
    self.additional = property
    self.weight = weight or 1
    self.updated = maid:give(Signal.new())
    self.agent = nil
    self.appliedValueTables = {}
    self.incremental = nil
    self.previousIncremental = nil

	return self
end



-- METHODS
function Buff:_changeValue(value)
    local newValue = value
    if typeof(value) == "BrickColor" then
        newValue = Color3.new(value.r, value.g, value.b)
    end
    return newValue
end

function Buff:set(value, optionalTweenInfo)
    self.previousIncremental = self.incremental
    self.incremental = false
    self.tweenInfo = optionalTweenInfo
    self.value = self:_changeValue(value)
    self.timeUpdated = os.clock()
    self.updated:Fire(self.effect, self.additional)
    return self
end

function Buff:increment(value, optionalTweenInfo)
    assert(type(value) == "number", "incremental value must be a number!")
    self.previousIncremental = self.incremental
    self.incremental = true
    self.tweenInfo = optionalTweenInfo
    self.value = self:_changeValue(value)
    self.timeUpdated = os.clock()
    self.updated:Fire(self.effect, self.additional)
    return self
end

function Buff:decrement(value, optionalTweenInfo)
    self:increment(-value, optionalTweenInfo)
    return self
end

function Buff:setWeight(weight)
    self.weight = weight or 1
    self.timeUpdated = os.clock()
    self.updated:Fire()
    return self
end

function Buff:_getAppliedValueTable(effect, instance)
    local parentTab = self.appliedValueTables[effect]
    if not parentTab then
        parentTab = {}
        self.appliedValueTables[effect] = parentTab
    end
    local tab = parentTab[instance]
    if not tab then
        tab = {}
        parentTab[instance] = tab
    end
    return tab
end

function Buff:destroy()
    if self.isDestroyed then return end
    self.isDestroyed = true
    self.updated:Fire()
    self._maid:clean()
    return self
end
Buff.Destroy = Buff.destroy



return Buff