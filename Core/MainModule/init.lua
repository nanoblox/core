-- PROJECTS/UTILITY
local DataStorePlus = require(4643209210)
local TopbarPlus = require(4874365424)
local DirectoryService = require(4926442976)
local Maid = require(5086306120)
local Signal = require(4893141590)


-- SETUP INITIAL DIRECTORIES
local projectName = "Core"
local client = script.Client
local starterPlayer = client.StarterPlayer
local sharedModules = script.SharedModules
DirectoryService:createDirectory("ServerStorage.HDAdmin."..projectName, {script.Server, script.Parent.Config})
DirectoryService:createDirectory("ReplicatedStorage.HDAdmin."..projectName, {client, sharedModules})
DirectoryService:createDirectory("StarterCharacterScripts", starterPlayer.StarterCharacterScripts:GetChildren())


-- PATHWAY MODULE
local pathwayModule = client.Assets.HDAdmin:Clone()
pathwayModule.Parent = game
require(pathwayModule):initiate()


-- INITIATE CLIENT (only after the server has fully initiated)
DirectoryService:createDirectory("StarterPlayerScripts", starterPlayer.StarterPlayerScripts:GetChildren())


return true