local main = require(game.Nanoblox)
local UserStore = require(main.shared.Packages.UserStore)
local dataStoreName = "NanobloxPlayerData"
local PlayerStore = UserStore.new(dataStoreName)
return PlayerStore