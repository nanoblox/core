-- LOCAL
local starterGui = game:GetService("StarterGui")
local guiService = game:GetService("GuiService")
local hapticService = game:GetService("HapticService")
local runService = game:GetService("RunService")
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
	local playerGui = player:WaitForChild("PlayerGui")
	local topbarPlusGui = playerGui:WaitForChild("Topbar+")
	return topbarPlusGui
end
local function checkTopbarEnabled()
	return(starterGui:GetCore("TopbarEnabled"))
end
local previousTopbarEnabled = checkTopbarEnabled()
local menuOpen
local topbarUpdating = false



-- PROPERTIES
IconController.topbarEnabled = true
IconController.forceController = false

-- METHODS
local function isControllerMode()
	return (userInputService.GamepadEnabled and not userInputService.MouseEnabled) or (IconController.forceController and userInputService.GamepadEnabled)
end

local function isConsoleMode()
	return guiService:IsTenFootInterface()
end

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
	local gap = 12
	local function getIncrement(otherIcon)
		local container = otherIcon.objects.container
		local sizeX = container.Size.X.Offset
		local increment = (sizeX + gap)
		return increment
	end
	local function updateIcon()
		assert(iconDetails, ("Failed to update Icon '%s': icon not found."):format(name))

		if topbarUpdating then -- This prevents the topbar updating and shifting icons more than it needs to
			return false
		end
		topbarUpdating = true
		runService.Heartbeat:Wait()
		topbarUpdating = false
		
		iconDetails.order = icon.order or 1
		local defaultIncrement = 44
		local alignmentDetails = {
			left = {
				startScale = 0,
				getStartOffset = function() 
					local offset = 104
					if not starterGui:GetCoreGuiEnabled("Chat") then
						offset = offset - defaultIncrement
					end
					return offset
				end,
				records = {},
			},
			mid = {
				startScale = 0.5,
				getStartOffset = function(totalIconX) 
					return -totalIconX/2 + (gap/2)
				end,
				records = {},
			},
			right = {
				startScale = 1,
				getStartOffset = function(totalIconX) 
					local offset = -totalIconX
					if starterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList) or starterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack) or starterGui:GetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu) then
						offset = offset - defaultIncrement
					end
					return offset
				end,
				records = {},
				reverseSort = true,
			},
		}
		for _, details in pairs(topbarIcons) do
			if details.icon.enabled == true then
				table.insert(alignmentDetails[details.icon.alignment].records, details)
			end
		end
		for alignment, alignmentInfo in pairs(alignmentDetails) do
			local records = alignmentInfo.records
			if #records > 1 then
				if alignmentInfo.reverseSort then
					table.sort(records, function(a,b) return a.order > b.order end)
				else
					table.sort(records, function(a,b) return a.order < b.order end)
				end
			end
			local totalIconX = 0
			for i, details in pairs(records) do
				local increment = getIncrement(details.icon)
				totalIconX = totalIconX + increment
			end
			local offsetX = alignmentInfo.getStartOffset(totalIconX)
			for i, details in pairs(records) do
				local container = details.icon.objects.container
				local increment = getIncrement(details.icon)
				container.Position = UDim2.new(alignmentInfo.startScale, offsetX, 0, 4)
				offsetX = offsetX + increment
			end
		end
		return true
	end
	coroutine.wrap(function() updateIcon() end)()
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
	
	if isControllerMode() then
		if isConsoleMode() then
			icon:setCellSize(32*3)
		else
			icon:setCellSize(32*1.3)
		end
		icon._previousAlignment = icon.alignment
		icon:setMid()
	end

	return icon
end

