local ServerStorage = game:GetService("ServerStorage")
local DataStorePlus = ServerStorage.HDAdmin["DataStore+"]
local UserStore = require(DataStorePlus.UserStore)
local PlayerStore = UserStore.new("HDAdmin 0001")
return PlayerStore--]]