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
        --[[ I need values to be 100% precise on both ends; converting to hex does not achieve this
        serialize = function(property)
			local r = math.floor(property.r*255+.5)
            local g = math.floor(property.g*255+.5)
            local b = math.floor(property.b*255+.5)
            return ("%02x%02x%02x"):format(r, g, b)
		end,
		deserialize = function(value)
			local r, g, b = value:match("(..)(..)(..)")
            r, g, b = tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
            return Color3.fromRGB(r, g, b)
        end,
        --]]
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
    ["table"] = {
        serialize = function(property, deepCopy)
            for k, v in pairs(property) do
                property[k] = Serializer.serialize(v, deepCopy)
            end
            return property
		end,
        deserialize = function(value, deepCopy)
            for k, v in pairs(value) do
                value[k] = Serializer.deserialize(v, deepCopy)
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