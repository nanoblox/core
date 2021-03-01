-- LOCAL
local main = require(game.Nanoblox)
local MessageService = {
	remotes = {
		message = main.modules.Remote.new("message"),
		hint = main.modules.Remote.new("hint"),
		notice = main.modules.Remote.new("notice"),
		popup = main.modules.Remote.new("popup"),
	},
}



--[[ MESSAGES
Silent, cover the entire screen, fade dark, disappear after read duration, cannot be hidden/closed, appear consecutively when multiple

```
messageDetails = {
	title = [String],
	subtitle = [String],
	body0 = [String],
	icon = [ImageId],
	titleColor = [Color3],
	subtitleColor = [Color3],
	textColor = [Color3],
	backgroundColor = [Color3],
}
```
]]

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
	soundId = [Integer],
}
```
]]

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