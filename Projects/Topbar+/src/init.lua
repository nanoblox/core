-- UTILITY
local DirectoryService = require(4926442976)
local Maid = require(5086306120)
local Signal = require(4893141590)



-- CREATE ICON UI
local topbarPlusGui = Instance.new("ScreenGui")
topbarPlusGui.Enabled = true
topbarPlusGui.DisplayOrder = 0
topbarPlusGui.IgnoreGuiInset = true
topbarPlusGui.ResetOnSpawn = false
topbarPlusGui.Name = "Topbar+"

local topbarContainer = Instance.new("Frame")
topbarContainer.BackgroundTransparency = 1
topbarContainer.Name = "TopbarContainer"
topbarContainer.Position = UDim2.new(0, 0, 0, 0)
topbarContainer.Size = UDim2.new(1, 0, 0, 36)
topbarContainer.Visible = true
topbarContainer.ZIndex = 1
topbarContainer.Parent = topbarPlusGui

local iconContainer = Instance.new("Frame")
iconContainer.BackgroundTransparency = 1
iconContainer.Name = "_IconTemplate"
iconContainer.Position = UDim2.new(0, 104, 0, 4)
iconContainer.Size = UDim2.new(0, 32, 0, 32)
iconContainer.Visible = false
iconContainer.ZIndex = 1
iconContainer.Parent = topbarContainer

local iconButton = Instance.new("ImageButton")
iconButton.BackgroundTransparency = 1
iconButton.Name = "IconButton"
iconButton.Position = UDim2.new(0, 0, 0, 0)
iconButton.Size = UDim2.new(1, 0, 1, 0)
iconButton.Visible = true
iconButton.ZIndex = 2
iconButton.Image = "rbxassetid://5027411759"
iconButton.ImageTransparency = 0.5
iconButton.ImageColor3 = Color3.fromRGB(0, 0, 0)
iconButton.ScaleType = Enum.ScaleType.Stretch
iconButton.Parent = iconContainer

local iconImage = Instance.new("ImageLabel")
iconImage.BackgroundTransparency = 1
iconImage.Name = "IconImage"
iconImage.AnchorPoint = Vector2.new(0.5, 0.5)
iconImage.Position = UDim2.new(0.5, 0, 0.5, 0)
iconImage.Size = UDim2.new(0, 20, 0, 20)
iconImage.Visible = true
iconImage.ZIndex = 3
iconImage.ImageTransparency = 0
iconImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
iconImage.ScaleType = Enum.ScaleType.Fit
iconImage.Parent = iconButton

local notification = Instance.new("ImageLabel")
notification.BackgroundTransparency = 1
notification.Name = "Notification"
notification.Position = UDim2.new(0.45, 0, 0, -2)
notification.Size = UDim2.new(1, 0, 0.7, 0)
notification.Visible = false
notification.ZIndex = 4
notification.Image = "http://www.roblox.com/asset/?id=4871790969"
notification.ImageTransparency = 0
notification.ImageColor3 = Color3.fromRGB(255, 255, 255)
notification.ScaleType = Enum.ScaleType.Fit
notification.Parent = iconButton

local amount = Instance.new("TextLabel")
amount.BackgroundTransparency = 1
amount.Name = "Amount"
amount.Position = UDim2.new(0.25, 0, 0.15, 0)
amount.Size = UDim2.new(0.5, 0, 0.7, 0)
amount.Visible = true
amount.ZIndex = 5
amount.Font = Enum.Font.Arial
amount.Text = "0"
amount.TextColor3 = Color3.fromRGB(31, 33, 35)
amount.TextScaled = true
amount.Parent = notification


--CREATE DROPDOWN
local dropdown = Instance.new("Frame")
dropdown.Name = "Dropdown"
dropdown.BackgroundTransparency = 1
dropdown.Visible = false
dropdown.ClipsDescendants = true
dropdown.Parent = topbarPlusGui

local background = Instance.new("Frame")
background.Name = "Background"
background.BackgroundColor3 = Color3.fromRGB(31, 33, 35)
background.BackgroundTransparency = 0.3
background.BorderSizePixel = 0
background.ZIndex = 10
background.AnchorPoint = Vector2.new(0.5,0.5)
background.Position = UDim2.new(0.5,0,0.5,0)
background.Size = UDim2.new(1,0,1,-8)
background.Parent = dropdown

local topRect = Instance.new("ImageLabel")
topRect.Name = "TopRoundedRect"
topRect.BackgroundTransparency = 1
topRect.ImageColor3 = Color3.fromRGB(31, 33, 35)
topRect.ImageTransparency = 0.3
topRect.Image = "rbxasset://textures/ui/BottomRoundedRect8px.png"
topRect.ScaleType = Enum.ScaleType.Slice
topRect.SliceCenter = Rect.new(8,8,24,16)
topRect.SliceScale = 0.5
topRect.Size = UDim2.new(1,0,0,4)
topRect.AnchorPoint = Vector2.new(0,1)
topRect.Position = UDim2.new(0,0,0,0)
topRect.Parent = background

local bottomRect = topRect:Clone()
bottomRect.Name = "BottomRoundedRect"
bottomRect.Image = "rbxasset://textures/ui/TopRoundedRect8px.png"
topRect.AnchorPoint = Vector2.new(0,0)
topRect.Position = UDim2.new(0,0,1,0)
bottomRect.Parent = background

