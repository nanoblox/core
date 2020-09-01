local hdadmin = game:GetService("ReplicatedStorage"):WaitForChild("HDAdmin")
local core = hdadmin:WaitForChild("Core")
local pathwayModule = core.Client.Assets.HDAdmin
pathwayModule.Parent = game
require(pathwayModule):initiate()