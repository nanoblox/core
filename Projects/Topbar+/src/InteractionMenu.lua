local contentProvider = game:GetService("ContentProvider")
local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local starterGui = game:GetService("StarterGui")
local HDAdmin = replicatedStorage:WaitForChild("HDAdmin")
local Signal = require(HDAdmin:WaitForChild("Signal"))
local interactionMenu = {}
interactionMenu.__index = interactionMenu

function interactionMenu.new(icon,options)
	local self = {}
	setmetatable(self, interactionMenu)
	
	self.tempConnections = {}
	self.constConnections = {}
	self.icon = icon
	self.optionTable = {}
	self.bringBackPlayerlist = false
	self.bringBackChat = false
	self.settings = {
		CanHidePlayerlist = true,
		CanHideChat = true,
		TweenSpeed = 0.2,
		EasingDirection = Enum.EasingDirection.Out,
		EasingStyle = Enum.EasingStyle.Quad,
		ChatDefaultDisplayOrder = 6,
	}
	local preload = {}
	
	for _,optionData in ipairs(options) do
		local option = self:newOption(optionData.Name,optionData.Icon,optionData.Order)
		table.insert(preload,option.container.Icon)
	end
	
	table.insert(self.constConnections,self.icon.objects.button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			local position = Vector2.new(input.Position.X,input.Position.Y)
			self:displayMenu(position)
		end
		input:Destroy()
	end))
	table.insert(self.constConnections,self.icon.objects.button.TouchLongPress:Connect(function(positions,state)
		if state == Enum.UserInputState.Begin then
			self:displayMenu()
		end
	end))
	
	spawn(function()
		contentProvider:PreloadAsync(preload)
	end)
	
	return self
end

function interactionMenu:menuIsOpen()
	if self.icon then
		if self.icon.objects.container.Parent.Parent.InteractionMenu.Visible then
			return true
		end
	end
	return false
end

function interactionMenu:hideMenu()
	for _,connection in pairs(self.tempConnections) do
		if connection.Connected then
			connection:Disconnect()
		end
	end
	if self.bringBackPlayerlist then
		starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,true)
		self.bringBackPlayerlist = false
	end
	local interactionMenuContainer = self.icon.objects.container.Parent.Parent.InteractionMenu
	if self.bringBackChat then
		local chat = interactionMenuContainer.Parent.Parent:FindFirstChild("Chat")
		if chat then
			chat.DisplayOrder = self.settings.ChatDefaultDisplayOrder
		end
	end
	interactionMenuContainer:TweenSize(
		UDim2.new(0.1,0,0,0),
		self.settings.EasingDirection,
		self.settings.EasingStyle,
		self.settings.TweenSpeed,
		true,
		function()
			if interactionMenuContainer.Size == UDim2.new(0.1,0,0,0) then
				interactionMenuContainer.Visible = false
			end
		end
	)
end

function interactionMenu:canHidePlayerlist(bool)
	assert(typeof(bool) == "boolean","Topbar+ | Expected boolean, got "..typeof(bool))
	self.settings.CanHidePlayerList = bool
end

function interactionMenu:canHideChat(bool)
	assert(typeof(bool) == "boolean","Topbar+ | Expected boolean, got "..typeof(bool))
	self.settings.CanHideChat = bool
end

function interactionMenu:setChatDefaultDisplayOrder(number)
	assert(typeof(number) == "number","Topbar+ | Expected number, got "..typeof(number))
	self.settings.ChatDefaultDisplayOrder = number
end

function interactionMenu:setTheme(theme)
	--[[
	Each icon has its own theme
	{
		TweenSpeed = 0.2,
		EasingDirection = Enum.EasingDirection.Out,
		EasingStyle = Enum.EasingStyle.Quad
	}
	]]
	assert(typeof(theme) == "table","Topbar+ | Expected table, got "..typeof(theme))
	if theme.TweenSpeed then
		self.settings.TweenSpeed = theme.TweenSpeed
	end
	if theme.EasingDirection then
		self.settings.EasingDirection = theme.EasingDirection
	end
	if theme.EasingStyle then
		self.settings.EasingStyle = theme.EasingStyle
	end
