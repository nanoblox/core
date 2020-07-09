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

local stateOverlay = Instance.new("ImageLabel")
stateOverlay.BackgroundTransparency = 1
stateOverlay.Name = "StateOverlay"
stateOverlay.Position = iconButton.Position
stateOverlay.Size = iconButton.Size
stateOverlay.Visible = true
stateOverlay.ZIndex = iconButton.ZIndex + 1
stateOverlay.Image = iconButton.Image
stateOverlay.ImageTransparency = 1
stateOverlay.ImageColor3 = Color3.fromRGB(255, 255, 255)
stateOverlay.ScaleType = iconButton.ScaleType
stateOverlay.Parent = iconButton.Parent

local gradient = Instance.new("UIGradient")
gradient.Enabled = false
gradient.Parent = iconButton

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
uiSize.MinSize = Vector2.new(150,0)
uiSize.Parent = dropdown

local tempFolder = Instance.new("Folder")
tempFolder.Name = "Temp"
tempFolder.Parent = script:WaitForChild("Dropdown")

local clickSound = Instance.new("Sound")
clickSound.Name = "ClickSound"
clickSound.SoundId = "rbxassetid://5273899897"
clickSound.Parent = topbarPlusGui

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


--TOOL TIP
local toolTip = Instance.new("Frame")
toolTip.Name = "ToolTip"
toolTip.BackgroundTransparency = 1
toolTip.AnchorPoint = Vector2.new(0,1)
toolTip.ClipsDescendants = true
toolTip.ZIndex = 100
toolTip.Visible = false
toolTip.Parent = topbarPlusGui

local toolTipBackground = Instance.new("Frame")
toolTipBackground.Name = "Background"
toolTipBackground.BackgroundTransparency = 0.1
toolTipBackground.BorderSizePixel = 0
toolTipBackground.BackgroundColor3 = Color3.new(1,1,1)
toolTipBackground.AnchorPoint = Vector2.new(0.5,0.5)
toolTipBackground.Position = UDim2.new(0.5,0,0.5,0)
toolTipBackground.Size = UDim2.new(1,0,1,-8)
toolTipBackground.ZIndex = 101
toolTipBackground.Parent = toolTip

local topRect = Instance.new("ImageLabel")
topRect.Name = "TopRoundedRect"
topRect.BackgroundTransparency = 1
topRect.ImageColor3 = Color3.new(1,1,1)
topRect.ImageTransparency = 0.1
topRect.Image = "rbxasset://textures/ui/BottomRoundedRect8px.png"
topRect.ScaleType = Enum.ScaleType.Slice
topRect.SliceCenter = Rect.new(8,8,24,16)
topRect.SliceScale = 0.5
topRect.Size = UDim2.new(1,0,0,4)
topRect.AnchorPoint = Vector2.new(0,1)
topRect.Position = UDim2.new(0,0,0,0)
topRect.ZIndex = 101
topRect.Parent = toolTipBackground

local bottomRect = topRect:Clone()
bottomRect.Name = "BottomRoundedRect"
bottomRect.Image = "rbxasset://textures/ui/TopRoundedRect8px.png"
topRect.AnchorPoint = Vector2.new(0,0)
topRect.Position = UDim2.new(0,0,1,0)
bottomRect.Parent = toolTipBackground

local toolTipText = Instance.new("TextLabel")
toolTipText.BackgroundTransparency = 1
toolTipText.Font = Enum.Font.GothamSemibold
toolTipText.TextScaled = false
toolTipText.TextSize = 12
toolTipText.Position = UDim2.new(0,3,0,3)
toolTipText.Size = UDim2.new(1,-6,1,-6)
toolTipText.ZIndex = 102
toolTipText.Parent = toolTip

-- SETUP DIRECTORIES
local projectName = "Topbar+"
DirectoryService:createDirectory("ReplicatedStorage.HDAdmin."..projectName, script:GetChildren())
DirectoryService:createDirectory("StarterGui", {topbarPlusGui})



return true