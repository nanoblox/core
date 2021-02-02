--[[
The commenting was a little lackluster at the time of writing this
service, so I'll aim to re-highlight more clearly and in greater detail sometime.
In short, it provides and abstraction of MessagingService using 'Senders' and
'Receivers', with methods similar to RemoteEvents and RemoteFunctions, to make
communication between servers effortless, while internally handling limits.

Raining Tacos Example:
---------------------
local GlobalService = main.services.GlobalService
local UNIQUE_EVENT_NAME = "RainingTacos"

local receiver = GlobalService.createReceiver(UNIQUE_EVENT_NAME)
receiver.onGlobalEvent:Connect(function(playerName)
	print(playerName.." made all servers rain tacos!")
	--> Rain tacos
end)

local sender = GlobalService.createSender(UNIQUE_EVENT_NAME)
local function whenAPlayerPurchasesAnItemToMakeEverywhereRainRacos(player)
	sender:fireAllServers(player.Name)
end
---------------------
]]



-- LOCAL
local main = require(game.HDAdmin)
local GlobalService = {}
local Promise = main.modules.Promise
local Thread = main.modules.Thread
local Sender = main.modules.Sender
local Receiver = main.modules.Receiver
local Signal = main.modules.Signal
local senders = {}
local receivers = {}
local GLOBAL_TOPIC = "HDAdmin"
local messagingService = main.MessagingService
local messagesThisMinute = 0
local nextRefresh = tick() + 60
local records = {}
local subscribersChanged = Signal.new()
local publishing = false
local published = Signal.new()

local function publish(topic, data)
	data = main.modules.Serializer.serialize(data)
	return Promise.async(function(resolve, reject)
		local ok, result = pcall(messagingService.PublishAsync, messagingService, topic, data)
		if ok then
			resolve(result)
		else
			reject(result)
		end
	end)
end

local function subscribe(topic, func)
	return Promise.async(function(resolve, reject)
		local ok, result = pcall(messagingService.SubscribeAsync, messagingService, topic, func)
		if ok then
			resolve(result)
		else
			reject(result)
		end
	end)
end

local function getInvocationTopic(name, UID)
	return(name..UID)
end

