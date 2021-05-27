--[[

This handles the synchronisation of system Data (bans, roles, etc)
between all servers. Processes such as queues are implemented to
prevent two servers saving within a 7 second period, and briefly saves
these changes to ensure server-specific perm changes are not over
written when a load request is received


As some context, Systems have three 'levels' of data:
------------------------------------------------------------------------------
1. Perm   -  This is high-level data that is synchronised globally.
             It resides within the perm table of a systems user.
             It is set by doing ``system.user.perm:setterName(...)``
------------------------------------------------------------------------------
2. Temp   -  This is combination of server-specific and Perm data.
             It resides within the temp table of a systems user.
             It is set by doing ``system.user.temp:setterName(...)``
             It inherits all changes within Perm
------------------------------------------------------------------------------
3. Display - This is a modified version of Temp data specifically
             tailored to display relavent information to services and
             clients.
             It can be viewed within ``system.records``
             It inherits all changes within Temp
------------------------------------------------------------------------------

Case Study (1): 
When a role is created on server A, it is set to Perm (e.g.
``main.services.RoleService.user.perm:set("RoleUIDHere", {name = "Guards"})``
Because it was set to Perm, this data will then synchronise across all
servers and permanently save into the datastore. It's differences then
csscade into Temp then Display.

Case Study (2)
When a role is modified within studio using the plugin, its changes are
set to the datastore. These changes are then listened for within ConfigService.
If changes are present, they are then set to Temp, which flows into Display.
In this case, data is not set to Perm, as this would cause it to infinitely
attempt to synchronisse within all servers across all servers. 


Hope that helps, go enjoy some much deserved pineapple
--]]



-- LOCAL
local main = require(game.Nanoblox)
local DataUtil = main.modules.DataUtil
local TableUtil = main.modules.TableUtil
local Thread = main.modules.Thread
local Signal = main.modules.Signal
local System = {}
System.__index = System



-- CONSTRUCTOR
function System.new(name, ignoreTempChanges)
	local self = {}
	setmetatable(self, System)
	
	local maid = main.modules.Maid.new()
	self._maid = maid
	local user = main.modules.SystemStore:createUser(name)
	local userLoadedFirstTime = false
	user.onlySaveDataWhenChanged = false
	user.ignoreSaveOnBindToClose = true
	--user.transformLoadDataTo = nil
	Thread.spawn(function()
		user:waitUntilLoaded()
		--user.transformLoadDataTo = user.temp
		--user.transformLoadDataTo = user.perm
		userLoadedFirstTime = true
	end)
	self.user = user
	self.name = name
	
	-- Record any change that occurs within perm
	-- then the server makes a request to change these globally.
	-- Calling user:temp(action, ...) duplicates System data
	-- into the temp table so that server values can be modified
	-- without modifying global data.
	local actionRecords = {}
	local globalStartTick
	local globalPending = false
	local newServerCooldown = 10 -- Needed to gauge an accurate global delay
	local newServerCooldownEnd = tick() + newServerCooldown
	local firstTimeLoading = true
	local myUIDs = {}
	user.perm.descendantChanged:Connect(function(pathwayTable, key, newValue, oldValue)
		-- Block first load completely
		if not userLoadedFirstTime then
			return
		end
		-- Repeat call for user.temp, making sure to deep copy tables
		if type(newValue) == "table" then
			newValue = TableUtil.copy(newValue)
		end
		user.temp:getOrSetup(pathwayTable):set(key, newValue)
		-- Data is being loaded from another server, block actions
		if user.transformingLoadData then
			return
		end
		table.insert(actionRecords, {pathwayTable, key, newValue})
		-- Request a global update
		-- If no global request already pending, or something
		-- went wrong (i.e. over 15 seconds elapsed), make request
		local currentTick = tick()
		if not globalPending and (not globalStartTick or currentTick - globalStartTick > 15) then
			globalStartTick = currentTick
			local function fireAway()
				local requestUID = DataUtil.generateUID(7)
				myUIDs[requestUID] = Signal.new()
				self.senderSave:fireAllServers(requestUID)
			end
			if currentTick < newServerCooldownEnd then
				Thread.delay(newServerCooldownEnd-currentTick, function()
					currentTick = tick()
					fireAway()
				end)
			else
				fireAway()
			end
		end
	end)
	
	-- Other servers may save before this server makes a save
	-- to prevent server-specific perm data being over-written in these scenarious
	-- the 'records' are re-added after the user loads
	user.loaded:Connect(function()
		local currentActionRecords = actionRecords
		actionRecords = {}
		for _, record in pairs(currentActionRecords) do
			local pathwayTable, key, newValue = unpack(record)
			user.perm:getOrSetup(pathwayTable):set(key, newValue)
		end
	end)
	-- This handles requests from this and other servers
	-- when they wish to make a global update.
	-- A cooldown queue is implemented to ensure two servers
	-- don't save at the same time
	local nextAvailableSaveTick = tick()
	local requestsList = {}
	local saveCooldown = 7
	Thread.spawn(function()
		main.waitUntilStarted()
		self.senderSave = main.services.GlobalService.createSender(name.."Save")
		self.receiverSave = main.services.GlobalService.createReceiver(name.."Save")
		self.receiverSave.onGlobalEvent:Connect(function(requestUID)
			table.insert(requestsList, requestUID)
			local readyToSaveSignal = myUIDs[requestUID]
			if readyToSaveSignal then -- If from the same server
				globalPending = true
				if #requestsList > 1 then
					readyToSaveSignal:Wait()
				end
				user:saveAsync()
				actionRecords = {}
				globalPending = false
				globalStartTick = nil
				self.senderLoad:fireAllServers(requestUID, requestsList)
			end
		end)
		self.senderLoad = main.services.GlobalService.createSender(name.."Load")
		self.receiverLoad = main.services.GlobalService.createReceiver(name.."Load")
		self.receiverLoad.onGlobalEvent:Connect(function(requestUID, globalRequestsList)
			if requestsList[1] ~= requestUID then
				-- Update new servers which may not have a complete request log
				requestsList = globalRequestsList
			end
			local isAlsoSender = myUIDs[requestUID]
			if isAlsoSender then
				isAlsoSender:Destroy()
				myUIDs[requestUID] = nil
			else
				Thread.spawn(function() user:loadAsync() end)
			end
			Thread.delay(saveCooldown, function()
				table.remove(requestsList, 1)
				local nextRequestUID = requestsList[1]
				local readyToSaveSignal = myUIDs[nextRequestUID]
				if readyToSaveSignal then
					readyToSaveSignal:Fire()
				end
			end)
		end)
	end)
	
	-- When the game requests to shutdown, ensure we wait long enough
	-- to allow for all queued requests to be processed
	if not main.RunService:IsStudio() then
		game:BindToClose(function()
			local finalRequestUID = #requestsList > 0 and requestsList[#requestsList]
			local readyToSaveSignal = myUIDs[finalRequestUID]
			if readyToSaveSignal then
				readyToSaveSignal:Wait()
			end
		end)
	end
	
	
	
	-- When data is added/modified within the temp table, update this
	-- data with default values (from generateRecord), and call the
	-- necessary service-object events
	if not ignoreTempChanges then
		local realRecords = {}
		----
		self.records = main.modules.State.new(nil, true)
		----
		self.recordAdded = maid:give(Signal.new())
		self.recordRemoved = maid:give(Signal.new())
		self.recordChanged = maid:give(Signal.new())
		self.recordsActionDelay = 0.1
		self.originalRecordsActionDelay = self.recordsActionDelay
		local changedUIDs = {}
		local expiryRecordsToWatch = {}
		local expiryWatchInterval = 1200 -- 20 minutes
		local nextExpiryUpdate = os.time()
		local pairedUIDs = {}
		user.temp.descendantChanged:Connect(function(pathwayTable, key, newValue, oldValue)
			
			------ TOP LAYER (calls recordAdded and recordRemoved) ------
			local depth = #pathwayTable
			if depth == 0 then
				local recordKey, record = key, newValue
				-- Ignore records labelled as 'nilled' (i.e. within NilledData)
				local ConfigService = main.services.ConfigService or (main.waitUntilStarted() and main.services.ConfigService)
				if ConfigService then
					local nilledUser = ConfigService.nilledUser
					nilledUser:waitUntilLoaded()
					if nilledUser.perm:find(name, recordKey) and record ~= nil then
						return
					end
				end
				-- Record added/removed
				local action 
				local recordValue = nil
				if record then
					-- Fill record with default values
					local newRecord = TableUtil.copy(record)
					local generateRecord = self.generateRecord
					if generateRecord then
						local defaultRecord = generateRecord(recordKey)
						for k, v in pairs(defaultRecord) do
							if newRecord[k] == nil then
								newRecord[k] = v
							end
						end
					end
					-- Mark record as global if present within config
					if main.config[self.name] and main.config[self.name][recordKey] ~= nil and user.temp[recordKey]._global == nil then
						user.temp[recordKey]:set("_global", true)
					end
					action = function()
						if realRecords[recordKey] then
							-- If record already exists, pair instead
							for k,v in pairs(record) do
								user.temp[recordKey]:set(k, v)
							end
						else
							-- Check for an expiryTime
							---------------
							local expiryTime = tonumber(newRecord.expiryTime)
							if expiryTime then
								local currentTime = os.time()
								if expiryTime <= currentTime then
									-- Record has expired, do not add
									return
								elseif expiryTime <= nextExpiryUpdate then
									-- Record is near to expiring, watch closely
									expiryRecordsToWatch[recordKey] = true
								end
							end
							---------------
							self.recordAdded:Fire(recordKey, newRecord)
							realRecords[recordKey] = newRecord
						end
					end
					recordValue = newRecord
				else
					-- If record has already been nilled, ignore
					if self.records[recordKey] == nil then
						return
					end
					action = function()
						if realRecords[recordKey] ~= nil then
							self.recordRemoved:Fire(recordKey, oldValue)
						end
						realRecords[recordKey] = nil
					end
				end
				self.records:set(recordKey, recordValue)
				-- Data may change rapidly - filter these rapid changes and only
				-- show the last request
				local actionUID = DataUtil.generateUID()
				changedUIDs[recordKey] = actionUID
				--print(name, recordKey, " self.recordsActionDelay = ", self.recordsActionDelay)
				local function endFunc()
					if changedUIDs[recordKey] ~= actionUID then
						return
					end
					changedUIDs[recordKey] = nil--]]
					-- Call action
					action()
				end
				if self.recordsActionDelay > 0 then
					Thread.delay(self.recordsActionDelay, endFunc)
				else
					endFunc()
				end

			
			
			
			
			------ DESCENDANT LAYERS (calls recordChanged) ------
			else
				-- Only the first and second layers are important to us. When a change is made
				-- made below the second layer, find its ancestor 2nd layer and call this instead
				local recordKey = pathwayTable[1]
				local propName = (depth == 1 and key) or pathwayTable[2]
				local newPropValue = (depth == 1 and newValue) or user.temp[recordKey][propName]
				local displayOldPropValue = self.records[recordKey] and self.records[recordKey][propName]
				local oldPropValue = (depth == 1 and oldValue) or displayOldPropValue or newPropValue

				-- If the record does not exist already (i.e. is nilled) then ignore
				if self.records[recordKey] == nil then
					return
				end
				-- If the records prop already equals newProp, then ignore
				if DataUtil.isEqual(displayOldPropValue, newPropValue) then
					return
				end
				-- Record changed
				if type(newPropValue) == "table" then
					newPropValue = TableUtil.copy(newPropValue)
				end
				self.records[recordKey][propName] = newPropValue
				-- Data may change rapidly - flter these rapid changes and only
				-- show the last request
				local actionUID = DataUtil.generateUID()
				local actionKey = recordKey.." | "..propName
				pairedUIDs[actionKey] = actionUID
				
				local function endFunc()
					if pairedUIDs[actionKey] ~= actionUID then
						return
					end
					pairedUIDs[actionKey] = nil
					-- Expiry checks
					local currentTime = os.time()
					if propName == "expiryTime" then
						if realRecords[recordKey] == nil and newPropValue > currentTime then
							-- If previously expired and no longer, then re-add
							user.temp:set(recordKey, self.records[recordKey])
							return
						elseif newPropValue <= nextExpiryUpdate and not expiryRecordsToWatch[recordKey] then
							-- Value falls within close-watch range, add to tracking
							expiryRecordsToWatch[recordKey] = true
						end
					end
					-- Call action
					self.recordChanged:Fire(recordKey, propName, newPropValue, oldPropValue)
					realRecords[recordKey][propName] = newPropValue
				end
				if self.recordsActionDelay > 0 then
					Thread.delay(self.recordsActionDelay, endFunc)
				else
					endFunc()
				end
				

			end



		end)
		
		-- Some records can expire, such as bans and timed role. This section
		-- is designed to track these expiry times, and hide or call any
		-- necessary events accordingly. For instance, if a record
		-- expires, we do not want it to appear on the client, therefore we
		-- remove it from realRecords. On records that are near to expiring
		-- (i.e. within 20 minutes of the current time) are closely watched.
		-- This precise watch is updated every 20 minutes.
		
		--Thread.loopUntil(1, function() return not System end, function()
		Thread.delayLoop(1, function()
			local currentTime = os.time()
			-- Every 20 minutes, determine if any records need close watching
			if currentTime >= nextExpiryUpdate then
				nextExpiryUpdate = currentTime + expiryWatchInterval
				expiryRecordsToWatch = {}
				for recordKey, record in pairs(realRecords) do
					if typeof(record) == "table" and record.expiryTime and record.expiryTime <= nextExpiryUpdate then
						expiryRecordsToWatch[recordKey] = true
					end
				end
			end
			-- Check to see if a closely watched record has expired
			for recordKey, _ in pairs(expiryRecordsToWatch) do
				local record = realRecords[recordKey]
				if not record then
					expiryRecordsToWatch[recordKey] = nil
				else
					local expiryTime = (tonumber(record.expiryTime) and record.expiryTime) or currentTime
					if expiryTime <= currentTime then
						expiryRecordsToWatch[recordKey] = nil
						self.recordRemoved:Fire(recordKey, record)
						realRecords[recordKey] = nil
					end
				end
			end
		end)
		
		-- Tyically when data is set, it is delayed by 0.1 seconds (i.e.
		-- self.recordsActionDelay). This enables rapid changes to be made within temp and perm,
		-- without pointlessly updating in the display records. Sometimes this delay is undesirable,
		-- for instance, when an external user wishes to create a role. To overcome this,  we wrap all 
		-- System methods so that they can bypass this delay and return values instantly
		for methodName, method in pairs(System) do
			if typeof(method) == "function" and methodName ~= "new" then
				self[methodName] = function(...)
					local previousRecordsActionDelay = self.recordsActionDelay
					self.recordsActionDelay = 0
					local returnValue = table.pack(method(...))
					self.recordsActionDelay = previousRecordsActionDelay
					return unpack(returnValue)
				end
			end
		end
		
	end
	
	
	
	return self
end



-- METHODS
function System:createRecord(key, isGlobal, properties)
	local user = self.user
	local data = user.temp
	if isGlobal or properties._global == true then
		properties._global = true
		data = user.perm
	else
		properties._global = false
	end
	data:set(key, properties)
	return data
end

function System:getRecord(key)
	key = tostring(key)
	local record = self.records[key]
	if not record then
		return false
	end
	return record
end

function System:getRecords()
	local recordsArray = {}
	for key, record in pairs(self.records) do
		table.insert(recordsArray, record)
	end
	return recordsArray
end

function System:updateRecord(key, propertiesToUpdate)
	--
	propertiesToUpdate = propertiesToUpdate or {}
	local user = self.user
	local record = user.temp[key]
	local prevGlobal = record and record._global
	local newGlobal = propertiesToUpdate._global
	if newGlobal == nil then
		newGlobal = prevGlobal
	end
	if prevGlobal ~= newGlobal and typeof(newGlobal) == "boolean" then
		local currentData = TableUtil.copy(user.temp)
		if newGlobal == true then
			-- Create role on all servers, then update with new props below
			user.perm:set(key, currentData)
		else
			-- Remove role on all servers, then re-add for this server
			user.perm:set(key, nil)
			user.temp:set(key, currentData)
		end
	end
	--
	local data = (newGlobal == true and user.perm) or user.temp
	for propName, propValue in pairs(propertiesToUpdate) do
		data:getOrSetup(key):set(propName, propValue)
	end
	return data
end

function System:removeRecord(key)
	local user = self.user
	local record = user.temp[key]
	local data = (record and record._global == true and user.perm) or user.temp
	data:set(key, nil)
	return true
end



--[[
local main = require(game.Nanoblox)
local SystemStore = main.modules.SystemStore
local user = SystemStore:getUser("Roles")
local roleUID = "Role0002"
local roleData = user.perm:getOrSetup(roleUID)
roleData:set("year", 20)
--]]


return System