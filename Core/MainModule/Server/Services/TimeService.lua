-- LOCAL
local main = require(game.HDAdmin)
local TimeService = {}
local Promise = main.modules.Promise



-- START
function TimeService:start()
	TimeService.grabLocalDateRemote = main.services.RemoteService:createRemote("grabLocalDate")
	TimeService.grabLocalTimeRemote = main.services.RemoteService:createRemote("grabLocalTime")
end



-- METHODS
function TimeService.grabLocalDate(player, dateTime)
	dateTime = dateTime or os.time()
	return Promise.async(function(resolve, reject)
		local clientDate, clientMonth = TimeService.grabLocalDateRemote:invokeClient(player, dateTime)
		clientDate = (typeof(clientDate) == "table" and clientDate) or {}
		clientMonth = tostring(clientMonth)
		resolve(clientDate, clientMonth)
	end)
end



return TimeService