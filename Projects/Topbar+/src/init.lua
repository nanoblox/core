-- Automation test Topbar+
-- SERVICES
local players = game:GetService("Players")
local starterGui = game:GetService("StarterGui")
local replicatedStorage = game:GetService("ReplicatedStorage")
local signalPlus = require(4893141590)



-- CREATE UI
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
iconButton.Image = "http://www.roblox.com/asset/?id=4871650602"
iconButton.ImageTransparency = 0.3
iconButton.ImageColor3 = Color3.fromRGB(31, 33, 35)
iconButton.ScaleType = Enum.ScaleType.Stretch
iconButton.Parent = iconContainer

local iconImage = Instance.new("ImageLabel")
iconImage.BackgroundTransparency = 1
iconImage.Name = "IconImage"
iconImage.Position = UDim2.new(0, 0, 0.2, 0)
iconImage.Size = UDim2.new(1, 0, 0.6, 0)
iconImage.Visible = true
iconImage.ZIndex = 3
iconImage.ImageTransparency = 0
iconImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
iconImage.ScaleType = Enum.ScaleType.Fit
iconImage.Parent = iconButton

local notification = Instance.new("ImageLabel")
notification.BackgroundTransparency = 1
notification.Name = "Notification"
notification.Position = UDim2.new(0.55, 0, 0, -2)
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



-- SETUP DIRECTORIES
local mainDirectoryName = "HDAdmin"
local function setupDirectory(directoryName, directoryParent)
	local directory = directoryParent:FindFirstChild(directoryName)
	if not directory then
		directory = Instance.new("Folder")
		directory.Name = directoryName
		directory.Parent = directoryParent
	end
	return directory
end

-- StarterGui/PlayerGui
local directoryGui = setupDirectory(mainDirectoryName, starterGui)
for _, plr in pairs(players:GetPlayers()) do
	local playerDirectoryGui = setupDirectory(mainDirectoryName, starterGui)
	for a,b in pairs(directoryGui:GetChildren()) do
		b:Clone().Parent = playerDirectoryGui
	end
end
topbarPlusGui.Parent = directoryGui

-- ReplicatedStorage
local directoryRs = setupDirectory(mainDirectoryName, replicatedStorage)
local topbarPlusRs = setupDirectory("Topbar+", directoryRs)
for a,b in pairs(script:GetChildren()) do
	b.Parent = topbarPlusRs
end



return true