-- SERVICES
local players = game:GetService("Players")
local starterGui = game:GetService("StarterGui")
local replicatedStorage = game:GetService("ReplicatedStorage")

print(script.Name)

-- CREATE UI
local topbarGui = Instance.new("ScreenGui")
topbarGui.Enabled = true
topbarGui.DisplayOrder = 0
topbarGui.IgnoreGuiInset = true
topbarGui.ResetOnSpawn = false
topbarGui.Name = "Topbar+"

local topbarContainer = Instance.new("Frame")
topbarContainer.BackgroundTransparency = 1
topbarContainer.Name = "TopbarContainer"
topbarContainer.Position = UDim2.new(0, 0, 0, 0)
topbarContainer.Size = UDim2.new(1, 0, 0, 36)
topbarContainer.Visible = true
topbarContainer.ZIndex = 1
topbarContainer.Parent = topbarGui

local iconTemplate = Instance.new("ImageButton")
iconTemplate.BackgroundTransparency = 1
iconTemplate.Name = "_IconTemplate"
iconTemplate.Position = UDim2.new(0, 104, 0, 4)
iconTemplate.Size = UDim2.new(0, 32, 0, 32)
iconTemplate.Visible = false
iconTemplate.ZIndex = 2
iconTemplate.Image = "http://www.roblox.com/asset/?id=4871650602"
iconTemplate.ImageTransparency = 0.3
iconTemplate.ImageColor3 = Color3.fromRGB(31, 33, 35)
iconTemplate.ScaleType = Enum.ScaleType.Stretch
iconTemplate.Parent = topbarContainer

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
iconImage.Parent = iconTemplate

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
notification.Parent = iconTemplate

local textLabel = Instance.new("TextLabel")
textLabel.BackgroundTransparency = 1
textLabel.Name = "TextLabel"
textLabel.Position = UDim2.new(0.25, 0, 0.15, 0)
textLabel.Size = UDim2.new(0.5, 0, 0.7, 0)
textLabel.Visible = true
textLabel.ZIndex = 5
textLabel.Font = Enum.Font.Arial
textLabel.Text = "0"
textLabel.TextColor3 = Color3.fromRGB(31, 33, 35)
textLabel.TextScaled = true
textLabel.Parent = notification



-- PARENT OBJECTS ACCORDINGLY
for _, plr in pairs(players:GetPlayers()) do
	topbarGui:Clone().Parent = plr.PlayerGui
end
topbarGui.Parent = starterGui

local clientContainer = Instance.new("Folder")
clientContainer.Name = "Topbar+"
for a,b in pairs(script:GetChildren()) do
	b.Parent = clientContainer
end
clientContainer.Parent = replicatedStorage
print("Test 9005")


return true