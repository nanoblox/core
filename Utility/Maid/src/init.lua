local DirectoryService = require(4926442976)
local Promise = require(5091723186)
local maid = script.Maid
DirectoryService:createDirectory("ReplicatedStorage.HDAdmin", {maid})
return require(maid)