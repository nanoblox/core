-- UTILITY
local DirectoryService = require(4926442976)


-- SETUP DIRECTORIES
local projectName = "DataStore+"
local serverDirectory = DirectoryService:createDirectory("ServerStorage.HDAdmin."..projectName, script:GetChildren())


return serverDirectory