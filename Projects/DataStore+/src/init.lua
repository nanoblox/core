-- UTILITY
local DirectoryService = require(4926442976)
local Maid = require(5086306120)
local Signal = require(4893141590)


-- SETUP DIRECTORIES
local projectName = "DataStore+"
local serverDirectory = DirectoryService:createDirectory("ServerStorage.HDAdmin."..projectName, script:GetChildren())


return serverDirectory