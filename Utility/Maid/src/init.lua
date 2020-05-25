-- test automation (1)
local DirectoryService = require(4926442976)
local maid = script.Maid
DirectoryService:createDirectory("ReplicatedStorage.HDAdmin", {maid})
return require(maid)