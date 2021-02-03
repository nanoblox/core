-- LOCAL
local main = require(game.Nanoblox)
local DataUtil = {}
local heartbeat = main.RunService.Heartbeat
local validCharacters = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","1","2","3","4","5","6","7","8","9","0","_","<",">","/","?","@","{","}","[","]","!","(",")","-","=","+","~","#"}
local function isATable(value)
	return type(value) == "table"
end



-- METHODS
function DataUtil.isEqual(v1, v2)
	local valueTypesToString = {
		["Color3"] = true,
		["CFrame"] = true,
		["Vector3"] = true,
	}
	if isATable(v1) and isATable(v2) then
		return main.modules.TableUtil.doTablesMatch(v1, v2)
	elseif valueTypesToString[typeof(v1)] and valueTypesToString[typeof(v2)] then
		v1 = tostring(v1)
		v2 = tostring(v2)
	end
	return v1 == v2
end

function DataUtil.generateUID(length)
	length = length or 5
	local UID = ""
	for i = 1, length do
		local randomCharacter = validCharacters[math.random(1, #validCharacters)]
		UID = UID..randomCharacter
	end
	return UID
end

function DataUtil.getIntFromUID(UID)
	
end

function DataUtil.getUIDFromInt(int)
	
end



return DataUtil