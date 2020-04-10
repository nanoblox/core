-- LOCAL
local player = game:GetService("Players").LocalPlayer
local playerGui = player.PlayerGui
local topbarGui = playerGui:WaitForChild("Topbar+")
local topbarContainer = topbarGui.TopbarContainer
local iconTemplate = topbarContainer["_IconTemplate"]
local Signal = require(script.Parent.Parent.Signal)
local Icon = {}
Icon.__index = Icon



-- CONSTRUCTOR
function Icon.new(name, imageId, order)
	local self = {}
	setmetatable(self, Icon)
	
	local iconButton = iconTemplate:Clone()
	iconButton.Name = name
	iconButton.Visible = true
	iconButton.Parent = topbarContainer
	
	self.iconButton = iconButton
	self.name = name
	self.imageId = imageId or 0
	self.order = order or 1
	self.imageScale = 0.7
	self.enabled = true
	self.isSelected = false
	self.deselectWhenOtherIconSelected = true
	self.totalNotifications = 0
	
	self.updated = Signal.new()
	self.selected = Signal.new()
	self.deselected = Signal.new()
	self.endNotifications = Signal.new()
	
	iconButton.MouseButton1Click:Connect(function()
		if self.isSelected then
			self:deselect()
		else
			self:select()
		end
	end)
		
	if imageId then
		self:setImage(imageId)
	end
	
	return self
end



-- METHODS
function Icon:setImage(imageId)
	self.imageId = imageId
	self.iconButton.IconImage.Image = "http://www.roblox.com/asset/?id="..imageId
end

function Icon:setOrder(order)
	self.order = tonumber(order) or 1
	self.updated:Fire()
end

function Icon:setImageScale(scale)
	scale = ((tonumber(scale) and scale >= 0 and scale <=1) and scale) or self.imageScale
	self.imageScale = scale
	self.iconButton.IconImage.Position = UDim2.new(0, 0, (1-scale)/2, 0)
	self.iconButton.IconImage.Size = UDim2.new(1, 0, scale, 0)
end

function Icon:setEnabled(bool)
	self.enabled = bool
	self.iconButton.Visible = bool
	self.updated:Fire()
end

function Icon:setToggleMenu(guiObject)
	if not guiObject or not guiObject:IsA("GuiObject") then
		guiObject = nil
	end
	self.toggleMenu = guiObject
end

function Icon:select()
	if self.toggleMenu then
		self.toggleMenu.Visible = true
	end
	self.iconButton.IconImage.ImageColor3 = Color3.fromRGB(57, 60, 65)
	self.iconButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
	self.isSelected = true
	self.selected:Fire()
end

function Icon:deselect()
	if self.toggleMenu then
		self.toggleMenu.Visible = false
	end
	self.iconButton.IconImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
	self.iconButton.ImageColor3 = Color3.fromRGB(31, 33, 35)
	self.isSelected = false
	self.deselected:Fire()
end

function Icon:notify(clearNoticeEvent)
	coroutine.wrap(function()
		if not clearNoticeEvent then
			clearNoticeEvent = self.deselected
		end
		local notification = self.iconButton.Notification
		self.totalNotifications = self.totalNotifications + 1
		notification.TextLabel.Text = self.totalNotifications
		notification.Visible = true
		
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
			notification.Visible = false
		end
	end)()
end

function Icon:clearNotifications()
	self.endNotifications:Fire()
end



return Icon