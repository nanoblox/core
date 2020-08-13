-- LOCAL
local replicatedStorage = game:GetService("ReplicatedStorage")
local HDAdmin = replicatedStorage:WaitForChild("HDAdmin")
local Signal = require(HDAdmin:WaitForChild("Signal"))
local Maid = require(HDAdmin:WaitForChild("Maid"))
local activeTables = {}
local actions = {
	set = "setted",
	increment = "incremented",
	concat = "concatted",
	insert = "inserted",
	remove = "removed",
	pair = "paired",
	clear = "cleared"
}
local changeActions = {
	set = true,
	increment = true,
	concat = true,
}
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
	eventInstances["actionCalled"] = maid:give(Signal.new())
	eventInstances["changed"] = maid:give(Signal.new())
	for actionName, eventName in pairs(actions) do
		local signal = maid:give(Signal.new())
		eventInstances[eventName] = signal
		if changeActions[actionName] then
			maid:give(signal:Connect(function(...)
				eventInstances.changed:Fire(...)
			end))
		end
	end
	setmetatable(targetTable, {
		__index = function(this, index)
			local newIndex = TableModifiers[index] or eventInstances[index]
			return newIndex
		end
	})
		
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
	local actionName = "set"
	local eventName = actions[actionName]
	local oldValue = self[stat]
	self[stat] = value
	self.actionCalled:Fire(actionName, stat, value)
	self[eventName]:Fire(stat, value, oldValue)
	return value
end

function TableModifiers:increment(stat, value)
	local actionName = "increment"
	local eventName = actions[actionName]
	local oldValue = self[stat] or 0
	local newValue = oldValue + value
	self[stat] = newValue
	self.actionCalled:Fire(actionName, stat, value)
	self[eventName]:Fire(stat, value)
	return newValue
end

function TableModifiers:insert(stat, value, pos)
	local actionName = "insert"
	local eventName = actions[actionName]
	local tab = (type(self[stat]) == "table" and self[stat])
	if not tab then
		tab = {}
		self:set(stat, tab)
	end
	pos = pos or #tab+1
	table.insert(tab, pos, value)
	self[stat] = tab
	self.actionCalled:Fire(actionName, stat, value, pos)
	self[eventName]:Fire(stat, value, pos)
	return tab
end

function TableModifiers:remove(stat, value, pos)
	local actionName = "remove"
	local eventName = actions[actionName]
	local tab = self[stat]
	if not tab then
		return
	end
	local exactV = tab[pos]
	if exactV and exactV == value then
		table.remove(tab, pos)
	else
		for i,v in pairs(tab) do
			if v == value then
				table.remove(tab, i)
				break
			end
		end
	end
	self.actionCalled:Fire(actionName, stat, value, pos)
	self.removed:Fire(stat, value, pos)
end

function TableModifiers:pair(stat, key, value)
	local actionName = "pair"
	local eventName = actions[actionName]
	local originalTab = self[stat]
	local tab = (type(originalTab) == "table" and originalTab)
	if not tab then
		tab = {}
		self:set(stat, tab)
	end
	local originalValue = tab[key]
	tab[key] = value
	self[stat] = tab
	self.actionCalled:Fire(actionName, stat, key, value)
	self.paired:Fire(stat, key, value, originalValue)
	return tab
end

function TableModifiers:concat(stat, value)
	local actionName = "concat"
	local eventName = actions[actionName]
	local oldValue = self[stat] or ""
	local newValue = oldValue.. tostring(value)
	self[stat] = newValue
	self.actionCalled:Fire(actionName, stat, value)
	self.concatted:Fire(stat, newValue, oldValue)
	return newValue
end

function TableModifiers:clear()
	local actionName = "clear"
	local eventName = actions[actionName]
	for k,v in pairs(self) do
		--self[k] = nil
		self:set(k, nil)
	end
	self.actionCalled:Fire(actionName)
	self.cleared:Fire()
end



return TableModifiers