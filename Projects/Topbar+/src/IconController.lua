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
	local success, bool = xpcall(function()
		return starterGui:GetCore("TopbarEnabled")
	end,function(err)
		--has not been registered yet, but default is that is enabled
		return true	
	end)
	return (success and bool)
end
local forceTopbarDisabled = false
local previousTopbarEnabled = checkTopbarEnabled()
local menuOpen
local topbarUpdating = false
local robloxStupidOffset = 32



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

local function getScaleMultiplier()
	if isConsoleMode() then
		return 3
	else
		return 1.3
	end
end

local function updateIconSize(icon, controllerEnabled)
	if not controllerEnabled then
		local currentSize, originalSize = icon:get("iconSize", nil, "original")
		icon:set("iconSize", originalSize)
		return
	end
	local currentSize, originalSize = icon:get("iconSize", nil, "original")
	local newOriginalSize = originalSize or currentSize
	local scaleMultiplier = getScaleMultiplier()
	local finalSize = UDim2.new(0, newOriginalSize.X.Offset*scaleMultiplier, 0, newOriginalSize.Y.Offset*scaleMultiplier)
	icon:set("iconSize", finalSize)
end

function IconController.createIcon(name, order, imageId, labelText)
	
	-- Verify data
	assert(not topbarIcons[name], ("icon '%s' already exists!"):format(name))
	
	-- Create and record icon
	local icon = Icon.new(name, order, imageId, labelText)
	topbarIcons[name] = icon
	
	-- Apply game theme if found
	local gameTheme = IconController.gameTheme
	if gameTheme then
		icon:setTheme(gameTheme)
	end
	
	-- Events
	local gap = 12
	local function getIncrement(otherIcon)
		--local container = otherIcon.instances.iconContainer
		--local sizeX = container.Size.X.Offset
		local sizeX = otherIcon:get("iconSize").X.Offset
		local increment = (sizeX + gap)
		return increment
	end
	local function updateIcon()
		assert(icon, ("Failed to update Icon '%s': icon not found."):format(name))
		
		if topbarUpdating then -- This prevents the topbar updating and shifting icons more than it needs to
			return false
		end
		topbarUpdating = true
		runService.Heartbeat:Wait()
		topbarUpdating = false
		
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
				records = {}
			},
			mid = {
				startScale = 0.5,
				getStartOffset = function(totalIconX) 
					return -totalIconX/2 + (gap/2)
				end,
				records = {}
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
				records = {}
				--reverseSort = true
			},
		}
		for _, otherIcon in pairs(topbarIcons) do
			if otherIcon.enabled == true then
				table.insert(alignmentDetails[otherIcon:get("alignment")].records, otherIcon)
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
			for i, otherIcon in pairs(records) do
				local increment = getIncrement(otherIcon)
				totalIconX = totalIconX + increment
			end
			local offsetX = alignmentInfo.getStartOffset(totalIconX)
			for i, otherIcon in pairs(records) do
				local container = otherIcon.instances.iconContainer
				local increment = getIncrement(otherIcon)
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
		local allIcons = IconController.getIcons()
		for _, otherIcon in pairs(allIcons) do
			if icon.deselectWhenOtherIconSelected and otherIcon ~= icon and otherIcon.deselectWhenOtherIconSelected and otherIcon:getToggleState() == "selected" then
				otherIcon:deselect()
			end
		end
	end)
	
	if isControllerMode() then
		updateIconSize(icon, true)
		icon:setMid()
	end
	
	return icon
end

function IconController.createIconBySettings(dictionaryOfSettings)
	local icon = IconController.createIcon()
	for settingName, settingValue in pairs(dictionaryOfSettings) do
		icon:set(settingName, settingValue)
	end
	return icon
end

