local DirectoryService = require(4926442976)
local signal = script.Signal
DirectoryService:createDirectory("ReplicatedStorage.HDAdmin", {signal})
return require(signal)