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
function TimeService.grabLocalDateAsync(player, dateTime)
	local newDateTime = dateTime or os.time()
	local returnDate = os.date("*t", newDateTime)
	local returnMonth = os.date("%B", newDateTime)
	local promise = TimeService.remotes.grabLocalDate:invokeClient(player, newDateTime)
		:timeout(3)
		:andThen(function(clientDate, clientMonth)
			returnDate = (typeof(clientDate) == "table" and clientDate) or returnDate
			returnMonth = tostring(clientMonth)
		end)
	promise:await()
	return returnDate, returnMonth
end



return TimeService