function IconController.setTopbarEnabled(bool, forceBool)
	if forceBool == nil then
		forceBool = true
	end
	local topbar = getTopbarPlusGui()
	if not topbar then return end
	local indicator = topbar.Indicator
	if forceBool and not bool then
		forceTopbarDisabled = true
	elseif forceBool and bool then
		forceTopbarDisabled = false
	end
	if isControllerMode() then
		if bool then
			if topbar.TopbarContainer.Visible or forceTopbarDisabled or menuOpen or not checkTopbarEnabled() then return end
			if forceBool then
				indicator.Visible = checkTopbarEnabled()
			else
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
					UDim2.new(0,0,0,5 + robloxStupidOffset),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.1,
					true
				)
				guiService:AddSelectionParent("TopbarPlus",topbar.TopbarContainer)
				guiService.CoreGuiNavigationEnabled = false
				guiService.GuiNavigationEnabled = true
				
				local selectIcon
				local targetOffset = 0
				runService.Heartbeat:Wait()
				local indicatorSizeTrip = 50 --indicator.AbsoluteSize.Y * 2
				for name, otherIcon in pairs(topbarIcons) do
					local container = otherIcon.instances.iconContainer
					if container.Visible then
						if not selectIcon or otherIcon:get("order") > selectIcon:get("order") then
							selectIcon = otherIcon
						end
					end
					local newTargetOffset = -27 + container.AbsoluteSize.Y + indicatorSizeTrip
					if newTargetOffset > targetOffset then
						targetOffset = newTargetOffset
					end
				end
				if guiService:GetEmotesMenuOpen() then
					guiService:SetEmotesMenuOpen(false)
				end
				if guiService:GetInspectMenuEnabled() then
					guiService:CloseInspectMenu()
				end
				delay(0.15,function()
					guiService.SelectedObject = selectIcon.instances.iconContainer
				end)
				indicator.Image = "rbxassetid://5278151071"
				indicator:TweenPosition(
					UDim2.new(0.5,0,0,targetOffset + robloxStupidOffset),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.1,
					true
				)
			end
		else
			if forceBool then
				indicator.Visible = false
			else
				indicator.Visible = checkTopbarEnabled()
			end
			if not topbar.TopbarContainer.Visible then return end
			guiService.AutoSelectGuiEnabled = true
			guiService:RemoveSelectionGroup("TopbarPlus")
			topbar.TopbarContainer:TweenPosition(
				UDim2.new(0,0,0,-topbar.TopbarContainer.Size.Y.Offset + robloxStupidOffset),
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
		if checkTopbarEnabled() then
			topbarContainer.Visible = bool
		else
			topbarContainer.Visible = false
		end
	end
end

function IconController.enableControllerMode(bool)
	local topbar = getTopbarPlusGui()
	if not topbar then return end
	local indicator = topbar.Indicator
	local controllerOptionIcon = IconController.getIcon("_TopbarControllerOption")
	if bool then
		topbar.TopbarContainer.Position = UDim2.new(0,0,0,5)
		topbar.TopbarContainer.Visible = false
		local scaleMultiplier = getScaleMultiplier()
		indicator.Position = UDim2.new(0.5,0,0,5)
		indicator.Size = UDim2.new(0, 18*scaleMultiplier, 0, 18*scaleMultiplier)
		indicator.Image = "rbxassetid://5278151556"
		indicator.Visible = checkTopbarEnabled()
		local isConsole = isConsoleMode()
		indicator.Position = UDim2.new(0.5,0,0,5)
		for name, otherIcon in pairs(topbarIcons) do
			updateIconSize(otherIcon, true)
			otherIcon:setMid()
		end
		if controllerOptionIcon then
			if not userInputService.MouseEnabled then
				controllerOptionIcon:setEnabled(false)
			else
				controllerOptionIcon:setEnabled(true)
			end
		end
	else
		if userInputService.GamepadEnabled and controllerOptionIcon then
			--mouse user but might want to use controller
			controllerOptionIcon:setEnabled(true)
		elseif controllerOptionIcon then
			controllerOptionIcon:setEnabled(false)
		end
		local isConsole = isConsoleMode()
		for name, otherIcon in pairs(topbarIcons) do
			updateIconSize(otherIcon, false)
			local previousAlignment = otherIcon:get("alignment", nil, "previous")
			if previousAlignment then
				otherIcon:set("alignment", previousAlignment)
			end
		end
		topbar.TopbarContainer.Position = UDim2.new(0,0,0,0)
		topbar.TopbarContainer.Visible = checkTopbarEnabled()
		indicator.Visible = false
	end
end

function updateDevice()
	if isControllerMode() then
		for _, icon in pairs(topbarIcons) do
			icon._isControllerMode = true
		end
		IconController.enableControllerMode(true)
		return
	end
	for _,icon in pairs(topbarIcons) do
		icon._isControllerMode = false
	end
	IconController.enableControllerMode()
end

function IconController.createFakeChat()
	local chatMainModule = getChatMain()
	local ChatMain = require(chatMainModule)
	local iconName = fakeChatName
	local icon = IconController.getIcon(iconName)
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
		icon = IconController.createIcon(iconName, -1, "rbxasset://textures/ui/TopBar/chatOff.png")
		-- Open chat via Slash key
		icon._fakeChatMaid:give(userInputService.InputEnded:connect(function(inputObject, gameProcessedEvent)
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
		icon._fakeChatMaid:give(ChatMain.VisibilityStateChanged:connect(function(visibility)
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
		icon._fakeChatMaid:give(ChatMain.MessagesChanged:connect(function()
			if ChatMain:GetVisibility() == true then
				return "ChatWindow was open"
			end
			icon:notify(icon.selected)
		end))
		-- Mimic visibility when StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, state) is called
		coroutine.wrap(function()
			runService.Heartbeat:Wait()
			icon._fakeChatMaid:give(ChatMain.CoreGuiEnabled:connect(function(newState)
				if icon.ignoreVisibilityStateChange then
					return "ignoreVisibilityStateChange enabled"
				end
				local topbarEnabled = checkTopbarEnabled()
				if topbarEnabled ~= previousTopbarEnabled then
					return "SetCore was called instead of SetCoreGuiEnabled"
				end
				if not icon.enabled and userInputService:IsKeyDown(Enum.KeyCode.LeftShift) and userInputService:IsKeyDown(Enum.KeyCode.P) then
					icon:setEnabled(true)
				else
					setIconEnabled(newState)
				end
			end))
		end)()
	end
	icon:setImage("rbxasset://textures/ui/TopBar/chatOn.png", "selected")
	icon:setImageSize(20)
	icon.deselected:Connect(function()
		displayChatBar(false)
	end)
	icon.selected:Connect(function()
		displayChatBar(true)
	end)
	setIconEnabled(starterGui:GetCoreGuiEnabled("Chat"))
	return icon
end

function IconController.removeFakeChat()
	local icon = IconController.getIcon(fakeChatName)
	local enabled = icon.enabled
	icon._fakeChatMaid:clean()
	starterGui:SetCoreGuiEnabled("Chat", enabled)
	IconController.removeIcon(fakeChatName)
end

function IconController.setGameTheme(theme)
	IconController.gameTheme = theme
	local icons = IconController.getIcons()
	for _, icon in pairs(icons) do
		icon:setTheme(theme)
	end
end

function IconController.setDisplayOrder(value)
	local topbarPlusGui = getTopbarPlusGui()
	value = tonumber(value) or topbarPlusGui.DisplayOrder
	topbarPlusGui.DisplayOrder = value
end

function IconController.getIcon(name)
	local icon = topbarIcons[name]
	if not icon then
		return false
	end
	return icon
end

function IconController.getIcons()
	local allIcons = {}
	for _, otherIcon in pairs(topbarIcons) do
		table.insert(allIcons, otherIcon)
	end
	return allIcons
end

function IconController.removeIcon(name)
	local icon = topbarIcons[name]
	assert(icon, ("icon '%s' not found!"):format(name))
	icon:setEnabled(false)
	icon:deselect()
	icon.updated:Fire()
	icon:destroy()
	topbarIcons[name] = nil
	return true
end



-- BEHAVIOUR
local function updateTopbar()
	local icons = IconController.getIcons()
	for i, icon in pairs(icons) do
		if i == 1 then
			icon.updated:Fire()
			break
		end
	end
end
coroutine.wrap(function()
	-- Mimic the enabling of the topbar when StarterGui:SetCore("TopbarEnabled", state) is called
	local ChatMain = require(getChatMain())
	ChatMain.CoreGuiEnabled:connect(function()
		local topbarEnabled = checkTopbarEnabled()
		if topbarEnabled == previousTopbarEnabled then
			updateTopbar()
			return "SetCoreGuiEnabled was called instead of SetCore"
		end
		previousTopbarEnabled = topbarEnabled
		if isControllerMode() then
			IconController.setTopbarEnabled(false,false)
		else
			IconController.setTopbarEnabled(topbarEnabled,false)
		end
		updateTopbar()
	end)
	IconController.setTopbarEnabled(checkTopbarEnabled(),false)
end)()

guiService.MenuClosed:Connect(function()
	menuOpen = false
	if not isControllerMode() then
		IconController.setTopbarEnabled(IconController.topbarEnabled,false)
	end
end)
guiService.MenuOpened:Connect(function()
	menuOpen = true
	IconController.setTopbarEnabled(false,false)
end)

--Controller
updateDevice()
userInputService.GamepadConnected:Connect(updateDevice)
userInputService.GamepadDisconnected:Connect(updateDevice)
userInputService:GetPropertyChangedSignal("MouseEnabled"):Connect(updateDevice)
userInputService.InputBegan:Connect(function(input,gpe)
	local topbar = getTopbarPlusGui()
	if not topbar then return end
	if not isControllerMode() then return end
	if input.KeyCode == Enum.KeyCode.DPadDown then
		if not guiService.SelectedObject and checkTopbarEnabled() then
			IconController.setTopbarEnabled(true,false)
		end
	elseif input.KeyCode == Enum.KeyCode.ButtonB then
		IconController.setTopbarEnabled(false,false)
	end
	input:Destroy()
end)

local controllerOptionIcon = IconController.createIcon("_TopbarControllerOption", 100, "rbxassetid://5278150942")
controllerOptionIcon:setRight()
controllerOptionIcon.deselectWhenOtherIconSelected = false
controllerOptionIcon:setEnabled(false)
controllerOptionIcon:setTip("Controller mode")
if not isControllerMode() and userInputService.GamepadEnabled then
	controllerOptionIcon:setEnabled(true)
end
controllerOptionIcon.selected:Connect(function()
	controllerOptionIcon:setTip("Normal mode")
	IconController.forceController = true
	updateDevice()
end)
controllerOptionIcon.deselected:Connect(function()
	controllerOptionIcon:setTip("Controller mode")
	IconController.forceController = false
	updateDevice()
end)
local topbar = getTopbarPlusGui()
topbar.Indicator.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		IconController.setTopbarEnabled(true,false)
	end
	input:Destroy()
end)

return IconController