-- LOCAL
local Serializer = {}
local identifiersToDetails = {}
local dataTypes
dataTypes = {
	["string"] = {
		identifier = "s",
		serialize = function(property)
			-- This is for rare cases where strings contain text at the start (such as 'c_')
			-- that conflict with the identifiers. This adds a 's_' for these scenarious to
			-- prevent data mutations 
			local myIdent = dataTypes.string.identifier.."_"
			local fakeIdentifier = property:match("^%l_")
			if fakeIdentifier and fakeIdentifier ~= myIdent then
				return property
			end
			return nil
		end,
		deserialize = function(value)
			return value
		end,
	},
	["Color3"] = {
		identifier = "c",
		serialize = function(property)
			return tostring(property)
		end,
		deserialize = function(value)
			local tValue = value:split(",")
			return Color3.new(unpack(tValue))
		end,
	},
	["EnumItem"] = {
		identifier = "e",
		serialize = function(property)
			return tostring(property)
		end,
		deserialize = function(value)
			local tValue = value:split(".")
			return Enum[tValue[2]][tValue[3]]
		end,
	},
	["CFrame"] = {
		identifier = "f",
		serialize = function(property)
			return tostring(property)
		end,
		deserialize = function(value)
			local tValue = value:split(",")
			return CFrame.new(unpack(tValue))
		end,
	},
	["Ray"] = {
		identifier = "r",
		serialize = function(property)
			return tostring(property)
		end,
		deserialize = function(value)
			local components = multiSplit(value)
			local origin, direction = Serializer.serialize(components[1]), Serializer.serialize(components[2])
			return Ray.new(origin, direction)
		end
	},
	["Region3"] = {
		identifier = "e",
		serialize = function(property)
			return tostring(property)
		end,
		deserialize = function(value)
			local components = value:split("; ")
			local cframe, size = Serializer.serialize(components[1]), Serializer.serialize(components[2])
			return Region3.new(cframe, size)
		end
	},
	["Vector2"] = {
		identifier = "w",
		serialize = function(property)
			return tostring(property)
		end,
		deserialize = function(value)
			local tValue = value:split(",")
			return Vector3.new(tValue[1], tValue[2])
		end,
	},
	["Vector3"] = {
		identifier = "v",
		serialize = function(property)
			return tostring(property)
		end,
		deserialize = function(value)
			local tValue = value:split(",")
			return Vector3.new(tValue[1], tValue[2], tValue[3])
		end,
	},
	["UDim"] = {
		identifier = "w",
		serialize = function(property)
			return tostring(property)
		end,
		deserialize = function(value)
			local tValue = value:split(",")
			return Vector3.new(tValue[1], tValue[2])
		end,
	},
	["UDim2"] = {
		identifier = "q",
		serialize = function(property)
			return tostring(property)
		end,
		deserialize = function(value)
			local components = multiSplit(value)
			local x, y = Serializer.serialize(components[1]), Serializer.serialize(components[2])
			return UDim2.new(x, y)
		end
	},
	["table"] = {
		serialize = function(property, deepCopy)
			for k, v in pairs(property) do
				local newK = Serializer.serialize(k, deepCopy)
				local newV = Serializer.serialize(v, deepCopy)
				property[newK] = newV
			end
			return property
		end,
		deserialize = function(value, deepCopy)
			for k, v in pairs(value) do
				local origK = Serializer.deserialize(k, deepCopy)
				local origV = Serializer.deserialize(v, deepCopy)
				value[origK] = origV
			end
			return value
		end,
	},
}

local function deepCopyOnce(property)
	local newProperty = {}  
	for k, v in pairs(property) do
		newProperty[k] = v
	end
	return newProperty
end

local function multiSplit(value)
	return value:sub(1, #value-1):split("}, {")
end



-- SETUP
for identifierName, details in pairs(dataTypes) do
	if details.identifier then
		identifiersToDetails[details.identifier.."_"] = details
	end
end



-- METHODS
function Serializer.serialize(property, deepCopy)
	local valueType = typeof(property)
	local details = dataTypes[valueType]
	if details then
		if valueType == "table" and deepCopy then
			property = deepCopyOnce(property)
		end
		local value = details.serialize(property, deepCopy)
		if value ~= nil then
			if details.identifier then
				value = details.identifier.."_"..value
			end
			return value
		end
	end
	return property
end

function Serializer.deserialize(value, deepCopy)
	local valueType = typeof(value)
	if valueType == "string" then
		local identifier = value:match("^%l_")
		local details = identifiersToDetails[identifier]
		if details then
			return details.deserialize(value:sub(3))
		end
		return value
	elseif valueType == "table" then
		if deepCopy then
			value = deepCopyOnce(value)
		end
		return dataTypes.table.deserialize(value, deepCopy)
	end
	return value
end


return Serializer
