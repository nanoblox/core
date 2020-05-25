-- LOCAL
local starterGui = game:GetService("StarterGui")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local IconController = {}
local Icon = require(script.Parent.Icon)
local topbarIcons = {}
local errorStart = "Topbar+ | "
local fakeChatName = "_FakeChat"
local function deepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            v = deepCopy(v)
        end
        copy[k] = v
    end
    return copy
end
local function getChatMain()
	return players.LocalPlayer.PlayerScripts:WaitForChild("ChatScript").ChatMain
end
local function getTopbarPlusGui()
	local player = game:GetService("Players").LocalPlayer
	local playerGui = player.PlayerGui
	local topbarPlusGui = playerGui:WaitForChild("Topbar+")
	return topbarPlusGui
end
local function checkTopbarEnabled()
	return(starterGui:GetCore("TopbarEnabled"))
end



-- METHODS
function IconController:createIcon(name, imageId, order)
	
	-- Verify data
	local iconDetails = topbarIcons[name]
	if iconDetails then
		warn(("%sFailed to create Icon '%s': an icon already exists under that name."):format(errorStart, name))
		return false
	end
	
	-- Create and record icon
	local icon = Icon.new(name, imageId, order)
	iconDetails = {name = name, icon = icon, order = icon.order}
	topbarIcons[name] = iconDetails
	icon:setOrder(icon.order)
	
	-- Apply game theme if found
	local gameTheme = self.gameTheme
	if gameTheme then
		icon:setTheme(gameTheme)
	end
	
	-- Events
	local function updateIcon()
		local iconDetails = topbarIcons[name]
		if not iconDetails then
			warn(("%sFailed to update Icon '%s': icon not found."):format(errorStart, name))
			return false
		end
		iconDetails.order = icon.order or 1
		local orderedIconDetails = {}
		for name, details in pairs(topbarIcons) do
			if details.icon.enabled == true then
				table.insert(orderedIconDetails, details)
			end
		end
		if #orderedIconDetails > 1 then
			table.sort(orderedIconDetails, function(a,b) return a.order < b.order end)
		end
		local startPosition = 104
		local positionIncrement = 44
		if not starterGui:GetCoreGuiEnabled("Chat") then
			startPosition = startPosition - positionIncrement
		end
		for i, details in pairs(orderedIconDetails) do
			local container = details.icon.objects.container
			local iconX = startPosition + (i-1)*positionIncrement
			container.Position = UDim2.new(0, iconX, 0, 4)
		end
		return true
	end
	updateIcon()
	icon.updated:Connect(function()
		updateIcon()
	end)
	icon.selected:Connect(function()
		local allIcons = self:getAllIcons()
		for _, otherIcon in pairs(allIcons) do
			if icon.deselectWhenOtherIconSelected and otherIcon ~= icon and otherIcon.deselectWhenOtherIconSelected and otherIcon.toggleStatus == "selected" then
				otherIcon:deselect()
			end
		end
	end)
	
	return icon
end

