local main = require(game.Nanoblox)
local UserStore = require(main.shared.Packages.UserStore)
local dataStoreName = "NanobloxSystemData"
local SystemStore = UserStore.new(dataStoreName)
return SystemStore