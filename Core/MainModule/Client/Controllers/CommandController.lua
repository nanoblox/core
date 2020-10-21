-- LOCAL
local main = require(game.HDAdmin)
local CommandController = {}



-- START
function CommandController:start()
	
	local clientCommandRequest = main.controllers.RemoteController.getRemote("CommandService_clientCommandRequest")
	clientCommandRequest.onClientEvent:Connect(function()
		
	end)
	
end



return CommandController