-- Custom enum implementation that provides an effective way to compare, send
-- and store values. Instead of returning a userdata value, enum items return
-- their corresponding itemValue (an integer) when indexed. Enum items can
-- also associate a 'property', specified as the third element, which can be
-- retrieved by doing ``main.enum.ENUM_NAME.getProperty(ITEM_NAME_OR_VALUE)``
-- This ultimately means groups of data can be easily categorised, efficiently
-- transmitted over networks and saved without throwing errors.


-- LOCAL
local EnumHandler = {}
local enums = {}



-- START
function EnumHandler:start()
	local createEnum = self.createEnum
	createEnum("Servers", {
		{"Current", 1}, -- This server
		{"Others", 2}, -- Every server, except this server
		{"All", 3}, -- Every server
	})
	
	createEnum("RoleType", {
		{"Perm", 1}, -- Persists until the player leaves
		{"Time", 2}, -- Persists until the 'giver' (user that gave the role) leaves the server
		{"Server", 3}, -- Persists until the server ends
		{"Giver", 4}, -- Remains permanently (until removed)
		{"Temp", 5}, -- Remains permanently, and syncs with config in studio (i.e.
		-- is added to the role itself)
	})
	
	--[[
	createEnum("Color", {
	    {"White", 1, Color3.fromRGB(255, 255, 255)},
	    {"Black", 2, Color3.fromRGB(0, 0, 0)},
	})
	--]]
end



-- METHODS
function EnumHandler.createEnum(enumName, details)
	assert(typeof(enumName) == "string", "bad argument #1 - enums must be created using a string name!")
	assert(typeof(details) == "table", "bad argument #2 - enums must be created using a table!")
	assert(not enums[enumName], ("enum '%s' already exists!"):format(enumName))
	
	local enum = {}
	local usedNames = {}
	local usedValues = {}
	local usedProperties = {}
	local enumMetaFunctions = {
		getName = function(valueOrProperty)
			valueOrProperty = tostring(valueOrProperty)
			local index = usedValues[valueOrProperty]
			if not index then
				index = usedProperties[valueOrProperty]
			end
			if index then
				return details[index][1]
			end
		end,
		getValue = function(nameOrProperty)
			nameOrProperty = tostring(nameOrProperty)
			local index = usedNames[nameOrProperty]
			if not index then
				index = usedProperties[nameOrProperty]
			end
			if index then
				return details[index][2]
			end
		end,
		getProperty = function(nameOrValue)
			nameOrValue = tostring(nameOrValue)
			local index = usedNames[nameOrValue]
			if not index then
				index = usedValues[nameOrValue]
			end
			if index then
				return details[index][3]
			end
		end
	}
	for i, detail in pairs(details) do
		assert(typeof(details) == "table", ("bad argument #2.%s - details must only be comprised of tables!"):format(i))
		local name = detail[1]
		assert(typeof(name) == "string", ("bad argument #2.%s.1 - detail name must be a string!"):format(i))
		assert(typeof(not usedNames[name]), ("bad argument #2.%s.1 - the detail name '%s' already exists!"):format(i, name))
		assert(typeof(not enumMetaFunctions[name]), ("bad argument #2.%s.1 - that name is reserved."):format(i, name))
		usedNames[tostring(name)] = i
		local value = detail[2]
		assert(typeof(value) == "number" and math.ceil(value)/value == 1, ("bad argument #2.%s.2 - detail value must be an integer!"):format(i))
		assert(typeof(not usedValues[value]), ("bad argument #2.%s.2 - the detail value '%s' already exists!"):format(i, value))
		usedValues[tostring(value)] = i
		local property = detail[3]
		if property then
			assert(typeof(not usedProperties[property]), ("bad argument #2.%s.3 - the detail property '%s' already exists!"):format(i, tostring(property)))
			usedProperties[tostring(property)] = i
		end
		enum[name] = value
		setmetatable(enum, {
			__index = function(_, index)
				return(enumMetaFunctions[index])
			end
		})
	end
	
	enums[enumName] = enum
	return enum
end

function EnumHandler.getEnums()
	return enums
end



return EnumHandler