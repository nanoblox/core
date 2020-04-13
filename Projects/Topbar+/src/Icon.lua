-- LOCAL
local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local player = game:GetService("Players").LocalPlayer
local playerGui = player.PlayerGui
local hdAdminGui = playerGui:WaitForChild("HDAdmin")
local topbarPlusGui = hdAdminGui:WaitForChild("Topbar+")
local topbarContainer = topbarPlusGui.TopbarContainer
local iconTemplate = topbarContainer["_IconTemplate"]
local hdAdminRs = replicatedStorage:WaitForChild("HDAdmin")
local signalPlus = hdAdminRs:WaitForChild("Signal+")
local Signal = require(signalPlus:WaitForChild("Signal"))
local Icon = {}
Icon.__index = Icon



-- CONSTRUCTOR
function Icon.new(name, imageId, order)
	local self = {}
	setmetatable(self, Icon)
	
	local button = iconTemplate:Clone()
	button.Name = name
	button.Visible = true
	
	self.objects = {
		["button"] = button,
		["image"] = button.IconImage,
		["notification"] = button.Notification,
		["amount"] = button.Notification.Amount
	}
	
	self.theme = {
		-- TOGGLE EFFECT
		["toggleTweenInfo"] = TweenInfo.new(0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		
		-- OBJECT PROPERTIES
		["button"] = {
			selected = {
				ImageColor3 = Color3.fromRGB(255, 255, 255),
			},
			deselected = {
				ImageColor3 = Color3.fromRGB(31, 33, 35),
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
	}
	self.toggleStatus = "deselected"
	self:applyThemeToAllObjects()
	
	self.name = name
	self.objects.imageId = imageId or 0
	self.order = order or 1
	self.objects.imageScale = 0.7
	self.enabled = true
	self.deselectWhenOtherIconSelected = true
	self.totalNotifications = 0
	self.toggleFunction = function(isSelected) end
	
	self.updated = Signal.new()
	self.selected = Signal.new()
	self.deselected = Signal.new()
	self.endNotifications = Signal.new()
	
	button.MouseButton1Click:Connect(function()
		if self.toggleStatus == "selected" then
			self:deselect()
		else
			self:select()
		end
	end)
		
	if imageId then
		self:setImage(imageId)
	end
	
	button.Parent = topbarContainer
	
	return self
end



-- METHODS
function Icon:setImage(imageId)
	self.objects.imageId = imageId
	self.objects.image.Image = "http://www.roblox.com/asset/?id="..imageId
end

function Icon:setOrder(order)
	self.order = tonumber(order) or 1
	self.updated:Fire()
end

function Icon:setImageScale(scale)
	scale = ((tonumber(scale) and scale >= 0 and scale <=1) and scale) or self.objects.imageScale
	self.objects.imageScale = scale
	self.objects.image.Position = UDim2.new(0, 0, (1-scale)/2, 0)
	self.objects.image.Size = UDim2.new(1, 0, scale, 0)
end

function Icon:setEnabled(bool)
	self.enabled = bool
	self.objects.button.Visible = bool
	self.updated:Fire()
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

function Icon:setTheme(themeDetails)
	local function parseDetails(objectName, toggleDetails)
		local errorBaseMessage = "Topbar+ | Failed to set theme:"
		local object = self.objects[objectName]
		if not object then
			if objectName == "toggleTweenInfo" then
				self.theme.toggleTweenInfo = toggleDetails
			else
				warn(("%s invalid objectName '%s'"):format(errorBaseMessage, objectName))
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
end

function Icon:applyThemeToObject(objectName, toggleStatus)
	local object = self.objects[objectName]
	if object then
		local propertiesTable = self.theme[objectName][(toggleStatus or self.toggleStatus)]
		local toggleTweenInfo = self.theme.toggleTweenInfo
		local invalidProperties = {"Image"}
		local finalPropertiesTable = {}
		for propName, propValue in pairs(propertiesTable) do
			if table.find(invalidProperties, propName) then
				object[propName] = propValue
			else
				finalPropertiesTable[propName] = propValue
			end
		end
		tweenService:Create(object, toggleTweenInfo, finalPropertiesTable):Play()
	end
end

function Icon:applyThemeToAllObjects(...)
	for objectName, toggleDetails in pairs(self.theme) do
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
		self.objects.amount.Text = self.totalNotifications
		self.objects.notification.Visible = true
		
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
	end)()
end

function Icon:clearNotifications()
	self.endNotifications:Fire()
end

function Icon:destroy()
	self.objects.button:Destroy()
	for signalName, signal in pairs(self) do
		if type(signal) == "table" and signal.Destroy then
			signal:Destroy()
		end
	end
end



return Icon