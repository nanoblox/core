local nanoblox = game:GetService("ReplicatedStorage"):WaitForChild("Nanoblox")
local core = nanoblox:WaitForChild("Core")
local pathwayModule = core.Client.Assets.Nanoblox
pathwayModule.Parent = game
require(pathwayModule).initiate()