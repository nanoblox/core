-- UTILITY
local DirectoryService = require(4926442976)
local Maid = require(5086306120)
local Signal = require(4893141590)



-- SETUP ICON TEMPLATE
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
iconContainer.Name = "IconContainer"
iconContainer.Position = UDim2.new(0, 104, 0, 4)
iconContainer.Visible = false
iconContainer.ZIndex = 1
iconContainer.Parent = topbarContainer

local iconButton = Instance.new("TextButton")
iconButton.Name = "IconButton"
iconButton.Visible = true
iconButton.ZIndex = 2
iconButton.BorderSizePixel = 0
iconButton.Parent = iconContainer

local iconImage = Instance.new("ImageLabel")
iconImage.BackgroundTransparency = 1
iconImage.Name = "IconImage"
iconImage.AnchorPoint = Vector2.new(0.5, 0.5)
iconImage.Position = UDim2.new(0.5, 0, 0.5, 0)
iconImage.Visible = true
iconImage.ZIndex = 3
iconImage.ScaleType = Enum.ScaleType.Fit
iconImage.Parent = iconButton

local iconLabel = Instance.new("TextLabel")
iconLabel.BackgroundTransparency = 1
iconLabel.Name = "IconLabel"
iconLabel.AnchorPoint = Vector2.new(0, 0.5)
iconLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
iconLabel.Text = ""
iconLabel.TextXAlignment = Enum.TextXAlignment.Left
iconLabel.TextScaled = true
iconLabel.ZIndex = 3
iconLabel.Parent = iconButton

local iconGradient = Instance.new("UIGradient")
iconGradient.Name = "IconGradient"
iconGradient.Enabled = false
iconGradient.Parent = iconButton

local iconCorner = Instance.new("UICorner")
iconCorner.Name = "IconCorner"
iconCorner.Parent = iconButton

local iconOverlay = Instance.new("ImageLabel")
iconOverlay.Name = "IconOverlay"
iconOverlay.BackgroundTransparency = 1
iconOverlay.Position = iconButton.Position
iconOverlay.Size = iconButton.Size
iconOverlay.Visible = true
iconOverlay.ZIndex = iconButton.ZIndex + 1
iconOverlay.ImageTransparency = 1
iconOverlay.ImageColor3 = Color3.new(1,1,1)
iconOverlay.BorderSizePixel = 0
iconOverlay.Image = "http://www.roblox.com/asset/?id=5540166883"
iconOverlay.ScaleType = Enum.ScaleType.Crop
iconOverlay.Parent = iconContainer

local iconOverlayCorner = iconCorner:Clone()
iconOverlayCorner.Name = "IconOverlayCorner"
iconOverlayCorner.Parent = iconOverlay


-- Notice prompts
local noticeFrame = Instance.new("ImageLabel")
noticeFrame.BackgroundTransparency = 1
noticeFrame.Name = "NoticeFrame"
noticeFrame.Position = UDim2.new(0.45, 0, 0, -2)
noticeFrame.Size = UDim2.new(1, 0, 0.7, 0)
noticeFrame.Visible = false
noticeFrame.ZIndex = 4
noticeFrame.ImageTransparency = 0
noticeFrame.ScaleType = Enum.ScaleType.Fit
noticeFrame.Parent = iconButton

local noticeLabel = Instance.new("TextLabel")
noticeLabel.Name = "NoticeLabel"
noticeLabel.BackgroundTransparency = 1
noticeLabel.Position = UDim2.new(0.25, 0, 0.15, 0)
noticeLabel.Size = UDim2.new(0.5, 0, 0.7, 0)
noticeLabel.Visible = true
noticeLabel.ZIndex = 5
noticeLabel.Font = Enum.Font.Arial
noticeLabel.Text = "0"
noticeLabel.TextScaled = true
noticeLabel.Parent = noticeFrame


