-- LOCAL
local main = require(game.Nanoblox)
local TimeService = {
	remotes = {
		grabLocalDate = main.modules.Remote.new("grabLocalDate"),
		grabLocalTime = main.modules.Remote.new("grabLocalTime"),
	}
}
local Promise = main.modules.Promise



-- METHODS
function TimeService.grabLocalDate(player, dateTime)
	local newDateTime = dateTime or os.time()
	local defaultDate = os.date("*t", newDateTime)
	local defaultMonth = os.date("%B", newDateTime)
	return TimeService.remotes.grabLocalDate:invokeClient(player, newDateTime)
		:timeout(3)
		:andThen(function(clientDate, clientMonth)
			clientDate = (typeof(clientDate) == "table" and clientDate) or defaultDate
			clientMonth = tostring(clientMonth)
			return clientDate, clientMonth
		end)
		:catch(function()
			return defaultDate, defaultMonth
		end)
end



return TimeService