local function getDataSize(data)
	return(#main.HttpService:JSONEncode(data))
end

local function finishRecord(record)
	record.finished:Fire()
	record.finished:Destroy()
	record = nil
end



-- CONFIG
GlobalService.maxMessagesPerMinute = 20
GlobalService.ignoreFirstPercentile = 0.2
GlobalService.maxMessageSize = 950
GlobalService.published = Signal.new()
GlobalService.flushed = Signal.new()



-- METHODS (SENDERS)
function GlobalService.getMessageDelay(messageNumber)
	local maxMessagesPerMinute = GlobalService.maxMessagesPerMinute
	local ignoreFirstPercentile = GlobalService.ignoreFirstPercentile
	local ignoredMessages = maxMessagesPerMinute * ignoreFirstPercentile
	local staggeredMessages = maxMessagesPerMinute * (1 - ignoreFirstPercentile)
	local meanDelay = 60 / staggeredMessages -- 6
	local interval = meanDelay / (staggeredMessages * 0.5)
	local messageDelay = interval * (messageNumber - ignoredMessages - 0.5)
	messageDelay = (messageDelay < 0 and 0) or messageDelay
	return messageDelay
end

function GlobalService.updateMessagesThisMinute()
	local currentTick = tick()
	if currentTick > nextRefresh then
		nextRefresh = currentTick + 60
		messagesThisMinute = 0
	end
end

function GlobalService.incrementMessages(amount)
	messagesThisMinute = messagesThisMinute + amount
	GlobalService.updateMessagesThisMinute()
end

function GlobalService.addRecord(record)
	-- Apply invocation details
	local invocationUID = record.iui
	if invocationUID then
		local connection
		local invocationTopic = getInvocationTopic(record.name, invocationUID)
		local pendingServers = {}
		local pendingCount = 0
		local response = false
		local invocationTimeout = 3
		local dataFromServers = {}
		local function informSender()
			local sender = GlobalService.getSender(record.name)
			if not sender then
				return "No sender present"
			end
			local invocationSignal = sender[invocationTopic]
			if not invocationSignal then
				return "No invocationSignal present"
			end
			invocationSignal:Fire(dataFromServers)
		end
		local active = true
		local function endSubscription()
			if connection then
				subscribersChanged:Fire()
				connection:Disconnect()
			end
			active = false
		end
		Thread.spawnNow(function()
			record.finished:Wait()
			Thread.delay(invocationTimeout, function()
				if not response then
					informSender()
					endSubscription()
				end
			end)
		end)
		local invocationSub
		invocationSub = function()
			subscribe(invocationTopic, function(message)
				local data = main.modules.Serializer.deserialize(message.Data)
				local jobId = data.jobId
				if not pendingServers[jobId] then
					response = true
					pendingServers[jobId] = true
					pendingCount = pendingCount + 1
				else
					table.insert(dataFromServers, data)
					pendingServers[jobId] = nil
					pendingCount = pendingCount - 1
				end
				Thread.delay(1, function()
					if pendingCount == 0 then
						endSubscription()
						pendingCount = nil
						informSender()
					end
				end)
			end)
				:andThen(function(RBXScriptConnection)
					connection = RBXScriptConnection
				end)
				:catch(function(warning)
					subscribersChanged:Wait()
					if active then 
						invocationSub()
					end
				end)
		end
		invocationSub()
	end
	
	-- Insert detail, and set release countdown if first detail
	GlobalService.flushRecord(record)
end

function GlobalService.flushRecord(record)
	if publishing then
		published:Wait()
	end
	local recordSize = getDataSize(record)
	local maxMessageSize = GlobalService.maxMessageSize
	if recordSize > maxMessageSize then
		finishRecord(record)
		return "Abort record, too large"
	end
	local allRecordsSize = getDataSize(records)
	if allRecordsSize + recordSize > maxMessageSize then
		Thread.spawnNow(function()
			GlobalService.flushed:Wait()
			GlobalService.flushRecord(record)
		end)
		return "Limit per message reached, queue record until next flush"
	end
	table.insert(records, record)
	if #records == 1 then
		local delayTime = GlobalService.getMessageDelay(messagesThisMinute)
		main.RunService.Heartbeat:Wait()
		Thread.delay(delayTime, GlobalService.publishRecords, GlobalService, records)
	end
end

function GlobalService.verifyCanPublish(recordsToFlush)
	GlobalService.updateMessagesThisMinute()
	local dataSize = getDataSize(recordsToFlush)
	if dataSize > GlobalService.maxMessageSize then
		return false, "Message size too large; send smaller requests."
	end
	local exceededMessageLimit = messagesThisMinute > GlobalService.maxMessagesPerMinute
	if exceededMessageLimit then
		return false, "Exceeded permitted global requests per minute."
	end
	return true
end

function GlobalService.publishRecords(recordsToFlush)
	
	local function updateUsers(success, warning)
		local users = main.modules.PlayerStore:getUsers()
		for _, user in pairs(users) do
			--[[
			if user.temp:get("pendingGlobalRequest") then
				user.temp:set("pendingGlobalRequest", false)
				if not success then
					-- send an error message to client !!!
				end
			end--]]
		end
		records = {}
		GlobalService.flushed:Fire()
	end
	
	local function reflushImportantRecords()
		local exceededMessageLimit = messagesThisMinute > GlobalService.maxMessagesPerMinute
		local delayTime = (exceededMessageLimit and nextRefresh + 1 - tick()) or 0
		Thread.delay(delayTime, function()
			local cumulativeDataSize = 0
			for _, record in pairs(recordsToFlush) do
				if record.fr then
					GlobalService.flushRecord(record)
				else
					finishRecord(record)
				end
			end
		end)
	end
	
	-- Block message publishing if any limits exceeded
	local canPublish, warning = GlobalService.verifyCanPublish(recordsToFlush)
	if not canPublish then
		updateUsers(canPublish, warning)
		reflushImportantRecords()
	end
	
	-- Publish message and catch any errors
	local parsedRecordsToFlush = {}
	for _, record in pairs(recordsToFlush) do
		local parsedRecord = {}
		for k, v in pairs(record) do
			if not(type(v) == "table" and v.Destroy) then
				parsedRecord[k] = v
			end
		end
		table.insert(parsedRecordsToFlush, parsedRecord)
	end
	local dataToSend = {
		jobId = game.JobId,
		records = parsedRecordsToFlush
	}
	publishing = true
	publish(GLOBAL_TOPIC, dataToSend)
		:andThen(function(body)
			updateUsers(true)
			for _, record in pairs(recordsToFlush) do
				finishRecord(record)
			end
			GlobalService.published:Fire()
		end)
		:catch(function(warningError)
			updateUsers(false, warningError)
			reflushImportantRecords()
		end)
		:finally(function()
		publishing = false
			published:Fire()
		end)
end

function GlobalService.createSender(name)
	
	-- Setup
	assert(not senders[name], ("sender '%s' already exists!"):format(name))
	local sender = Sender.new(name)
	senders[name] = sender
	
	-- Listen
	sender.addRequest.OnInvoke = function(requestType, ...)
		local isInvocation = requestType:sub(1,1) == "I"
		local invocationUID = (isInvocation and main.modules.DataUtil.generateUID(3)) or nil
		local record = {
			rt = requestType, -- What servers will act upon the record
			name = name, -- The name to be associated with a Receiver
			fr = (sender.forceRetry == true) or nil, -- Should the record be re-added if its message fails?
			iui = invocationUID, -- Invocation Unqiue Identifier
			args = table.pack(...), -- Specified arguments
			finished = Signal.new() -- Just before the record is published or aborted, call this, then destroy
		}
		GlobalService.addRecord(record)
		if isInvocation then
			local invocationTopic = getInvocationTopic(name, invocationUID)
			local invocationSignal = Signal.new()
			sender._maid[invocationTopic] = invocationSignal
			sender[invocationTopic] = invocationSignal
			local dataFromServers = invocationSignal:Wait()
			sender._maid[invocationTopic] = nil
			sender[invocationTopic] = nil
			return dataFromServers
		end
	end
	
	return sender
end

function GlobalService.getSender(name)
	local sender = senders[name]
	if not sender then
		return false
	end
	return sender
end

function GlobalService.getSenders()
	local allSenders = {}
	for name, sender in pairs(senders) do
		table.insert(allSenders, sender)
	end
	return allSenders
end

function GlobalService.removeSender(name)
	local sender = senders[name]
	assert(sender, ("sender '%s' not found!"):format(name))
	sender:destroy()
	senders[name] = nil
	return true
end



-- METHODS (RECEIVERS)
function GlobalService.start()
	local function executeRecord(jobId, record)
		local requestType = record.rt
		local target = requestType:sub(2,2)
		if target == "O" and jobId == game.JobId then
			return "Ignore: receiver == sender"
		elseif target == "S" then
			local targetJobId = record.args[1]
			if targetJobId ~= game.JobId then
				return "Ignore: not the target server"
			end
			table.remove(record.args, 1)
		end
		local action = requestType:sub(1,1)
		local receiver = GlobalService.getReceiver(record.name)
		if not receiver then
			return "Receiver not found"
		end
		if action == "F" then
			receiver.onGlobalEvent:Fire(table.unpack(record.args))
		elseif action == "I" then
			local func = receiver.onGlobalInvoke
			if not func then
				return "onGlobalInvoke function not present"
			end
			-- Fire off initial response to sender can generate a 'count'
			local invocationTopic = getInvocationTopic(record.name, record.iui)
			local dataToSend = {
				jobId = game.JobId,
			}
			publish(invocationTopic, dataToSend)
				:catch(function(warning)
					
				end)
			-- Invoke function and return desired info
			local info = table.pack(func(table.unpack(record.args)))
			dataToSend.info = info
			publish(invocationTopic, dataToSend)
				:catch(function(warning)
					
				end)
		end
	end
	subscribe(GLOBAL_TOPIC, function(message)
		local data = main.modules.Serializer.deserialize(message.Data)
		local jobId = data.jobId
		local newRecords = data.records
		-- Reset messagesThisMinute if 60 seconds elapsed
		GlobalService.incrementMessages(1)
		-- Execute appropriate records
		for _, record in pairs(newRecords) do
			executeRecord(jobId, record)
		end
	end)
		:catch(function(warning)
			warn(("Failed to subscribe to global topic '%s': %s"):format(GLOBAL_TOPIC, warning))
		end)
end

function GlobalService.createReceiver(name)
	assert(not receivers[name], ("receiver '%s' already exists!"):format(name))
	local receiver = Receiver.new(name)
	receiver.name = name
	receivers[name] = receiver
	return receiver
end

function GlobalService.getReceiver(name)
	local receiver = receivers[name]
	if not receiver then
		return false
	end
	return receiver
end

function GlobalService.getReceivers()
	local allReceivers = {}
	for name, receiver in pairs(receivers) do
		table.insert(allReceivers, receiver)
	end
	return allReceivers
end

function GlobalService.removeReceiver(name)
	local receiver = receivers[name]
	assert(receiver, ("sender '%s' already exists!"):format(name))
	receiver:destroy()
	receivers[name] = nil
	return true
end



GlobalService._order = 2
return GlobalService