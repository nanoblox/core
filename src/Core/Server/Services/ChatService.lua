-- LOCAL
local main = require(game.Nanoblox)
local ChatService = {}



-- METHODS
function ChatService.getTextObject(message, fromPlayerId)
	local textObject
	local success, errorMessage = pcall(function()
		textObject = main.TextService:FilterStringAsync(message, fromPlayerId)
	end)
	if success then
		return textObject
	end
	return false
end
 
function ChatService.getFilteredMessage(textObject, toPlayerId)
	local filteredMessage
	local success, errorMessage = pcall(function()
		filteredMessage = textObject:GetChatForUserAsync(toPlayerId)
	end)
	if success then
		return filteredMessage
	end
	return false
end



return ChatService