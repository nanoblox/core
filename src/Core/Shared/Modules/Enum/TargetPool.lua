local players = game:GetService("Players")
local function getArrayOfPlayers(definedPool, criteria)
	local playersArray = {}
	local newDefinedPool = definedPool or players:GetPlayers()
	local isAnArray = newDefinedPool[1]
	local function check(player)
		if criteria(player) then
			table.insert(playersArray, player)
		end
	end
	if isAnArray then
		for _, player in pairs(newDefinedPool) do
			check(player)
		end
	else
		for player, _ in pairs(newDefinedPool) do
			check(player)
		end
	end
	return playersArray
end

local function getNearbyPlayers(origin, radius, playerToIgnore, definedPool)
	local playersArray = getArrayOfPlayers(definedPool, function(plrToCheck)
		return plrToCheck ~= playerToIgnore and plrToCheck:DistanceFromCharacter(origin) <= radius
	end)
	return playersArray
end



-- enumName, enumValue, additionalProperty
return {
	{"None ", 1},
	
	{"Individual ", 2, function(player, definedPool)
		local newPlayer = unpack(getArrayOfPlayers(definedPool, function(plrToCheck)
			return plrToCheck == player
		end))
		return newPlayer
	end},

	{"Nearby", 3, function(origin, radius, definedPool)
		return getNearbyPlayers(origin, radius, nil, definedPool)
	end},

	{"Others", 4, function(playerToIgnore, definedPool)
		local playersArray = getArrayOfPlayers(definedPool, function(plrToCheck)
			return plrToCheck ~= playerToIgnore
		end)
		return playersArray
	end},

	{"OthersNearby", 5, function(origin, radius, playerToIgnore, definedPool)
		return getNearbyPlayers(origin, radius, playerToIgnore, definedPool)
	end},
	
	{"All", 6, function(definedPool)
		local playersArray = getArrayOfPlayers(definedPool, function(plrToCheck)
			return true
		end)
		return playersArray
	end},
}