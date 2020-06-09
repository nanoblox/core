-- LOCAL
local httpService = game:GetService("HttpService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local HDAdmin = replicatedStorage:WaitForChild("HDAdmin")
local Signal = require(HDAdmin:WaitForChild("Signal"))
local Maid = require(HDAdmin:WaitForChild("Maid"))
local activeTables = {}
local events = {"setted", "incremented", "changed", "inserted", "removed", "paired", "concatted", "cleared"}
local TableModifiers = {}
setmetatable(TableModifiers, {
	__mode = "k"}
)



-- CONSTRUCTOR
function TableModifiers.apply(targetTable)
	
	local maid = activeTables[targetTable]
	if activeTables[targetTable] then
		return maid
	end
	maid = Maid.new()
	
	local eventInstances = {}
	for _, eventName in pairs(events) do
		eventInstances[eventName] = maid:give(Signal.new())
	end
	setmetatable(targetTable, {
		__index = function(this, index)
			local newIndex = TableModifiers[index] or eventInstances[index]
			return newIndex
		end
	})
	
	targetTable._tableUpdated = false
		
	return maid
end

function TableModifiers.remove(targetTable)
	local maid = activeTables[targetTable]
	if activeTables[targetTable] then
		maid:clean()
		return true
	end
	return false
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

function TableModifiers:set(stat, value)
	local oldValue = self[stat]
	self[stat] = value
	self._tableUpdated = true
	self.setted:Fire(stat, value, oldValue)
	self.changed:Fire(stat, value, oldValue)
	return value
end

function TableModifiers:increment(stat, value)
	local oldValue = self[stat] or 0
	local newValue = oldValue + value
	self[stat] = newValue
	self._tableUpdated = true
	self.incremented:Fire(stat, value)
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

function TableModifiers:concat(stat, value)
	local oldValue = self[stat] or ""
	local newValue = oldValue.. tostring(value)
	self[stat] = newValue
	self._tableUpdated = true
	self.concatted:Fire(stat, newValue, oldValue)
	self.changed:Fire(stat, newValue, oldValue)
	return newValue
end

function TableModifiers:clear()
	for k,v in pairs(self) do
		self[k] = nil
	end
	self.cleared:Fire()
end



return TableModifiers