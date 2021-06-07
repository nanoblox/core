-- This is responsible for modifying data when using the 'Stat' arg and associated commands such as ';setStat', ';addStat', etc

-- LOCAL
local main = require(game.Nanoblox)
local StatHandler = {}



-- METHODS
function StatHandler.get(player, statName)
	print("statName = ", statName)
	local leaderstats = player:FindFirstChild("leaderstats")
	local stat = leaderstats and leaderstats:FindFirstChild(statName)
	return stat
end

function StatHandler.set(stat, value)
	if stat then
		stat.Value = value
	end
end

function StatHandler.add(stat, value)
	local numberValue = tonumber(value)
	if numberValue and stat and (stat:IsA("NumberValue") or stat:IsA("IntValue")) then
		stat.Value += numberValue
	end
end

function StatHandler.subtract(stat, value)
	local numberValue = tonumber(value)
	if numberValue and stat and (stat:IsA("NumberValue") or stat:IsA("IntValue")) then
		stat.Value -= numberValue
	end
end

function StatHandler.reset(stat)
	if stat then
		if stat:IsA("StringValue") then
			stat.Value = ""
		else
			stat.Value = 0
		end
	end
end



return StatHandler