function IconController:setTopbarEnabled(bool)
	local topbar = getTopbarPlusGui()
	if not topbar then return end
	local indicator = topbar.Indicator
	if isControllerMode() then
		indicator.Visible = checkTopbarEnabled()
		if bool then
			if topbar.TopbarContainer.Visible then return end
			if hapticService:IsVibrationSupported(Enum.UserInputType.Gamepad1) and hapticService:IsMotorSupported(Enum.UserInputType.Gamepad1,Enum.VibrationMotor.Small) then
				hapticService:SetMotor(Enum.UserInputType.Gamepad1,Enum.VibrationMotor.Small,1)
				delay(0.2,function()
					pcall(function()
						hapticService:SetMotor(Enum.UserInputType.Gamepad1,Enum.VibrationMotor.Small,0)
					end)
				end)
			end
			topbar.TopbarContainer.Visible = true
			topbar.TopbarContainer:TweenPosition(
				UDim2.new(0,0,0,5),
				Enum.EasingDirection.Out,
				Enum.EasingStyle.Quad,
				0.1,
				true
			)
			guiService:AddSelectionParent("TopbarPlus",topbar.TopbarContainer)
			guiService.CoreGuiNavigationEnabled = false
			guiService.GuiNavigationEnabled = true
			
			local selectObject
			for name,details in pairs(topbarIcons) do
				if details.icon.objects.container.Visible then
					if not selectObject or details.order > selectObject.order then
						selectObject = details
					end
				end
			end
			if guiService:GetEmotesMenuOpen() then
				guiService:SetEmotesMenuOpen(false)
			end
			if guiService:GetInspectMenuEnabled() then
				guiService:CloseInspectMenu()
			end
			delay(0.15,function()
				guiService.SelectedObject = selectObject.icon.objects.container
			end)
			indicator.Image = "rbxassetid://5278151071"
			indicator:TweenPosition(
				UDim2.new(0.5,0,0,topbar.TopbarContainer.Size.Y.Offset+20),
				Enum.EasingDirection.Out,
				Enum.EasingStyle.Quad,
				0.1,
				true
			)
		else
			if not topbar.TopbarContainer.Visible then return end
			guiService.AutoSelectGuiEnabled = true
			guiService:RemoveSelectionGroup("TopbarPlus")
			topbar.TopbarContainer:TweenPosition(
				UDim2.new(0,0,0,-topbar.TopbarContainer.Size.Y.Offset),
				Enum.EasingDirection.Out,
				Enum.EasingStyle.Quad,
				0.1,
				true,
				function()
					topbar.TopbarContainer.Visible = false
				end
			)
			indicator.Image = "rbxassetid://5278151556"
			indicator:TweenPosition(
				UDim2.new(0.5,0,0,5),
				Enum.EasingDirection.Out,
				Enum.EasingStyle.Quad,
				0.1,
				true
			)
		end
	else
		local topbarContainer = topbar.TopbarContainer
		if menuOpen then
			topbarContainer.Visible = false
		else
			topbarContainer.Visible = bool
		end
		IconController.topbarEnabled = bool
	end
end

function IconController:enableControllerMode(bool)
	local topbar = getTopbarPlusGui()
	if not topbar then return end
	local indicator = topbar.Indicator
	local controllerOptionIcon = IconController:getIcon("_TopbarControllerOption")
	local expandIconScale = {
		console = 3,
		other = 1.3,
	}
	if bool then
		topbar.TopbarContainer.Position = UDim2.new(0,0,0,5)
		topbar.TopbarContainer.Visible = false
		indicator.Position = UDim2.new(0.5,0,0,5)
		indicator.Image = "rbxassetid://5278151556"
		indicator.Visible = checkTopbarEnabled()
		local isConsole = isConsoleMode()
		for name,details in pairs(topbarIcons) do
			local icon = details.icon
			if isConsole then
				details.icon:setCellSize(icon.cellSize*expandIconScale.console)
			else
				details.icon:setCellSize(icon.cellSize*expandIconScale.other)
			end
			details.icon._previousAlignment = details.icon.alignment
			details.icon:setMid()
		end
		if controllerOptionIcon and not userInputService.MouseEnabled then
			controllerOptionIcon:setEnabled(false)
		end
	else
		if userInputService.GamepadEnabled and controllerOptionIcon then
			--mouse user but might want to use controller
			controllerOptionIcon:setEnabled(true)
		elseif controllerOptionIcon then
			controllerOptionIcon:setEnabled(false)
		end
		local isConsole = isConsoleMode()
		for name,details in pairs(topbarIcons) do
			local icon = details.icon
			if isConsole then
				details.icon:setCellSize(icon.cellSize/expandIconScale.console)
			else
				details.icon:setCellSize(icon.cellSize/expandIconScale.other)
			end
			if details.icon._previousAlignment then
				details.icon.alignment = details.icon._previousAlignment
				details.icon.updated:Fire()
			end
		end
		topbar.TopbarContainer.Position = UDim2.new(0,0,0,0)
		topbar.TopbarContainer.Visible = checkTopbarEnabled()
		indicator.Visible = false
	end
