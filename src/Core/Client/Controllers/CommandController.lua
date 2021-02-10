-- LOCAL
local main = require(game.Nanoblox)
local CommandController = {}



-- START
function CommandController.start()
	
	local clientCommandRequest = main.modules.Remote.new("clientCommandRequest")
	clientCommandRequest.onClientEvent:Connect(function()
		
	end)
	
end



return CommandController