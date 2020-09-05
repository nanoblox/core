-- LOCAL
local replicatedStorage = game:GetService("ReplicatedStorage")
local HDAdmin = replicatedStorage:WaitForChild("HDAdmin")
local Signal = require(HDAdmin:WaitForChild("Signal"))
local Maid = require(HDAdmin:WaitForChild("Maid"))
local Serializer = require(script.Parent.Serializer)
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



-- CONSTRUCTOR
function State.new(props)
	
	local newTable = {}
	if typeof(props) == "table" then
		for k,v in pairs(props) do
			newTable[k] = v
		end
	end
	local maid = Maid.new()
	activeTables[newTable] = maid
	
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
	setmetatable(newTable, {
		__index = function(this, index)
			local newIndex = State[index] or eventInstances[index]
			return newIndex
		end
	})
		
	return newTable
end



-- METHODS
function State:get(stat)
	return self[stat]
end

function State:find(stat, value)
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

function State:len(stat)
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

function State:set(stat, value)
	local actionName = "set"
	local eventName = actions[actionName]
	local oldValue = self[stat]
	self[stat] = value
	self.actionCalled:Fire(actionName, stat, value)
	self[eventName]:Fire(stat, value, oldValue)
	return value
end

function State:increment(stat, value)
	value = tonumber(value) or 1
	local actionName = "increment"
	local eventName = actions[actionName]
	local oldValue = self[stat] or 0
	local newValue = oldValue + value
	self[stat] = newValue
	self.actionCalled:Fire(actionName, stat, value)
	self[eventName]:Fire(stat, value)
	return newValue
end

function State:insert(stat, value, pos)
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

function State:remove(stat, value, pos)
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

function State:pair(stat, key, value)
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

function State:concat(stat, value)
	local actionName = "concat"
	local eventName = actions[actionName]
	local oldValue = self[stat] or ""
	local newValue = oldValue.. tostring(value)
	self[stat] = newValue
	self.actionCalled:Fire(actionName, stat, value)
	self.concatted:Fire(stat, newValue, oldValue)
	return newValue
end

function State:clear()
	local actionName = "clear"
	local eventName = actions[actionName]
	for k,v in pairs(self) do
		--self[k] = nil
		self:set(k, nil)
	end
	self.actionCalled:Fire(actionName)
	self.cleared:Fire()
end

function State:destroy()
	local maid = activeTables[self]
	if maid then
		maid:clean()
		return true
	end
	return false
end


-- The following giant deduces the differences between two sets of data
-- and applies these differences to the third table using the States
-- setter methods (such as :set, :insert, etc)
local function transformData(data1, data2, dataToUpdate, ignoreNilled, modifier)
	if not dataToUpdate then
		dataToUpdate = data2
	end
	
	-- account for nilled values
	if not ignoreNilled and typeof(data2) == "table" then
		for name, content in pairs(data2) do
			local dataToUpdateMain = (modifier and modifier(name, content)) or dataToUpdate
			name = Serializer.deserialize(name)
			if data1[name] == nil then
				dataToUpdateMain:set(name, nil)
			end
		end
	end
	
	-- repeat a similar process for present values
	if typeof(data1) == "table" then
		for name, content in pairs(data1) do
			-- don't deseralize hidden values and add them to _data instantly instead
			local dataToUpdateMain, extra = (modifier and modifier(name, content)) or dataToUpdate, nil
			local isPrivate = extra == "isPrivate"
			if not isPrivate then
				name = Serializer.deserialize(name)
				content = Serializer.deserialize(content)
			end
			-- Update values
			local coreValue = data2[name]
			local bothAreTables = type(coreValue) == "table" and type(content) == "table"
			if isPrivate or (coreValue ~= content and not bothAreTables) then
				-- Only set values or keys with values/tables that dont match
				local oldValueNum = tonumber(coreValue)
				local newValueNum = tonumber(content)
				dataToUpdateMain[name] = coreValue
				if oldValueNum and newValueNum then
					dataToUpdateMain:increment(name, newValueNum-oldValueNum)
				else
					dataToUpdateMain:set(name, content)
				end
			else
				-- For this section, we only want to insert/set/pair *differences*
				if type(content) == "table" then
					-- t1 | the table with new information
					local t1 = content
					-- t2 | the table we are effectively merging into
					local original_t2 = (type(coreValue) == "table" and coreValue) or {}
					local t2 = {}
					for k,v in pairs(original_t2) do
						t2[k] = v
					end
					if #content > 0 then
						-- This inserts/removes differences accoridngly using minimal amounts of moves
						local iterations = (#t1 > #t2 and #t1) or #t2
						for i = 1, iterations do
							local V1 = t1[i]
							local V2 = t2[i]
							if V1 ~= V2 then
								local nextV1 = t1[i+1]
								if nextV1 ~= V2 and V2 ~= nil then
									table.remove(t2, i)
									if not ignoreNilled then
										dataToUpdateMain:remove(name, Serializer.deserialize(V2, true), i)
									end
								end
								local newV2 = t2[i]
								if V1 ~= nil and newV2 ~= V1 then
									table.insert(t2, i, V1)
									dataToUpdateMain:insert(name, Serializer.deserialize(V1, true), i)
								end
							end
						end
					else
						-- Only pair keys with values/tables that dont match
						for k,v in pairs(t1) do
							if not(t2[k] ~= nil and isEqual(t2[k], v)) then
								k = Serializer.deserialize(k)
								v = Serializer.deserialize(v)
								dataToUpdateMain:pair(name, k, v)
							end
						end
						-- This accounts for nilled values
						if not ignoreNilled then
							for k,v in pairs(t2) do
								if t1[k] == nil then
									k = Serializer.deserialize(k)
									dataToUpdateMain:pair(name, k, nil)
								end
							end
						end
					end
				end
			end
		end
	end
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


return State