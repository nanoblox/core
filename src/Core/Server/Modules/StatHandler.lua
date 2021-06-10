-- This is responsible for modifying data when using the 'Stat' arg and associated commands such as ';setStat', ';addStat', etc

-- LOCAL
local main = require(game.Nanoblox)
local StatHandler = {}



-- METHODS
function StatHandler.get(player, statName)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	local stat = leaderstats:FindFirstChild(statName)
	if not stat then
		local lowercaseStatName = string.lower(statName)
		for _, childStat in pairs(leaderstats:GetChildren()) do
			if string.lower(childStat.Name) == lowercaseStatName then
				stat = childStat
				break
			end
		end
	end
	return stat
end

function StatHandler.change(stat, value)
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