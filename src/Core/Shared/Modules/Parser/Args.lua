local main = require(game.Nanoblox)
local Args = {}



-- ARRAY
Args.array = {
	
	-----------------------------------
	{
		name = "player",
		aliases = {},
		description	= "",
		defaultValue = 0,
		playerArg = true,
		executeForEachPlayer = true,
		parse = function(self, qualifiers)
			local targetsDict = {}
			for qualifierName, qualifierArgs in pairs(qualifiers or {}) do
				local targets = main.modules.Qualifiers.dictionary[qualifierName]
				for _, plr in pairs(targets) do
					targetsDict[plr] = true
				end
			end
			local players = {}
			for plr, _ in pairs(targetsDict) do
				table.insert(players, plr)
			end
			return players
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "players",
		aliases = {},
		description	= "",
		defaultValue = 0,
		playerArg = true,
		executeForEachPlayer = false,
		parse = function(self, qualifiers)
			return main.modules.Args.dictionary.player:parse(qualifiers)
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "optionalplayer",
		aliases = {},
		description	= "Hides the players argument for general use and only displays it within the preview menu.",
		defaultValue = 0,
		playerArg = true,
		hidden = true,
		executeForEachPlayer = true,
		parse = function(self, qualifiers)
			local defaultToAll = qualifiers == nil or main.modules.TableUtil.isEmpty(self.qualifiers)
			if defaultToAll then
				return main.Players:GetPlayers()
			end
			return main.modules.Args.dictionary.player:parse(qualifiers)
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "optionalplayers",
		aliases = {},
		description	= "Hides the players argument for general use and only displays it within the preview menu.",
		defaultValue = 0,
		playerArg = true,
		hidden = true,
		executeForEachPlayer = false,
		parse = function(self, qualifiers)
			return main.modules.Args.dictionary.optionalplayer:parse(qualifiers)
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "text",
		aliases = {"string", "reason", "question", "teamname"},
		description	= "",
		defaultValue = 0,
		filterText = true,
		parse = function(self, stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "code",
		aliases = {"lua"},
		description	= "",
		defaultValue = 0,
		parse = function(self, stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "number",
		aliases = {"integer", "studs", "speed", "intensity"},
		description	= "",
		defaultValue = 0,
		parse = function(self, stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "soundid", -- consider blocking soundids and a setting to achieve this
		aliases = {"musicid"},
		description	= "",
		defaultValue = 0,
		parse = function(self, stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "duration", -- returns the time string (such as 5s7d8h) in seconds
		aliases = {"time", "durationtime", "timelength"},
		description	= "",
		defaultValue = 0,
		parse = function(self, stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "degrees",
		aliases = {},
		description	= "",
		defaultValue = 180,
		parse = function(self, stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "role",
		aliases = {},
		description	= "",
		defaultValue = 0,
		parse = function(self, stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "color",
		aliases = {"colour", "color3", "uigradient", "colorgradient", "gradient"},
		description	= "",
		defaultValue = 0,
		parse = function(self, stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "optionalcolor",
		aliases = {"optionalcolour", "optionalcolor3"},
		description	= "",
		defaultValue = 0,
		hidden = true,
		parse = function(self, stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "bool",
		aliases = {"boolean", "trueOrFalse", "yesOrNo"},
		description	= "",
		defaultValue = 0,
		parse = function(self, stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "stat", -- Consider making a setting to update this or set its pathway
		aliases = {"statName"},
		description	= "",
		defaultValue = 0,
		parse = function(self, stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "scale", -- Consider scale limits
		aliases = {},
		description	= "",
		defaultValue = 0,
		parse = function(self, stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "gearId", -- Consider gear limits
		aliases = {},
		description	= "",
		defaultValue = 0,
		parse = function(self, stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "user",
		aliases = {"username", "userid", "playerid", "playername"},
		description	= "",
		defaultValue = 0,
		parse = function(self, stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "playerOrUser", -- returns a string instead of a player instance - it fist looks for a player in the server otherwise defaults to the given string
		aliases = {},
		description	= "",
		defaultValue = 0,
		parse = function(self, stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "team",
		aliases = {},
		description	= "",
		defaultValue = 0,
		parse = function(self, stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "teamcolor",
		aliases = {},
		description	= "",
		defaultValue = 0,
		parse = function(self, stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "material",
		aliases = {},
		description	= "",
		defaultValue = 0,
		parse = function(self, stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "tool",
		aliases = {"gear", "item"},
		description	= "",
		defaultValue = 0,
		parse = function(self, stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "morph",
		aliases = {},
		description	= "",
		defaultValue = 0,
		parse = function(self, stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	
};



-- DICTIONARY
-- This means instead of scanning through the array to find a name match
-- you can simply do ``Args.dictionary.ARGUMENT_NAME`` to return its item
Args.dictionary = {}
for _, item in pairs(Args.array) do
	Args.dictionary[item.name:lower()] = item
	for _, alias in pairs(item.aliases) do
		Args.dictionary[alias:lower()] = item
	end
end



-- SORTED ARRAY(S)
Args.executeForEachPlayerArgsDictionary = {}
for _, item in pairs(Args.array) do
	if item.playerArg and item.executeForEachPlayer then
		Args.executeForEachPlayerArgsDictionary[item.name:lower()] = true
	end
end



return Args