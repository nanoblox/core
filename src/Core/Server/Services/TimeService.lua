-- LOCAL
local main = require(game.HDAdmin)
local TimeService = {
	remotes = {
		"gDrabLocalDate",
		"grabLocalTime",
	}
}
local Promise = main.modules.Promise



-- METHODS
function TimeService.grabLocalDate(player, dateTime)
	dateTime = dateTime or os.time()
	return Promise.async(function(resolve, reject)
		local clientDate, clientMonth = TimeService.remotes.grabLocalDate:invokeClient(player, dateTime)
		clientDate = (typeof(clientDate) == "table" and clientDate) or {}
		clientMonth = tostring(clientMonth)
		resolve(clientDate, clientMonth)
	end)
end



return TimeService