function IconController:createFakeChat(theme)
	local chatMainModule = getChatMain()
	local ChatMain = require(chatMainModule)
	local iconName = fakeChatName
	local icon = self:getIcon(iconName)
	local function displayChatBar(visibility)
		icon.ignoreVisibilityStateChange = true
		ChatMain.CoreGuiEnabled:fire(visibility)
		ChatMain.IsCoreGuiEnabled = false
		ChatMain:SetVisible(visibility)
		icon.ignoreVisibilityStateChange = nil
	end
	local function setIconEnabled(visibility)
		icon.ignoreVisibilityStateChange = true
		ChatMain.CoreGuiEnabled:fire(visibility)
		icon:setEnabled(visibility)
		starterGui:SetCoreGuiEnabled("Chat", false)
		icon:deselect()
		icon.updated:Fire()
		icon.ignoreVisibilityStateChange = nil
	end
	if not icon then
		icon = self:createIcon(iconName, "rbxasset://textures/ui/TopBar/chatOff.png", -1)
		-- Open chat via Slash key
		icon._fakeChatConnections:add(userInputService.InputEnded:connect(function(inputObject, gameProcessedEvent)
			if gameProcessedEvent then
				return "Another menu has priority"
			elseif not(inputObject.KeyCode == Enum.KeyCode.Slash or inputObject.KeyCode == Enum.SpecialKey.ChatHotkey) then
				return "No relavent key pressed"
			elseif ChatMain.IsFocused() then
				return "Chat bar already open"
			end--]]
			ChatMain:SpecialKeyPressed(inputObject.KeyCode)
			ChatMain:FocusChatBar(true)
			icon:select()
		end))
		-- Keep when other icons selected
		icon.deselectWhenOtherIconSelected = false
		-- Mimic chat notifications
		icon._fakeChatConnections:add(ChatMain.MessagesChanged:connect(function(messageCount)
			if ChatMain:GetVisibility() == true then
				return "ChatWindow was open"
			end
			icon:notify(icon.selected)
		end))
		-- Mimic visibility when StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, state) is called
		local previousTopbarEnabled = checkTopbarEnabled()
		icon._fakeChatConnections:add(ChatMain.CoreGuiEnabled:connect(function(newState)
			if icon.ignoreVisibilityStateChange then
				return "ignoreVisibilityStateChange enabled"
			end
			local topbarEnabled = checkTopbarEnabled()
			if topbarEnabled ~= previousTopbarEnabled then
				previousTopbarEnabled = topbarEnabled
				return "SetCore was called instead of SetCoreGuiEnabled"
			end
			setIconEnabled(newState)
		end))
	end
	theme = (theme and deepCopy(theme)) or {}
	theme.image = theme.image or {}
	theme.image.selected = theme.image.selected or {}
	theme.image.selected.Image = "rbxasset://textures/ui/TopBar/chatOn.png"
	icon:setTheme(theme)
	icon:setImageSize(20)
	icon:setToggleFunction(function()
		local isSelected = icon.toggleStatus == "selected"
		displayChatBar(isSelected)
	end)
	setIconEnabled(starterGui:GetCoreGuiEnabled("Chat"))
	return icon
end

function IconController:removeFakeChat()
	local icon = IconController:getIcon(fakeChatName)
	local enabled = icon.enabled
	icon._fakeChatConnections:doCleaning()
	IconController:removeIcon(fakeChatName)
	starterGui:SetCoreGuiEnabled("Chat", enabled)
end

function IconController:setTopbarEnabled(newState)
	local topbarPlusGui = getTopbarPlusGui()
	local topbarContainer = topbarPlusGui.TopbarContainer
	topbarContainer.Visible = newState
end

function IconController:setGameTheme(theme)
	self.gameTheme = theme
	local icons = self:getAllIcons()
	for _, icon in pairs(icons) do
	    icon:setTheme(theme)
	end
end

function IconController:setDisplayOrder(value)
	local topbarPlusGui = getTopbarPlusGui()
	local value = tonumber(value) or topbarPlusGui.DisplayOrder
	topbarPlusGui.DisplayOrder = value
end

function IconController:getIcon(name)
	local iconDetails = topbarIcons[name]
	if not iconDetails then
		--warn(("%sFailed to get Icon '%s': icon not found."):format(errorStart, name))
		return false
	end
	return iconDetails.icon
end

function IconController:getAllIcons()
	local allIcons = {}
	for name, details in pairs(topbarIcons) do
		table.insert(allIcons, details.icon)
	end
	return allIcons
end

function IconController:removeIcon(name)
	local iconDetails = topbarIcons[name]
	if not iconDetails then
		warn(("%sFailed to remove Icon '%s': icon not found."):format(errorStart, name))
		return false
	end
	local icon = iconDetails.icon
	icon:setEnabled(false)
	icon:deselect()
	icon.updated:Fire()
	icon:destroy()
	topbarIcons[name] = nil
	return true
end



-- BEHAVIOUR
coroutine.wrap(function()
	-- Mimic the enabling of the topbar when StarterGui:SetCore("TopbarEnabled", state) is called
	local ChatMain = require(getChatMain())
	ChatMain.CoreGuiEnabled:connect(function(newState)
		--print("TOPBAR CHANGED!")
		local enabled = checkTopbarEnabled()
		IconController:setTopbarEnabled(enabled)
		local icons = IconController:getAllIcons()
		for _, icon in pairs(icons) do
			--print("Updated: ", icon.name)
			icon.updated:Fire()
		end
	end)
	IconController:setTopbarEnabled(checkTopbarEnabled())
end)()



return IconController