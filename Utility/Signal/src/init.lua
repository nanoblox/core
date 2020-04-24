-- SERVICES
local players = game:GetService("Players")
local starterGui = game:GetService("StarterGui")
local replicatedStorage = game:GetService("ReplicatedStorage")
local DirectoryService = require(4926442976)



-- SETUP DIRECTORIES
local signal = script.Signal
DirectoryService:createDirectory("ReplicatedStorage.HDAdmin", {signal})



return require(signal)