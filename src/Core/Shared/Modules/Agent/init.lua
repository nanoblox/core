local Agent = {}
Agent.__index = Agent



-- CONSTRUCTOR
function Agent.new(player)
	local self = {}
	setmetatable(self, Agent)

    self.originalOrBaseValues = {}

	return self
end



-- METHODS
function Agent:buff(effect, weight)

end

function Agent:getBuffs()

end

function Agent:getBuffsWithEffect(effect)

end

function Agent:clearBuffs()

end

function Agent:clearBuffsWithEffect(effect)

end

function Agent:destroy()

end



return Agent