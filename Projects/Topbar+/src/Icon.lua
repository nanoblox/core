-- LOCAL
local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local debris = game:GetService("Debris")
local userInputService = game:GetService("UserInputService")
local textService = game:GetService("TextService")
local guiService = game:GetService("GuiService")
local player = game:GetService("Players").LocalPlayer
local playerGui = player.PlayerGui
local topbarPlusGui = playerGui:WaitForChild("Topbar+")
local topbarContainer = topbarPlusGui.TopbarContainer
local iconTemplate = topbarContainer["_IconTemplate"]
local HDAdmin = replicatedStorage:WaitForChild("HDAdmin")
local Signal = require(HDAdmin:WaitForChild("Signal"))
local Maid = require(HDAdmin:WaitForChild("Maid"))
local Icon = {}
Icon.__index = Icon



-- CONSTRUCTOR
function Icon.new(name, imageId, order)
	local self = {}
	setmetatable(self, Icon)
	
	local container = iconTemplate:Clone()
	container.Name = name
	container.Visible = true
	local button = container.IconButton
	
	self.objects = {
		["container"] = container,
		["button"] = button,
		["image"] = button.IconImage,
		["notification"] = button.Notification,
		["amount"] = button.Notification.Amount,
		["gradient"] = button.UIGradient
	}
	
	self.theme = {
		-- TOGGLE EFFECT
		["toggleTweenInfo"] = TweenInfo.new(0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		
		-- OBJECT PROPERTIES
		["container"] = {
			selected = {},
			deselected = {}
		},
		["button"] = {
			selected = {
				ImageColor3 = Color3.fromRGB(245, 245, 245),
				ImageTransparency = 0.1
			},
			deselected = {
				ImageColor3 = Color3.fromRGB(0, 0, 0),
				ImageTransparency = 0.5
			}
		},
		["image"] = {
			selected = {
				ImageColor3 = Color3.fromRGB(57, 60, 65),
			},
			deselected = {
				ImageColor3 = Color3.fromRGB(255, 255, 255),
			}
		},
		["notification"] = {
			selected = {},
			deselected = {},
		},
		["amount"] = {
			selected = {},
			deselected = {},
		},
		["gradient"] = {
			selected = {},
			deselected = {},
		}
	}
	self.toggleStatus = "deselected"
	self:applyThemeToAllObjects()
	
	local maid = Maid.new()
	self._maid = maid
	self._fakeChatConnections = Maid.new()
	self.updated = maid:give(Signal.new())
	self.selected = maid:give(Signal.new())
	self.deselected = maid:give(Signal.new())
	self.endNotifications = maid:give(Signal.new())
	maid:give(container)
	
	self.name = name
	self.tip = ""
	self.imageId = imageId or 0
	self:setImageSize(20)
	self:setCellSize(32)
	self.order = order or 1
	self.enabled = true
	self.alignment = "left"
	self.totalNotifications = 0
	self.toggleFunction = function() end
	self.hoverFunction = function() end
	self.deselectWhenOtherIconSelected = true
	
	--[[
	local hoverInputs = {"InputBegan", "InputEnded"}
	local originalTransparency = button.ImageTransparency
	self:setHoverFunction(function(inputName)
		local hovering = inputName == "InputBegan"
		button.ImageTransparency = (hovering and originalTransparency + 0.2) or (self.theme.button.selected.ImageTransparency or originalTransparency)
	end)
	for _, inputName in pairs(hoverInputs) do
		button[inputName]:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				self.hoverFunction(inputName)
			end
		end)
	end
	--]]
	self.maxTouchTime = 0.5
	self._isControllerMode = false
	
	if userInputService.MouseEnabled or userInputService.GamepadEnabled then
		button.MouseButton1Down:Connect(function()
			if self.toggleStatus == "selected" then
				self:deselect()
			else
				if not self._isControllerMode then
					topbarPlusGui.ToolTip.Visible = false
				end
				self:select()
			end
		end)
	elseif userInputService.TouchEnabled then
		local inputs = {}
		button.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				local tTime = tick()
				table.insert(inputs,tTime)
				delay(self.maxTouchTime,function()
					local index = table.find(inputs,tTime)
					if index then
						table.remove(inputs,index)
					end
				end)
			end
		end)
		button.InputEnded:Connect(function(input)
			local check = false
			local currentTime = tick()
			for i,v in pairs(inputs) do
				if currentTime-v < self.maxTouchTime then
					check = true
					break
				end
			end
			if check then
				if self.toggleStatus == "selected" then
					self:deselect()
				else
					self:select()
				end
			end
			input:Destroy()
		end)
	end
	
	if imageId then
		self:setImage(imageId)
	end
	
	self._hoverFunctions = {
		enter = function(x,y)
			if self.toggleStatus == "deselected" and self.tip and self.tip ~= "" then
				showToolTip(self.tip,Vector2.new(x,y),self._isControllerMode)
				xpcall(function()
					self.hoverFunction(true)
				end,function(err)
					warn("Hover function error: "..err)
				end)
				if self._mouseHoverTrack and self._mouseHoverTrack.Connected then
					self._mouseHoverTrack:Disconnect()
					self._mouseHoverTrack = nil
				end
				if self._isControllerMode then
					local tempConnection
					tempConnection = guiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
						if tempConnection and tempConnection.Connected then
							tempConnection:Disconnect()
						end
						xpcall(function()
							self.hoverFunction(false)
						end,function(err)
							warn("Hover function error: "..err)
						end)
					end)
				else
					self._mouseHoverTrack = button.MouseMoved:Connect(setToolTipPosition)
				end
			else
				topbarPlusGui.ToolTip.Visible = false
			end
		end,
		leave = function(x,y)
			if self._mouseHoverTrack and self._mouseHoverTrack.Connected then
				self._mouseHoverTrack:Disconnect()
				self._mouseHoverTrack = nil
			end
			hideToolTip()
			xpcall(function()
				self.hoverFunction(true)
			end,function(err)
				warn("Hover function error: "..err)
			end)
		end,
	}
	
	maid:give(button.MouseEnter:Connect(self._hoverFunctions.enter))
	maid:give(button.MouseLeave:Connect(self._hoverFunctions.leave))
	maid:give(guiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
		if guiService.SelectedObject == self.objects.button then
			self._hoverFunctions.enter()
		end
	end))
	
	
	container.Parent = topbarContainer
	
	return self
