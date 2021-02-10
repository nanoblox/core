local nanoblox = game:GetService("ReplicatedStorage"):WaitForChild("Nanoblox")
local pathwayModule = nanoblox.Shared.Assets.Nanoblox
pathwayModule.Parent = game
require(pathwayModule).initiate()