-- Captions
local captionContainer = Instance.new("Frame")
captionContainer.Name = "CaptionContainer"
captionContainer.Position = UDim2.new(0.5,0,1,4)
captionContainer.BackgroundTransparency = 1
captionContainer.AnchorPoint = Vector2.new(0.5,0)
captionContainer.ClipsDescendants = true
captionContainer.ZIndex = 30
captionContainer.Visible = false
captionContainer.Parent = iconContainer

local captionFrame = Instance.new("Frame")
captionFrame.Name = "CaptionFrame"
captionFrame.BorderSizePixel = 0
captionFrame.AnchorPoint = Vector2.new(0.5,0.5)
captionFrame.Position = UDim2.new(0.5,0,0.5,0)
captionFrame.Size = UDim2.new(1,0,1,0)
captionFrame.ZIndex = 31
captionFrame.Parent = captionContainer

local captionLabel = Instance.new("TextLabel")
captionFrame.Name = "CaptionLabel"
captionLabel.BackgroundTransparency = 1
captionLabel.TextScaled = true
captionLabel.TextSize = 12
captionLabel.Position = UDim2.new(0,3,0.12,3)
captionLabel.Size = UDim2.new(1,-6,0.8,-6)
captionLabel.ZIndex = 32
captionLabel.Parent = captionContainer

local captionCorner = Instance.new("UICorner")
captionFrame.Name = "CaptionCorner"
captionCorner.Parent = captionFrame

local captionOverlineContainer = Instance.new("Frame")
captionFrame.Name = "CaptionOverlineContainer"
captionOverlineContainer.BackgroundTransparency = 1
captionOverlineContainer.AnchorPoint = Vector2.new(0.5,0.5)
captionOverlineContainer.Position = UDim2.new(0.5,0,-0.5,3)
captionOverlineContainer.Size = UDim2.new(1,0,1,0)
captionOverlineContainer.ZIndex = 33
captionOverlineContainer.ClipsDescendants = true
captionOverlineContainer.Parent = captionContainer

local captionOverline = Instance.new("Frame")
captionOverline.Name = "CaptionOverline"
captionOverline.AnchorPoint = Vector2.new(0.5,0.5)
captionOverline.Position = UDim2.new(0.5,0,1.5,-3)
captionOverline.Size = UDim2.new(1,0,1,0)
captionOverline.ZIndex = 34
captionOverline.Parent = captionOverlineContainer

local captionOverlineCorner = captionCorner:Clone()
captionOverline.Name = "CaptionOverlineCorner"
captionOverlineCorner.Parent = captionOverline


-- Tips
local tipFrame = Instance.new("Frame")
tipFrame.Name = "TipFrame"
tipFrame.BorderSizePixel = 0
tipFrame.AnchorPoint = Vector2.new(0.5,0.5)
tipFrame.Position = UDim2.new(0.5,0,0.5,0)
tipFrame.Size = UDim2.new(1,0,1,-8)
tipFrame.ZIndex = 40
tipFrame.Parent = iconContainer

local tipCorner = Instance.new("UICorner")
tipCorner.Name = "TipCorner"
tipCorner.CornerRadius = UDim.new(0.25,0)
tipCorner.Parent = tipFrame

local tipLabel = Instance.new("TextLabel")
tipLabel.Name = "TipLabel"
tipLabel.BackgroundTransparency = 1
tipLabel.TextScaled = false
tipLabel.TextSize = 12
tipLabel.Position = UDim2.new(0,3,0,3)
tipLabel.Size = UDim2.new(1,-6,1,-6)
tipLabel.ZIndex = 41
tipLabel.Parent = tipFrame


-- Dropdowns
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
indicator.Active = true
indicator.Parent = topbarPlusGui



-- SETUP DIRECTORIES
local projectName = "Topbar+"
DirectoryService:createDirectory("ReplicatedStorage.HDAdmin."..projectName, script:GetChildren())
DirectoryService:createDirectory("StarterGui", {topbarPlusGui})



return true