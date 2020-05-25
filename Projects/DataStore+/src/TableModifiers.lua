-- LOCAL
local httpService = game:GetService("HttpService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local HDAdmin = replicatedStorage:WaitForChild("HDAdmin")
local Signal = require(HDAdmin:WaitForChild("Signal"))
local Maid = require(HDAdmin:WaitForChild("Maid"))
local TableModifiers = {}
TableModifiers.__index = TableModifiers



-- CONSTRUCTOR
function TableModifiers.new(eventsParent)
	local self = {}
	setmetatable(self, TableModifiers)
	eventsParent = eventsParent or self
	local differentParents = eventsParent ~= self
	
	local pathwayId = (differentParents and game:GetService("HttpService"):GenerateGUID()) or ""
	local maid = Maid.new()
	eventsParent[pathwayId.."Maid"] = maid
	local events = {"changed", "inserted", "removed", "paired", "merged", "destroyed"}
	for _, eventName in pairs(events) do
		eventsParent[pathwayId..eventName] = maid:add(Signal.new())
	end
	if differentParents then
		setmetatable(self, {
			__index = function(this, index)
				local newIndex = TableModifiers[index] or eventsParent[pathwayId..index]
				return newIndex
			end
		})
	end
	
	self._tableUpdated = false
		
	return self
end



-- METHODS
function TableModifiers:get(stat)
	return self[stat]
end

function TableModifiers:find(stat, value)
	local tab = self[stat]
	if type(tab) == "table" then
		if #tab == 0 then return tab[value] end
		for i,v in pairs(tab) do
			if v == value then
				return true
			end
		end
	end
	return false
end

function TableModifiers:len(stat)
	local value = self[stat]
	local typeActions = {
		["table"] = function()
			local function getTotalHashes(v)
				local l = 0
				for _, _ in pairs(v) do
					l = l + 1
				end
				return l
			end
			return(((#value > 0) and #value) or getTotalHashes(value))
		end;
		["string"] = function()
			return #stat
		end;
	}
	local typeAction = typeActions[type(value)]
	return((typeAction and typeAction()) or 0)
end

function TableModifiers:change(stat, value)
	local oldValue = self[stat]
	self[stat] = value
	self._tableUpdated = true
	self.changed:Fire(stat, value, oldValue)
	return value
end

function TableModifiers:add(stat, value)
	local oldValue = self[stat] or 0
	local newValue = oldValue + value
	self[stat] = newValue
	self._tableUpdated = true
	self.changed:Fire(stat, newValue, oldValue)
	return newValue
end

function TableModifiers:insert(stat, value)
	local tab = (type(self[stat]) == "table" and self[stat]) or {}
	table.insert(tab, value)
	self[stat] = tab
	self._tableUpdated = true
	self.inserted:Fire(stat, value)
	return tab
end

function TableModifiers:remove(stat, value)
	local tab = self[stat]
	for i,v in pairs(tab) do
		if v == value then
			table.remove(tab, i)
		end
	end
	self._tableUpdated = true
	self.removed:Fire(stat, value)
end

function TableModifiers:pair(stat, key, value)
	local originalTab = self[stat]
	local tab = (type(originalTab) == "table" and originalTab) or {}
	tab[key] = value
	self[stat] = tab
	self._tableUpdated = true
	self.paired:Fire(stat, key, value)
	return tab
end

function TableModifiers:merge(stat, value)
	local oldValue = self[stat] or ""
	local newValue = oldValue.. tostring(value)
	self[stat] = newValue
	self._tableUpdated = true
	self.merged:Fire(stat, newValue, oldValue)
	return newValue
end

function TableModifiers:clear()
	for k,v in pairs(self) do
		self[k] = nil
	end
end



return TableModifiers