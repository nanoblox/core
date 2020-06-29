-- LOCAL
local starterGui = game:GetService("StarterGui")
local guiService = game:GetService("GuiService")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local IconController = {}
local Icon = require(script.Parent.Icon)
local topbarIcons = {}
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
local previousTopbarEnabled = checkTopbarEnabled()
local menuOpen



-- PROPERTIES
IconController.topbarEnabled = true



-- METHODS
function IconController:createIcon(name, imageId, order)
	
	-- Verify data
	assert(not topbarIcons[name], ("icon '%s' already exists!"):format(name))
	
	-- Create and record icon
	local icon = Icon.new(name, imageId, order)
	local iconDetails = {name = name, icon = icon, order = icon.order}
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
		assert(iconDetails, ("Failed to update Icon '%s': icon not found."):format(name))

		iconDetails.order = icon.order or 1
		local orderedIconDetails = {}
		local rightOrderedIconDetails = {}
		for name, details in pairs(topbarIcons) do
			if details.icon.enabled == true then
				if details.icon.rightSide then
					table.insert(rightOrderedIconDetails, details)
				else
					table.insert(orderedIconDetails, details)
				end
			end
		end		
		if #orderedIconDetails > 1 then
			table.sort(orderedIconDetails, function(a,b) return a.order < b.order end)
		end
		if #rightOrderedIconDetails > 1 then
			table.sort(rightOrderedIconDetails, function(a,b) return a.order < b.order end)
		end
		local leftStartPosition, rightStartPosition = 104, -90
		local positionIncrement = 44
		if not starterGui:GetCoreGuiEnabled("Chat") then
			leftStartPosition = leftStartPosition - positionIncrement
		end
		if not starterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList) and not starterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack) and not starterGui:GetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu) then
			rightStartPosition = rightStartPosition + positionIncrement
		end
		for i, details in pairs(orderedIconDetails) do
			local container = details.icon.objects.container
			local iconX = leftStartPosition + (i-1)*positionIncrement
			container.Position = UDim2.new(0, iconX, 0, 4)
		end
		for i, details in pairs(rightOrderedIconDetails) do
			local container = details.icon.objects.container
			local iconX = rightStartPosition - (i-1)*positionIncrement
			container.Position = UDim2.new(1, iconX, 0, 4)
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
		icon._fakeChatConnections:give(userInputService.InputEnded:connect(function(inputObject, gameProcessedEvent)
			if gameProcessedEvent then
				return "Another menu has priority"
			elseif not(inputObject.KeyCode == Enum.KeyCode.Slash or inputObject.KeyCode == Enum.SpecialKey.ChatHotkey) then
				return "No relavent key pressed"
			elseif ChatMain.IsFocused() then
				return "Chat bar already open"
			elseif not icon.enabled then
				return "Icon disabled"
			end
			ChatMain:FocusChatBar(true)
			icon:select()
		end))
		-- ChatActive
		icon._fakeChatConnections:give(ChatMain.VisibilityStateChanged:connect(function(visibility)
			if not icon.ignoreVisibilityStateChange then
				if visibility == true then
					icon:select()
				else
					icon:deselect()
				end
			end
		end))
		-- Keep when other icons selected
		icon.deselectWhenOtherIconSelected = false
		-- Mimic chat notifications
		icon._fakeChatConnections:give(ChatMain.MessagesChanged:connect(function(messageCount)
			if ChatMain:GetVisibility() == true then
				return "ChatWindow was open"
			end
			icon:notify(icon.selected)
		end))
		-- Mimic visibility when StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, state) is called
		icon._fakeChatConnections:give(ChatMain.CoreGuiEnabled:connect(function(newState)
			if icon.ignoreVisibilityStateChange then
				return "ignoreVisibilityStateChange enabled"
			end
			local topbarEnabled = checkTopbarEnabled()
			if topbarEnabled ~= previousTopbarEnabled then
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
	icon._fakeChatConnections:clean()
	starterGui:SetCoreGuiEnabled("Chat", enabled)
	IconController:removeIcon(fakeChatName)
end

function IconController:setTopbarEnabled(newState)
	local topbarPlusGui = getTopbarPlusGui()
	local topbarContainer = topbarPlusGui.TopbarContainer
	if menuOpen then
		topbarContainer.Visible = false
	else
		topbarContainer.Visible = newState
	end
	IconController.topbarEnabled = newState
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
	assert(iconDetails, ("icon '%s' not found!"):format(name))
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
		local topbarEnabled = checkTopbarEnabled()
		if topbarEnabled == previousTopbarEnabled then
			return "SetCoreGuiEnabled was called instead of SetCore"
		end
		previousTopbarEnabled = topbarEnabled
		IconController:setTopbarEnabled(topbarEnabled)
		local icons = IconController:getAllIcons()
		for _, icon in pairs(icons) do
			icon.updated:Fire()
		end
	end)
	IconController:setTopbarEnabled(checkTopbarEnabled())
	-- Display topbar icons when the Roblox menu is opened/closed
	guiService.MenuClosed:Connect(function()
		menuOpen = false
		IconController:setTopbarEnabled(IconController.topbarEnabled)
	end)
	guiService.MenuOpened:Connect(function()
		menuOpen = true
		IconController:setTopbarEnabled(IconController.topbarEnabled)
	end)
end)()



return IconController