-- LOCAL
local main = require(game.Nanoblox)
local MessageService = {
	remotes = {}
}



-- START
function MessageService.start()

    local message = main.modules.Remote.new("message")
    MessageService.remotes.message = message

	local hint = main.modules.Remote.new("hint")
    MessageService.remotes.hint = hint

	local notice = main.modules.Remote.new("notice")
    MessageService.remotes.notice = notice

	local popup = main.modules.Remote.new("popup")
    MessageService.remotes.popup = popup
    
end



--[[ MESSAGES
Silent, cover the entire screen, fade dark, disappear after read duration, cannot be hidden/closed, appear consecutively when multiple

```
messageDetails = {
	title = [String],
	subtitle = [String],
	body = [String],
	icon = [ImageId],
	titleColor = [Color3],
	subtitleColor = [Color3],
	textColor = [Color3],
	backgroundColor = [Color3],
}
```
]]

MessageService.messageProperties = {
	defaultTitleColor = Color3.fromRGB(255, 255, 255),
	defaultSubtitleColor = Color3.fromRGB(255, 255, 255),
	defaultBodyColor = Color3.fromRGB(255, 255, 255),
	defaultBackgroundColor = Color3.fromRGB(0, 0, 0),
	soundEnabled = false,
	soundId = 0,
	soundVolume = 0.2,
	soundPitch = 1,
}

function MessageService.message(player, messageDetails)
	MessageService.remotes.message:Fire(player, messageDetails)
end

function MessageService.messagePool(targetPoolName, packedPoolArgs, messageDetails)
	local playersArray = main.enum.TargetPool.getProperty(targetPoolName)(table.unpack(packedPoolArgs))
	for _, player in pairs(playersArray) do
		MessageService.message(player, messageDetails)
	end
end



--[[ HINTS
Consider basing on https://material.io/components/banners#anatomy and snackbars (but for the topbar)
Rounded rectangle, span part of the top screen, disappear after read duration OR remain until revoked, cannot be hidden/closed, stack when multiple (form a scrollbar after X amount)

```
hintDetails = {
	text = [String],
	textColor = [Color3],
	backgroundColor = [Color3],
	disappear = [Bool],
}
```
]]

MessageService.hintProperties = {
	defaultTextColor = Color3.fromRGB(255, 255, 255),
	defaultBackgroundColor = Color3.fromRGB(0, 0, 0),
	soundEnabled = false,
	soundId = 0,
	soundVolume = 0.2,
	soundPitch = 1,
}

function MessageService.hint(player, hintDetails)
	MessageService.remotes.message:Fire(player, hintDetails)
end

function MessageService.hintPool(targetPoolName, packedPoolArgs, hintPool)
	local playersArray = main.enum.TargetPool.getProperty(targetPoolName)(table.unpack(packedPoolArgs))
	for _, player in pairs(playersArray) do
		MessageService.hint(player, hintPool)
	end
end



--[[ NOTICES
Consider basing on https://material.io/components/banners
Rounded rectangle, appear in bottom right corner, disappear after duration OR remain until closed, can be closed, stack when multiple (form a scrollbar after X amount)

```
noticeDetails = {
	text = [String],
	icon = [ImageId],
	disappear = [Bool],
	duration = [Number],
	soundId = [Integer],
	actions = [Table],
}
```
]]

MessageService.noticeProperties = {
	soundEnabled = true,
	promptSoundId = 2865227271,
	errorSoundId = 2865228021,
	soundVolume = 0.1,
	soundPitch = 1,
}

function MessageService.notice(player, noticeDetails)
	MessageService.remotes.message:Fire(player, noticeDetails)
end

function MessageService.noticePool(targetPoolName, packedPoolArgs, noticeDetails)
	local playersArray = main.enum.TargetPool.getProperty(targetPoolName)(table.unpack(packedPoolArgs))
	for _, player in pairs(playersArray) do
		MessageService.notice(player, noticeDetails)
	end
end



--[[ SNACKBARS
Consider basing on https://material.io/components/snackbars
Rounded rectangle, appear in bottom right corner, disappear after duration OR remain until closed, can be closed, stack when multiple (form a scrollbar after X amount)

```
snackbarDetails = {
	text = [String],
	soundId = [Integer],
	actions = [Table],
}
```
]]

MessageService.snackbarProperties = {
	soundEnabled = false,
	soundId = 0,
	soundVolume = 0.2,
	soundPitch = 1,
}

function MessageService.snackbar(player, snackbarDetails)
	MessageService.remotes.message:Fire(player, snackbarDetails)
end

function MessageService.snackbarPool(targetPoolName, packedPoolArgs, snackbarDetails)
	local playersArray = main.enum.TargetPool.getProperty(targetPoolName)(table.unpack(packedPoolArgs))
	for _, player in pairs(playersArray) do
		MessageService.snackbar(player, snackbarDetails)
	end
end



--[[ POPUPS
Rectangular, appear mid screen, must be closed manually, stack behind each other when multiple
These can include alerts, PMs, fly controls, etc

```
popupDetails = {
	title = [String],
	body = [String],
	soundId = [Integer],
	actions = [Table],
}
```
]]

MessageService.popupProperties = {
	soundEnabled = true,
	promptSoundId = 3140355872,
	alertSoundId = 3140355872,
	volume = 0.5,
	pitch = 1,
}

function MessageService.popup(player, popupDetails)
	MessageService.remotes.message:Fire(player, popupDetails)
end

function MessageService.popupPool(targetPoolName, packedPoolArgs, popupDetails)
	local playersArray = main.enum.TargetPool.getProperty(targetPoolName)(table.unpack(packedPoolArgs))
	for _, player in pairs(playersArray) do
		MessageService.popup(player, popupDetails)
	end
end



return MessageService