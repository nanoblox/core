-- LOCAL
local replicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(script.Parent.Signal)
local Maid = require(script.Parent.Maid)
local activeTables = {}
local State = {}
setmetatable(State, {
	__mode = "k"}
)



-- LOCAL FUNCTIONS
local function doTablesMatch(t1, t2, cancelOpposites)
	if type(t1) ~= "table" then
		return false
	end
	for i, v in pairs(t1) do
		if (typeof(v) == "table") then
			if (doTablesMatch(t2[i], v) == false) then
				return false
			end
		else
			if (v ~= t2[i]) then
				return false
			end
		end
	end
	if not cancelOpposites then
		if not doTablesMatch(t2, t1, true) then
			return false
		end
	end
	return true
end

local function isATable(value)
	return type(value) == "table"
end

local function isEqual(v1, v2)
	if isATable(v1) and isATable(v2) then
		return doTablesMatch(v1, v2)
	end
	return v1 == v2
end

local function findValue(tab, value)
	for i,v in pairs(tab) do
		if isEqual(v, value) then
			return i
		end
	end
end

local function deepCopyTable(t)
	local tCopy = table.create(#t)
	for k,v in pairs(t) do
		if (type(v) == "table") then
			tCopy[k] = deepCopyTable(v)
		else
			tCopy[k] = v
		end
	end
	return tCopy
end



-- CONSTRUCTOR
function State.new(props, convertDescendantsToTables)
	
	local newTable = {}
	local maid = Maid.new()
	if typeof(props) == "table" and (convertDescendantsToTables or props._convertDescendantsToTables) then
		for k,v in pairs(props) do
			if typeof(v) == "table" then
				v = maid:give(State.new(v, convertDescendantsToTables))
			end
			newTable[k] = v
		end
	end
	
	local hiddenKeys = {}
	hiddenKeys["_tables"] = {}
	hiddenKeys["_convertDescendantsToTables"] = convertDescendantsToTables
	hiddenKeys["changedFirst"] = maid:give(Signal.new())
	hiddenKeys["changed"] = maid:give(Signal.new())
	setmetatable(newTable, {
		__index = function(this, index)
			local newIndex = State[index] or hiddenKeys[index]
			return newIndex
		end
	})

	activeTables[newTable] = {maid = maid, hiddenKeys = hiddenKeys} 
	
	return newTable
end



-- METHODS
function State:get(...)
	local pathwayTable = {...}
	if type(pathwayTable[1]) == "table" then
		pathwayTable = ...
	end
	local max = #pathwayTable
	local value = self
	if max == 0 then
		return value
	end
	for i, key in pairs(pathwayTable) do
		value = value[key]
		if not (i == max or (type(value) == "table" and value.isState)) then
			return nil
		end
	end
	return value
end

function State:getOrSetup(...)
	local pathwayTable = {...}
	if type(pathwayTable[1]) == "table" then
		pathwayTable = ...
	end
	local value = self
	for i, key in pairs(pathwayTable) do
		local nextValue = value[key]
		if type(nextValue) ~= "table" then
			nextValue = value:set(key, {})
		end
		value = nextValue
	end
	return value
end

function State:find(...)
	local pathwayTable = {...}
	if type(pathwayTable[1]) == "table" then
		pathwayTable = ...
	end
	local max = #pathwayTable
	local value = pathwayTable[max]
	table.remove(pathwayTable, max)
	max = max - 1
	local tab = self
	if max > 0 then
		tab = self:get(table.unpack(pathwayTable))
	end
	if type(tab) == "table" then
		if #tab == 0 then return tab[value] end
		local index = table.find(tab, value)
		return index
	end
	return nil
end

function State:len()
	local length = #self
	if length > 0 then
		return length
	end
	local count = 0
	for k,v in pairs(self) do
		count = count + 1
	end
	return count
end

function State:set(stat, value)
	local oldValue = self[stat]
	if type(value) == "table" and self._convertDescendantsToTables then--and not value.new then
		-- Convert tables and descending tables into States unless an object
		local thisMaid = activeTables[self].maid
		value = thisMaid:give(State.new(value, true))
	elseif value == nil and type(oldValue) == "table" and oldValue.isState then
		-- Destroy State and descending States
		oldValue:destroy()
	end
	self[stat] = value
	self.changedFirst:Fire(stat, value, oldValue)
	self.changed:Fire(stat, value, oldValue)
	return value
end

function State:increment(stat, value)
	value = tonumber(value) or 1
	local oldValue = self[stat] or 0
	local newValue = oldValue + value
	self:set(stat, newValue)
	return newValue
end

function State:decrement(stat, value)
	value = tonumber(value) or 1
	local oldValue = self[stat] or 0
	local newValue = oldValue - value
	self:set(stat, newValue)
	return newValue
end

function State:insert(value, pos)
	local lastIndex = #self+1
	pos = (tonumber(pos) and pos <= lastIndex and pos) or lastIndex
	local startIndex = pos
	local previousValue = self[startIndex]
	local nextValue = value
	for i = startIndex, lastIndex do
		self:set(i, nextValue)
		nextValue = previousValue
		previousValue = self[i+1]
	end
	return value
end

function State:remove(pos)
	local lastIndex = #self
	pos = tonumber(pos) or lastIndex
	if pos > lastIndex then
		return false
	end
	self:set(pos, nil)
	local startIndex = pos
	for i = startIndex, lastIndex do
		local nextValue = self[i+1]
		self:set(i, nextValue)
	end
	return true
end

function State:clear()
	for k,v in pairs(self) do
		self:set(k, nil)
	end
end

-- The following deduces the differences between two sets of data
-- and applies these differences to the third table using the States
-- set method
local function transformData(data1, data2, dataToUpdate, ignoreNilled, modifier)
	-- data1 is typically the 'incoming' or 'new' data, while data2 is typically the 'existing' data
	if not dataToUpdate then
		dataToUpdate = data2
	end
	
	-- If a value is present in data2, but not in data1, then nil it
	if not ignoreNilled then
		local function compareNilled(tab2, tab1, tabToUpdate)
			if typeof(tab2) == "table" and typeof(tab1) == "table" then
				for key, tab2value in pairs(tab2) do
					local tab1value = tab1[key]
					local tabToUpdateMain = (tabToUpdate == dataToUpdate and modifier and modifier(key, tab2value)) or tabToUpdate
					if tab1value == nil then
						tabToUpdateMain:set(key, nil)
					else
						compareNilled(tab2value, tab1value, (tabToUpdateMain and tabToUpdateMain[key]))
					end
				end
			end
		end
		compareNilled(data2, data1, dataToUpdate)
	end
	
	-- If a value is present in data1, but DIFFERENT *or* not in data2, then set it	
	local function comparePresent(tab1, tab2, tabToUpdate)
		if typeof(tab1) == "table" then
			for key, tab1value in pairs(tab1) do
				local tabToUpdateMain, extra = (tabToUpdate == dataToUpdate and modifier and modifier(key, tab1value)) or tabToUpdate, nil
				local isPrivate = extra == "isPrivate"
				local tab2value = tab2[key]
				local bothAreTables = type(tab1value) == "table" and type(tab2value) == "table"
				if isPrivate or (not bothAreTables and tab1value ~= tab2value) then
					tabToUpdateMain:set(key, tab1value)
				else
					comparePresent(tab1value, tab2value, (tabToUpdateMain and tabToUpdateMain[key]))
				end
			end
		end
	end
	comparePresent(data1, data2, dataToUpdate)
end

function State:transformTo(data1, modifier)
	transformData(data1, self, self, false, modifier)
end

function State:transformToWithoutNilling(data1, modifier)
	transformData(data1, self, self, true, modifier)
end

function State:transformDifferences(data1, data2, modifier)
	transformData(data1, data2, self, false, modifier)
end

-- This creates a signal that is fired when descendant tables
-- (and itself optionally) are changed. The first value returned
-- is a 'pathwayTable', followed by the normal .changed return values.
-- A pathway table enables you to get the table that was originally
-- called, from the listening table, by doing
-- ``self:get(pathwayTable)``
function State:createDescendantChangedSignal(includeSelf)
	local maid = activeTables[self].maid
	local signal = maid:give(Signal.new())
	local function connectToTable(tab, pathwayTable, onlyListenToDescendants)
		local function connectChild(key, value)
			if type(value) == "table" then
				local newPathwayTable = deepCopyTable(pathwayTable)
				table.insert(newPathwayTable, key)
				connectToTable(value, newPathwayTable)
			end
		end
		if not onlyListenToDescendants then
			tab.changed:Connect(function(key, newValue, oldValue)
				connectChild(key, newValue)
				----
				signal:Fire(pathwayTable, key, newValue, oldValue)
				----
			end)
		end
		for key, value in pairs(tab) do
			connectChild(key, value)
		end
	end
	local initialPathwayTable = {}
	connectToTable(self, initialPathwayTable, not includeSelf)
	return signal
end


-- This enables the creation of tables that mirror their target with specified sorted differences
-- For instance, it may be desirable to retrieve a table of commands in descending order by name length
-- Instead of sorting a new commands table every time a command is requested (which could be a lot!),
-- only sort the table when its changed, then retrieve doing ``originalTable:getTable("sortedTableName")``
function State:setTable(tableName, sortFunction, changeFirst)
	local activeTable = activeTables[self]
	if activeTable then
		local maid = activeTable.maid
		local hiddenKeys = activeTable.hiddenKeys
		local event = (changeFirst and self.changedFirst) or self.changed
		maid:give(event:Connect(function()
			hiddenKeys._tables[tableName] = sortFunction()
		end))
		hiddenKeys._tables[tableName] = sortFunction()
	end
end

function State:getTable(tableName)
	local activeTable = activeTables[self]
	if activeTable then
		local hiddenKeys = activeTable.hiddenKeys
		return hiddenKeys._tables[tableName]
	end
end


-- This destroys all State Instances (such as Signals) and metatables
-- associated with the table, so that only normal keys and values remain
function State:destroy()
	local activeTable = activeTables[self]
	if activeTable then
		activeTable.maid:clean()
		setmetatable(self, {__index = nil})
		return true
	end
	return false
end



-- ADDITIONAL
State.isState = true



return State