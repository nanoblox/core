local DirectoryService = require(4926442976)
local promise = script.Promise
DirectoryService:createDirectory("ReplicatedStorage.HDAdmin", {promise})
return require(promise)