-- LOCAL
local main = require(game.HDAdmin)
local TimeController = {}



-- START
function TimeController:start()
	
	local grabLocalDate = main.controllers.RemoteController:getRemote("grabLocalDate")
	grabLocalDate.onClientInvoke = function(dateTime)
		return os.date("*t", dateTime), os.date("%B", dateTime)
	end
	
	local grabLocalTime = main.controllers.RemoteController:getRemote("grabLocalTime")
	grabLocalTime.onClientInvoke = function()
		return os.time()
	end
	
end



return TimeController