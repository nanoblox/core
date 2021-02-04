-- LOCAL
local main = require(game.Nanoblox)
local MessageService = {
	remotes = {
		message = main.services.RemoteService.createRemote("message"),
		hint = main.services.RemoteService.createRemote("hint"),
		notice = main.services.RemoteService.createRemote("notice"),
		alert = main.services.RemoteService.createRemote("alert"),
	},
}



-- METHODS
--[[
	messageDetails = {
		title = [String],
		subtitle = [String],
		text = [String],
		icon = [ImageId],
		titleColor = [Color3],
		subtitleColor = [Color3],
		textColor = [Color3],
		backgroundColor = [Color3],
		duration = [Number],
		stack = [Bool],
		override = [Bool],
	}
]]
function MessageService.message(player, messageDetails)
	MessageService.remotes.message:Fire(player, messageDetails)
end

function MessageService.messageAll(messageDetails)
	for _, player in pairs(main.Players:GetPlayers()) do
		MessageService.message(player, messageDetails)
	end
end

--[[
	hintDetails = {
		text = [String],
		textColor = [Color3],
		backgroundColor = [Color3],
		duration = [Number],
		stack = [Bool],
		override = [Bool],
	}
]]
function MessageService.hint(player, hintDetails)
	MessageService.remotes.message:Fire(player, hintDetails)
end

function MessageService.hintAll(hintDetails)
	for _, player in pairs(main.Players:GetPlayers()) do
		MessageService.hint(player, hintDetails)
	end
end

--[[
	noticeDetails = {
		title = [String],
		text = [String],
		icon = [ImageId],
		titleColor = [Color3],
		textColor = [Color3],
		duration = [Number],
		stack = [Bool],
		override = [Bool],
		error = [Bool],
		clickDetails = [Table],
		soundId = [SoundId],
		volume = [Number],
		pitch = [Number],
	}
]]
function MessageService.notice(player, noticeDetails)
	MessageService.remotes.message:Fire(player, noticeDetails)
end

function MessageService.noticeAll(noticeDetails)
	for _, player in pairs(main.Players:GetPlayers()) do
		MessageService.notice(player, noticeDetails)
	end
end

--[[
	alertDetails = {
		title = [String],
		text = [String],
		titleColor = [Color3],
		textColor = [Color3],
		duration = [Number],
		stack = [Bool],
		override = [Bool],
		soundId = [SoundId],
		volume = [Number],
		pitch = [Number],
	}
]]
function MessageService.alert(player, alertDetails)
	MessageService.remotes.message:Fire(player, alertDetails)
end

function MessageService.alertAll(alertDetails)
	for _, player in pairs(main.Players:GetPlayers()) do
		MessageService.alert(player, alertDetails)
	end
end



return MessageService