end



-- METHODS
function setToolTipPosition(x,y)
	local tipContainer = topbarPlusGui.ToolTip
	
	local camera = workspace.CurrentCamera
	if camera then
		local viewportSize = camera.ViewportSize
		local posX = math.clamp(x,5,viewportSize.X-tipContainer.Size.X.Offset-53)
		local posY = math.clamp(y,tipContainer.Size.Y.Offset+5,viewportSize.Y)
		x = posX
		y = posY
	end
	
	tipContainer.Position = UDim2.new(0,x,0,y)
end

function showToolTip(tip,position,controllerMode)
	local tipContainer = topbarPlusGui.ToolTip
	local textSize = textService:GetTextSize(tip,12,Enum.Font.GothamSemibold,Vector2.new(1000,20-6))
	tipContainer.Size = UDim2.new(0,textSize.X+6,0,20)
	if not controllerMode then
		setToolTipPosition(position.X,position.Y)
	end
	tipContainer.TextLabel.Text = tip
	tipContainer.Visible = true
end

function hideToolTip()
	local tipContainer = topbarPlusGui.ToolTip
	tipContainer.Visible = false
end

function Icon:setTip(tip)
	if tip then
		assert(typeof(tip) == "string","Expected string, got "..typeof(tip))
		self.tip = tip
	else
		self.tip = ""
	end
end

function Icon:createDropdown(options)
	if self.dropdown then
		self:removeDropdown()
	end
	local DropdownModule = require(script.Parent:WaitForChild("Dropdown"))
	self.dropdown = self._maid:give(DropdownModule.new(self,options))
	return self.dropdown
end

function Icon:removeDropdown()
	if self.dropdown then
		self.dropdown:destroy()
		self.dropdown = nil
	end
end

function Icon:setImage(imageId)
	local textureId = (tonumber(imageId) and "http://www.roblox.com/asset/?id="..imageId) or imageId
	self.imageId = textureId
	self.objects.image.Image = textureId
	self.theme.image = self.theme.image or {}
	self.theme.image.selected = self.theme.image.selected or {}
	self.theme.image.selected.Image = textureId
end

function Icon:setOrder(order)
	self.order = tonumber(order) or 1
	self.updated:Fire()
end