end

function updateDevice()
	if isControllerMode() then
		IconController:enableControllerMode(true)
		return
	end
	IconController:enableControllerMode()
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
		icon._fakeChatConnections:give(ChatMain.MessagesChanged:connect(function()
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

function IconController:setGameTheme(theme)
	self.gameTheme = theme
	local icons = self:getAllIcons()
	for _, icon in pairs(icons) do
	    icon:setTheme(theme)
	end
end

function IconController:setDisplayOrder(value)
	local topbarPlusGui = getTopbarPlusGui()
	value = tonumber(value) or topbarPlusGui.DisplayOrder
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
	for _, details in pairs(topbarIcons) do
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
	ChatMain.CoreGuiEnabled:connect(function()
		local topbarEnabled = checkTopbarEnabled()
		if topbarEnabled == previousTopbarEnabled then
			return "SetCoreGuiEnabled was called instead of SetCore"
		end
		previousTopbarEnabled = topbarEnabled
		if isControllerMode() then
			IconController:setTopbarEnabled(false)
		else
			IconController:setTopbarEnabled(topbarEnabled)
		end
		local icons = IconController:getAllIcons()
		for _, icon in pairs(icons) do
			icon.updated:Fire()
		end
	end)
	IconController:setTopbarEnabled(checkTopbarEnabled())
	-- Display topbar icons when the Roblox menu is opened/closed
	guiService.MenuClosed:Connect(function()
		menuOpen = false
		if not isControllerMode() then
			IconController:setTopbarEnabled(IconController.topbarEnabled)
		end
	end)
	guiService.MenuOpened:Connect(function()
		menuOpen = true
		if isControllerMode() then
			IconController:setTopbarEnabled(false)
		else
			IconController:setTopbarEnabled(IconController.topbarEnabled)
		end
	end)
end)()

--Controller
updateDevice()
userInputService.GamepadConnected:Connect(updateDevice)
userInputService.GamepadDisconnected:Connect(updateDevice)
userInputService:GetPropertyChangedSignal("MouseEnabled"):Connect(updateDevice)
userInputService.InputBegan:Connect(function(input,gpe)
	local topbar = getTopbarPlusGui()
	if not topbar then return end
	if input.KeyCode == Enum.KeyCode.DPadDown then
		if not guiService.SelectedObject and checkTopbarEnabled() then
			IconController:setTopbarEnabled(true)
		end
	elseif input.KeyCode == Enum.KeyCode.ButtonB then
		IconController:setTopbarEnabled(false)
	end
	input:Destroy()
end)

local controllerOptionIcon = IconController:createIcon("_TopbarControllerOption","rbxassetid://5278150942",-99)
controllerOptionIcon:setRight()
controllerOptionIcon.deselectWhenOtherIconSelected = false
controllerOptionIcon:setEnabled(false)
if not isControllerMode() and userInputService.GamepadEnabled then
	controllerOptionIcon:setEnabled(true)
end
controllerOptionIcon.selected:Connect(function()
	IconController.forceController = true
	updateDevice()
end)
controllerOptionIcon.deselected:Connect(function()
	IconController.forceController = false
	updateDevice()
end)

return IconController