end

local function ToScale(offsetUDim2,viewportSize)
	return UDim2.new(offsetUDim2.X.Offset/viewportSize.X,0,offsetUDim2.Y.Offset/viewportSize.Y,0)
end

function interactionMenu:displayMenu(position)
	local interactionMenuContainer = self.icon.objects.container.Parent.Parent.InteractionMenu
	if interactionMenuContainer.Visible then self:hideMenu() return end
	
	if position then
		interactionMenuContainer.Position = UDim2.new(0,position.X,0,math.clamp(position.Y+36,36,10000000))
	else
		interactionMenuContainer.Position = UDim2.new(0,self.icon.objects.container.AbsolutePosition.X,0,self.icon.objects.container.AbsolutePosition.Y+36+32)--topbar offset and icon size
	end
	
	if workspace.CurrentCamera then
		local viewportSize = workspace.CurrentCamera.ViewportSize
		local position = UDim2.new(
			0,
			math.clamp(interactionMenuContainer.Position.X.Offset,0,viewportSize.X-interactionMenuContainer.AbsoluteSize.X-16),
			0,
			math.clamp(interactionMenuContainer.Position.Y.Offset,40,viewportSize.Y-interactionMenuContainer.AbsoluteSize.Y)
		)
		interactionMenuContainer.Position = ToScale(position,viewportSize)
	end
	
	for _,option in pairs(interactionMenuContainer:GetChildren()) do
		if option:IsA("Frame") and option.Name == "Option" then
			option.Visible = false
			option.Parent = script.Temp
		end
	end
	local containerSizeY = 8 --for top and bottom rounded rect
	local orderTable = {}
	
	for name,data in next, self.optionTable do
		orderTable[data.order] = data
	end
	
	for i,data in ipairs(orderTable) do
		data.container.Parent = interactionMenuContainer
		data.container.Visible = true
		data.container.Position = UDim2.new(0,0,0,4+(35*data.order)-35)
		containerSizeY = containerSizeY + data.container.Size.Y.Offset
	end
	
	if self.settings.CanHidePlayerlist and self.icon.rightSide and starterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList) then
		starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false)
		self.bringBackPlayerlist = true
	end
	
	local chat = interactionMenuContainer.Parent.Parent:FindFirstChild("Chat")
	if chat and self.settings.CanHideChat and interactionMenuContainer.Parent.DisplayOrder < chat.DisplayOrder then
		chat.DisplayOrder = interactionMenuContainer.Parent.DisplayOrder-1
		self.bringBackChat = true
	end
	
	interactionMenuContainer.Size = UDim2.new(0.1,0,0,0)
	interactionMenuContainer.Visible = true
	interactionMenuContainer:TweenSize(
		UDim2.new(0.1,0,0,containerSizeY),
		self.settings.EasingDirection,
		self.settings.EasingStyle,
		self.settings.TweenSpeed,
		true
	)
	
	local cancelCD = true
	delay(0.5,function()
		cancelCD = false
	end)
	
	table.insert(self.tempConnections,userInputService.InputBegan:Connect(function(input,gpe)
		if not cancelCD and (input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.MouseButton2
		or input.UserInputType == Enum.UserInputType.MouseWheel
		or input.UserInputType == Enum.UserInputType.MouseButton3
		or input.UserInputType == Enum.UserInputType.Touch)
		then
			local isOn = false
			for i,v in pairs(interactionMenuContainer.Parent.Parent:GetGuiObjectsAtPosition(input.Position.X,input.Position.Y)) do
				if v:IsDescendantOf(interactionMenuContainer) then
					isOn = true
					break
				end
			end
			if not isOn then
				self:hideMenu()
			end
		end
		input:Destroy()
	end))
	
	if userInputService.MouseEnabled then
		table.insert(self.tempConnections,userInputService.WindowFocusReleased:Connect(function()
			self:hideMenu()
		end))
	end
	