function Icon:setLeft()
	self.alignment = "left"
	self.updated:Fire()
end

function Icon:setMid()
	self.alignment = "mid"
	self.updated:Fire()
end

function Icon:setRight()
	self.alignment = "right"
	self.updated:Fire()
end

function Icon:setImageSize(pixelsX, pixelsY)
	pixelsX = tonumber(pixelsX) or self.imageSize
	if not pixelsY then
		pixelsY = pixelsX
	end
	self.imageSize = Vector2.new(pixelsX, pixelsY)
	self.objects.image.Size = UDim2.new(0, pixelsX, 0, pixelsY)
end

function Icon:setCellSize(pixelsX)
	local originalPixelsX = self.cellSize
	pixelsX = tonumber(pixelsX) or self.cellSize
	if originalPixelsX then
		local differenceMultiplier = pixelsX/originalPixelsX
		self:setImageSize(self.imageSize.X*differenceMultiplier, self.imageSize.X*differenceMultiplier)
	end
	self.cellSize = pixelsX
	self.objects.container.Size = UDim2.new(0, pixelsX, 0, pixelsX)
end

function Icon:setEnabled(bool)
	self.enabled = bool
	self.objects.container.Visible = bool
	self.updated:Fire()
end

function Icon:setCellSize(pixelsX)
	local originalPixelsX = self.cellSize
	pixelsX = tonumber(pixelsX) or self.cellSize
	if originalPixelsX then
		local differenceMultiplier = pixelsX/originalPixelsX
		self:setImageSize(self.imageSize.X*differenceMultiplier, self.imageSize.X*differenceMultiplier)
	end
	self.cellSize = pixelsX
	self.objects.container.Size = UDim2.new(0, pixelsX, 0, pixelsX)
	self.updated:Fire()
end

function Icon:setBaseZIndex(baseValue)
	local container = self.objects.container
	baseValue = tonumber(baseValue) or container.ZIndex
	local difference = baseValue - container.ZIndex
	if difference == 0 then
		return "The baseValue is the same"
	end
	for _, object in pairs(self.objects) do
		object.ZIndex = object.ZIndex + difference
	end
end

function Icon:setToggleMenu(guiObject)
	if not guiObject or not guiObject:IsA("GuiObject") then
		guiObject = nil
	end
	self.toggleMenu = guiObject
end

function Icon:setToggleFunction(toggleFunction)
	if type(toggleFunction) == "function" then
		self.toggleFunction = toggleFunction
	end
end

function Icon:setHoverFunction(hoverFunction)
	if type(hoverFunction) == "function" then
		self.hoverFunction = hoverFunction
	end
end

function Icon:setTheme(themeDetails)
	local gradientEnabled = false
	local function parseDetails(objectName, toggleDetails)
		local errorBaseMessage = "Topbar+ | Failed to set theme:"
		local object = self.objects[objectName]
		if not object then
			if objectName == "toggleTweenInfo" then
				self.theme.toggleTweenInfo = toggleDetails
			--[[else
				warn(("%s invalid objectName '%s'"):format(errorBaseMessage, objectName))]]
			end
			return false
		end
		for toggleStatus, propertiesTable in pairs(toggleDetails) do
			local originalPropertiesTable = self.theme[objectName][toggleStatus]
			if not originalPropertiesTable then
				warn(("%s invalid toggleStatus '%s'. Use 'selected' or 'deselected'."):format(errorBaseMessage, toggleStatus))
				return false
			end
			local oppositeToggleStatus = (toggleStatus == "selected" and "deselected") or "selected"
			local oppositeGroup = self.theme[objectName][oppositeToggleStatus]
			local group = self.theme[objectName][toggleStatus]
			for key, value in pairs(propertiesTable) do
				if objectName == "gradient" then
					gradientEnabled = true
				end
				local oppositeKey = oppositeGroup[key]
				if not oppositeKey then
					oppositeGroup[key] = group[key]
				end
				group[key] = value
			end
			if toggleStatus == self.toggleStatus then
				self:applyThemeToObject(objectName, toggleStatus)
			end
		end
	end
	for objectName, toggleDetails in pairs(themeDetails) do
		parseDetails(objectName, toggleDetails)
	end
	self.objects.gradient.Enabled = gradientEnabled
end

