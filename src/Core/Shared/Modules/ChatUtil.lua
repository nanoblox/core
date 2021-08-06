-- LOCAL
local main = require(game.Nanoblox)
local ChatUtil = {}



-- METHODS
function ChatUtil.getTextObject(message, fromPlayerId)
	return main.modules.Promise.defer(function(resolve, reject)
		local success, textObjectOrError = pcall(main.TextService.FilterStringAsync, main.TextService, message, fromPlayerId)
		if success then
			resolve(textObjectOrError)
		end
		reject(textObjectOrError)
	end)
end
 
function ChatUtil.getFilteredMessage(textObject, toPlayerId)
	return main.modules.Promise.defer(function(resolve, reject)
		if not textObject then reject("textObject arg[1] required!") end
		local success, filteredMessageOrError = pcall(textObject.GetChatForUserAsync, textObject, toPlayerId)
		if not success then
			success, filteredMessageOrError = pcall(textObject.GetNonChatStringForBroadcastAsync, textObject)
		end
		if success then
			resolve(filteredMessageOrError)
		end
		reject(filteredMessageOrError)
	end)
end

function ChatUtil.filterText(fromUserId, toUserId, textToFilter)
	local ERROR_MESSAGE = "Error: '%s'"
	return ChatUtil.getTextObject(textToFilter, fromUserId)
		:andThen(function(textObject)
			return ChatUtil.getFilteredMessage(textObject, toUserId)
				:andThen(function(filteredMessage)
					return filteredMessage
				end)
				:catch(function(warning)
					return ERROR_MESSAGE:format(warning)
				end)
		end)
		:catch(function(warning)
			return ERROR_MESSAGE:format(warning)
		end)
end

function ChatUtil.getSpeaker(player)
	return main.modules.Promise.new(function(resolve, reject)
		local ChatService = require(game:GetService("ServerScriptService"):WaitForChild("ChatServiceRunner").ChatService)
		local speaker = ChatService:GetSpeaker(player.Name)
    	local checkPlayer = speaker and speaker:GetPlayer()
		if not checkPlayer then
			reject(("Speaker '%s' does not exist"):format(tostring(player.Name)))
		end
		resolve(speaker)
	end)
end

function ChatUtil.hideChat(player)
	-- Wait for a response from https://devforum.roblox.com/t/brand-new-bubble-chat-customizations/1252869/139 before supporting this
end

function ChatUtil.showChat(player)
	-- Wait for a response from https://devforum.roblox.com/t/brand-new-bubble-chat-customizations/1252869/139 before supporting this
end
	



return ChatUtil