end

function interactionMenu:newOption(content,icon,order)
	assert(not self.optionTable[content],"Topbar+ | There is already an option with that name!")
	
	local optionContainer = Instance.new("Frame")
	optionContainer.Name = "Option"
	optionContainer.BackgroundColor3 = Color3.new(1,1,1)
	optionContainer.BackgroundTransparency = 1
	optionContainer.BorderSizePixel = 0
	optionContainer.Size = UDim2.new(1,0,0,35)
	optionContainer.Active = true
	optionContainer.Selectable = true
	optionContainer.ZIndex = 11
	optionContainer.Visible = false
	
	local optionIcon = Instance.new("ImageLabel")
	optionIcon.Name = "Icon"
	optionIcon.Image = icon
	optionIcon.ScaleType = Enum.ScaleType.Fit
	optionIcon.BackgroundTransparency = 1
	optionIcon.AnchorPoint = Vector2.new(0.5,0.5)
	optionIcon.Position = UDim2.new(0.1,5,0.5,0)
	optionIcon.Size = UDim2.new(0,25,0,25)
	optionIcon.ZIndex = 12
	optionIcon.Parent = optionContainer
	
	local optionText = Instance.new("TextLabel")
	optionText.Text = content
	optionText.BackgroundTransparency = 1
	optionText.AnchorPoint = Vector2.new(0,0.5)
	optionText.Position = UDim2.new(0.1,25,0.5,0)
	optionText.Size = UDim2.new(1,-40,0,25)
	optionText.Font = Enum.Font.GothamSemibold
	optionText.TextScaled = true
	optionText.TextColor3 = Color3.new(1,1,1)
	optionText.ZIndex = 12
	optionText.TextXAlignment = Enum.TextXAlignment.Left
	optionText.Parent = optionContainer
	
	local uiText = Instance.new("UITextSizeConstraint")
	uiText.MaxTextSize = 18
	uiText.MinTextSize = 8
	uiText.Parent = optionText
	
	local option = {
		event = Signal.new(),
		container = optionContainer,
		order = order or 1,
	}
	
	optionContainer.MouseEnter:Connect(function()
		optionContainer.BackgroundTransparency = 0.9
	end)
	
	
	optionContainer.MouseLeave:Connect(function()
		optionContainer.BackgroundTransparency = 1
	end)
	
	optionContainer.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			option.event:Fire()
			self:hideMenu()
		end
		input:Destroy()	
	end)
	
	--[[optionContainer.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			print(input.Position)
			option.event:Fire()
			self:hideMenu()
		end		
	end)]] --Didn't work as expected
	
	optionContainer.TouchTap:Connect(function()
		option.event:Fire()
		self:hideMenu()
	end)
	
	--controller support
	
	local firstOrder = option.order
	for name,data in next, self.optionTable do
		if data.order == option.order then
			option.order = option.order + 1
			break
		end
	end
	for name,data in next, self.optionTable do
		if data.order > firstOrder then
			data.order = data.order + 1
		end
	end
	self.optionTable[content] = option
	
	return option
end

function interactionMenu:removeOption(name)
	local option = self.optionTable[name]
	if option then
		option.container:Destroy()
		option.event:Destroy()
		option = nil
		self.optionTable[name] = nil
	else
		warn("Topbar+ | Could not find an option with that name")
	end
end

function interactionMenu:destroy()
	self:hideMenu()
	for i,v in pairs(self.optionTable) do
		if v.container then
			v.container:Destroy()
		end
		if v.event then
			v.event:Destroy()
		end
	end
	for i,v in pairs(self.constConnections) do
		if v.Connected then
			v:Disconnect()
		end
	end
	self = nil
end

return interactionMenu
