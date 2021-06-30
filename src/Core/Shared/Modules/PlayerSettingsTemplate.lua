-- These are located within a Shared module so that the client can access the default values instantly too
local main = require(game.Nanoblox)

local playerSettings = {
	prefixes = {";"},
	argCapsule = "(%s)",
	collective = ",",
	descriptorSeparator = "",
	spaceSeparator = " ",
	batchSeparator = " ",
	
	playerIdentifier = "@",
	playerUndefinedSearch = main.enum.PlayerSearch.DisplayName, -- 'Undefined' means *without* the 'playerIdentifier' (e.g. ";kill Ben)
	playerDefinedSearch = main.enum.PlayerSearch.UserName, -- 'Defined' means *with* the 'playerIdentifier' (e.g. ";kill @ForeverHD)

	previewIncompleteCommands = false,
	
	theme = "",
	backgroundTransparency 	= 0.1,

	soundProperties = {
		Volume = {
			Music = 1,
			Command = 1,
			Interface = 1,
		},
		Pitch = {
			Music = 1,
			Command = 1,
			Interface = 1,
		},
	}
}

return playerSettings