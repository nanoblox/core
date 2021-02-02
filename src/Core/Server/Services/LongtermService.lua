-- Manages permanent and timed roletypes

-- LOCAL
local main = require(game.HDAdmin)
local System = main.modules.System
local LongtermService = System.new("Longterms")
local systemUser = LongtermService.user



-- EVENTS
LongtermService.recordAdded:Connect(function(recordKey, record)
	
end)

LongtermService.recordRemoved:Connect(function(recordKey)
	
end)

LongtermService.recordChanged:Connect(function(recordKey, key, value)
	
end)



-- METHODS
function LongtermService.generateRecord(targetUserId)
	local currentTime = os.time()
	return {
		userId = targetUserId or 0,
		-- Coming soon
	}
end

function LongtermService.createLongterm(targetUserId, isGlobal, properties)
	local key = tostring(targetUserId)
	local record = LongtermService:createRecord(key, isGlobal, properties)
	return record
end

function LongtermService.getLongterm(targetUserId)
	local key = tostring(targetUserId)
	return LongtermService:getRecord(key)
end

function LongtermService.getLongterms()
	return LongtermService:getRecords()
end

function LongtermService.updateLongterm(targetUserId, propertiesToUpdate)
	local key = tostring(targetUserId)
	LongtermService:updateRecord(key, propertiesToUpdate)
	return true
end

function LongtermService.removeLongterm(targetUserId)
	local key = tostring(targetUserId)
	LongtermService:removeRecord(key)
	return true
end



return LongtermService