local uiSize = Instance.new("UISizeConstraint")
uiSize.Name = "_UISizeConstraint"
uiSize.MinSize = Vector2.new(140,0)
uiSize.Parent = dropdown

local tempFolder = Instance.new("Folder")
tempFolder.Name = "Temp"
tempFolder.Parent = script:WaitForChild("Dropdown")

local clickSound = Instance.new("Sound")
clickSound.Name = "ClickSound"
clickSound.SoundId = "rbxassetid://5273899897"
clickSound.Parent = topbarPlusGui

--[[CREATE CONSOLE UI
local consoleContainer = Instance.new("Frame")
consoleContainer.Name = "ConsoleContainer"
consoleContainer.BackgroundTransparency = 1
consoleContainer.Position = UDim2.new(0.1,0,0,5)
consoleContainer.Size = UDim2.new(0.8,0,0,32)
consoleContainer.Visible = false
consoleContainer.Parent = topbarPlusGui

local consoleUIGrid = Instance.new("UIGridLayout")
consoleUIGrid.Name = "_UIGridLayout"
consoleUIGrid.CellPadding = UDim2.new(0,10,0,10)
consoleUIGrid.CellSize = UDim2.new(0,32,0,32)
consoleUIGrid.FillDirection = Enum.FillDirection.Horizontal
consoleUIGrid.FillDirectionMaxCells = 0
consoleUIGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
consoleUIGrid.Parent = consoleContainer

local consoleIconTemplate = Instance.new("Frame")
consoleIconTemplate.Name = "_IconTemplate"
consoleIconTemplate.BackgroundTransparency = 1
consoleIconTemplate.Visible = false
consoleIconTemplate.Parent = consoleContainer

local consoleIconButton = Instance.new("ImageButton")
consoleIconButton.Name = "IconButton"
consoleIconButton.Size = UDim2.new(1,0,1,0)
consoleIconTemplate.Selectable = true
consoleIconTemplate.Active = true
consoleIconButton.BackgroundTransparency = 1
consoleIconButton.ZIndex = 2
consoleIconButton.Image = "rbxassetid://5027411759"
consoleIconButton.ImageTransparency = 0.5
consoleIconButton.ScaleType = Enum.ScaleType.Stretch
consoleIconButton.ImageColor3 = Color3.new(0,0,0)
consoleIconButton.Parent = consoleIconTemplate

local consoleIconImage = Instance.new("ImageLabel")
consoleIconImage.Name = "IconImage"
consoleIconImage.Position = UDim2.new(0.5,0,0.5,0)
consoleIconImage.Size = UDim2.new(0.6,0,0.6,0)
consoleIconImage.AnchorPoint = Vector2.new(0.5,0.5)
consoleIconImage.BackgroundTransparency = 1
consoleIconImage.ZIndex = 3
consoleIconImage.Image = ""
consoleIconImage.ImageTransparency = 0
consoleIconImage.ScaleType = Enum.ScaleType.Fit
consoleIconImage.Parent = consoleIconButton

local consoleIconNotification = Instance.new("ImageLabel")
consoleIconNotification.Name = "Notification"
consoleIconNotification.Position = UDim2.new(0.45,0,-0.03,0)
consoleIconNotification.Size = UDim2.new(1,0,0.7,0)
consoleIconNotification.BackgroundTransparency = 1
consoleIconNotification.ZIndex = 4
consoleIconNotification.Image = "http://www.roblox.com/asset/?id=4871790969"
consoleIconNotification.ImageTransparency = 0
consoleIconNotification.ScaleType = Enum.ScaleType.Fit
consoleIconNotification.Visible = false
consoleIconNotification.Parent = consoleIconButton

local consoleNotificationText = Instance.new("TextLabel")
consoleNotificationText.Name = "Amount"
consoleNotificationText.Position = UDim2.new(0.25,0,0.15,0)
consoleNotificationText.BackgroundTransparency = 1
consoleNotificationText.Size = UDim2.new(0.5,0,0.7,0)
consoleNotificationText.ZIndex = 5
consoleNotificationText.Font = Enum.Font.Arial
consoleNotificationText.Text = "1"
consoleNotificationText.TextColor3 = Color3.fromRGB(31,33,35)
consoleNotificationText.TextScaled = true
consoleNotificationText.Parent = consoleIconNotification
]]

local indicator = Instance.new("ImageLabel")
indicator.Name = "Indicator"
indicator.BackgroundTransparency = 1
indicator.Image = "rbxassetid://5278151556"
indicator.Size = UDim2.new(0,32,0,32)
indicator.AnchorPoint = Vector2.new(0.5,0)
indicator.Position = UDim2.new(0.5,0,0,5)
indicator.ScaleType = Enum.ScaleType.Fit
indicator.Visible = false
indicator.Parent = topbarPlusGui

-- SETUP DIRECTORIES
local projectName = "Topbar+"
DirectoryService:createDirectory("ReplicatedStorage.HDAdmin."..projectName, script:GetChildren())
DirectoryService:createDirectory("StarterGui", {topbarPlusGui})



return true
