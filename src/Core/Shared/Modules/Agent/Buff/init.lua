local main = require(game.Nanoblox)
local players = game:GetService("Players")
local httpService = game:GetService("HttpService")
local bodyGroups = require(script.Parent.BodyGroups)
local effects = require(script.Parent.Effects)
local Maid = main.modules.Maid
local Buff = {}
Buff.__index = Buff



-- EFFECTS
local function getHumanoid(player)
    local char = player and player.Character
    local humanoid = char and char:FindFirstChild("Humanoid")
    return humanoid
end



-- LOCAL FUNCTIONS
local function updateBuffs(player)
    local buffs = playersAndBuffs[player]
    --
    local properties = buff.effectFunction(buff.player)
    -- give tweens maid
    --
    for buffId, buff in pairs(buffs) do
        
    end
end



-- CONSTRUCTOR
function Buff.new(effect, weight)
	local self = {}
	setmetatable(self, Buff)
	
    local buffId = httpService:GenerateGUID(true)
    self.buffId = buffId
    self.timeCreated = os.clock()
    self._maid = Maid.new()
    
    playersAndBuffs[player][buffId] = self
    updateBuffs(player)

	return self
end



-- METHODS
function Buff:set(value)
    
end

function Buff:tweenSet(value, tweenInfo)
    
end

function Buff:increment(value)
    
end

function Buff:tweenIncrement(value, tweenInfo)
    
end

function Buff:destroy()
    playersAndBuffs[self.player][self.buffId] = nil
    self._maid:clean()
end



return Buff