-- LOCAL
local main = require(game.Nanoblox)
local TimeController = {}



-- START
function TimeController.start()
	
	local grabLocalDate = main.modules.Remote.new("grabLocalDate")
	grabLocalDate.onClientInvoke = function(dateTime)
		return os.date("*t", dateTime), os.date("%B", dateTime)
	end
	
	local grabLocalTime = main.modules.Remote.new("grabLocalTime")
	grabLocalTime.onClientInvoke = function()
		return os.time()
	end
	
end



return TimeController