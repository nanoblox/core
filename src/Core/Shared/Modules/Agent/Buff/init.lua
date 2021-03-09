local main = require(game.Nanoblox)
local httpService = game:GetService("HttpService")
local Maid = main.modules.Maid
local Signal = main.modules.Signal
local Buff = {}
Buff.__index = Buff



-- CONSTRUCTOR
function Buff.new(effect, weight)
	local self = {}
	setmetatable(self, Buff)
	
    local buffId = httpService:GenerateGUID(true)
    self.buffId = buffId
    self.timeCreated = os.clock()
    local maid = Maid.new()
    self._maid = maid
    self.destroyed = maid:give(Signal.new())
    self.effect = effect
    self.weight = weight
    self.updated = maid:give(Signal.new())
    self.agent = nil

	return self
end



-- METHODS
function Buff:set(value)
    self.override = true
    self.increment = false
    self.tweenInfo = nil
    self.valueReducer = function() return value end
    self.updated:Fire(self.effect)
end

function Buff:tweenSet(value, tweenInfo)
    self.override = true
    self.increment = false
    self.tweenInfo = tweenInfo
    self.valueReducer = function() return value end
    self.updated:Fire(self.effect)
end

function Buff:increment(value)
    self.override = false
    self.increment = true
    self.tweenInfo = nil
    self.valueReducer = function(baseValue) return baseValue + value end
    self.updated:Fire(self.effect)
end

function Buff:tweenIncrement(value, tweenInfo)
    self.override = false
    self.increment = true
    self.tweenInfo = tweenInfo
    self.valueReducer = function(baseValue) return baseValue + value end
    self.updated:Fire(self.effect)
end

function Buff:destroy()
    self.destroyed:Fire()
    self._maid:clean()
end
Buff.Destroy = Buff.destroy



return Buff