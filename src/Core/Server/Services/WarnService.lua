-- LOCAL
local main = require(game.Nanoblox)
local System = main.modules.System
local WarnService = System.new("Warns")
local systemUser = WarnService.user
local PlayerStore = main.modules.PlayerStore



-- EVENTS
WarnService.recordAdded:Connect(function(recordKey, record)
	
end)

WarnService.recordRemoved:Connect(function(recordKey)
	
end)

WarnService.recordChanged:Connect(function(recordKey, key, value)
	
end)



-- PLAYERSERVICE METHODS
function WarnService.playerAddedMethod(player)
	
end

function WarnService.playerLoadedMethod(player, user)
	
end



-- METHODS
function WarnService.generateRecord(targetUserId)
	local currentTime = os.time()
	return {
		userId = targetUserId or 0,
		-- Coming soon, to be decided
		--[[
		banTime = currentTime,
		expiryTime = currentTime + unbanLimit*2,
		reason = "",
		callerId = 0,
		callerHighestRoleUID = "",
		--]]
	}
end

function WarnService.verifyWarn(targetUserId, callerUser)
	
end

function WarnService.warn(targetUserId, callerUser, isGlobal, properties)
	
end

function WarnService.createWarn(targetUserId, isGlobal, properties)
	local key = tostring(targetUserId)
	local record = WarnService:createRecord(key, isGlobal, properties)
	return record
end

function WarnService.getWarn(targetUserId)
	local key = tostring(targetUserId)
	return WarnService:getRecord(key)
end

function WarnService.getWarns()
	return WarnService:getRecords()
end

function WarnService.updateWarn(targetUserId, propertiesToUpdate)
	local key = tostring(targetUserId)
	WarnService:updateRecord(key, propertiesToUpdate)
	return true
end

function WarnService.removeWarn(targetUserId)
	local key = tostring(targetUserId)
	WarnService:removeRecord(key)
	return true
end

function WarnService.kick(player)
	
end



return WarnService