function Icon:applyThemeToObject(objectName, toggleStatus)
	local object = self.objects[objectName]
	if object then
		local propertiesTable = self.theme[objectName][(toggleStatus or self.toggleStatus)]
		local toggleTweenInfo = self.theme.toggleTweenInfo
		local invalidProperties = {"Image","Color","NumberSequence"}
		local finalPropertiesTable = {}
		local noTweenTable = {}
		for propName, propValue in pairs(propertiesTable) do
			if propName == "Transparency" and object:IsA("UIGradient") then
				object[propName] = propValue
			end
			if table.find(invalidProperties, propName) then
				object[propName] = propValue
			else
				finalPropertiesTable[propName] = propValue
			end
		end
		local tween = tweenService:Create(object, toggleTweenInfo, finalPropertiesTable):Play()
		debris:AddItem(tween,toggleTweenInfo.Time)
	end
end

function Icon:applyThemeToAllObjects(...)
	for objectName, _ in pairs(self.theme) do
		self:applyThemeToObject(objectName, ...)
	end
end

function Icon:select()
	self.toggleStatus = "selected"
	self:applyThemeToAllObjects()
	self.toggleFunction()
	if self.toggleMenu then
		self.toggleMenu.Visible = true
	end
	self.selected:Fire()
end

function Icon:deselect()
	self.toggleStatus = "deselected"
	self:applyThemeToAllObjects()
	self.toggleFunction()
	if self.toggleMenu then
		self.toggleMenu.Visible = false
	end
	self.deselected:Fire()
end

function Icon:notify(clearNoticeEvent)
	coroutine.wrap(function()
		if not clearNoticeEvent then
			clearNoticeEvent = self.deselected
		end
		self.totalNotifications = self.totalNotifications + 1
		self.objects.amount.Text = (self.totalNotifications < 100 and self.totalNotifications) or "99+"
		self.objects.notification.Visible = true
		
		local dropdown = self.dropdown
		local promptedOptions = {}
		if dropdown then
			for i, option in pairs(dropdown.options) do
				if table.find(option.events, clearNoticeEvent) then
					local dNotice = option.notice
					if not dNotice then
						dNotice = self.objects.notification:Clone()
						dNotice.Position = UDim2.new(0.8, 0, 0.175, -1)
						dNotice.Size = UDim2.new(0.2, 0, 0.65, 0)
						dNotice.ZIndex = dNotice.ZIndex + 10
						dNotice.Amount.ZIndex = dNotice.Amount.ZIndex + 10
						dNotice.Amount.Text = 0
						dNotice.Parent = option.container
						option.notice = dNotice
						local optionName = option.container.OptionName
						local ONS = optionName.Size
						optionName.Size = UDim2.new(0.82, ONS.X.Offset, ONS.Y.Scale, ONS.Y.Offset)
					end
					pcall(function() dNotice.ImageColor3 = self.theme.notification.deselected.ImageColor3 end)
					pcall(function() dNotice.Amount.TextColor3 = self.theme.amount.deselected.TextColor3 end)
					dNotice.Amount.Text = tonumber(dNotice.Amount.Text) + 1
					table.insert(promptedOptions, option)
				end
			end
		end

		local notifComplete = Signal.new()
		local endEvent = self.endNotifications:Connect(function()
			notifComplete:Fire()
		end)
		local customEvent = clearNoticeEvent:Connect(function()
			notifComplete:Fire()
		end)
			
		notifComplete:Wait()
		
		endEvent:Disconnect()
		customEvent:Disconnect()
		notifComplete:Disconnect()
		
		self.totalNotifications = self.totalNotifications - 1
		if self.totalNotifications < 1 then
			self.objects.notification.Visible = false
		end

		if self.dropdown then
			for _, option in pairs(promptedOptions) do
				local dNotice = option.notice
				local optionName = option.container.OptionName
				local ONS = optionName.Size
				local totalDNotifications = tonumber(dNotice.Amount.Text) - 1
				dNotice.Amount.Text = totalDNotifications
				if totalDNotifications < 1 then
					option.notice = nil
					dNotice:Destroy()
					optionName.Size = UDim2.new(0.95, ONS.X.Offset, ONS.Y.Scale, ONS.Y.Offset)
				end
			end
		end
	end)()
end

function Icon:clearNotifications()
	self.endNotifications:Fire()
end

function Icon:destroy()
	self:clearNotifications()
	self._maid:clean()
	self._fakeChatConnections:clean()
end



return Icon