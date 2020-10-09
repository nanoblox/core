local main = require(game.HDAdmin)
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
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "players",
		aliases = {},
		description	= "",
		defaultValue = 0,
		playerArg = true,
		parse = function(stringToParse)
			
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
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		-- Consider filters for specific players or broadcast
		name = "text",
		aliases = {"string", "reason", "question", "teamname"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "code",
		aliases = {"lua"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "number",
		aliases = {"integer", "studs", "speed", "intensity"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "degrees",
		aliases = {},
		description	= "",
		defaultValue = 180,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "role",
		aliases = {},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "color",
		aliases = {"colour", "color3", "uigradient", "colorgradient", "gradient"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "bool",
		aliases = {"boolean", "trueOrFalse", "yesOrNo"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "stat",
		aliases = {"statName"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "scale", -- Consider scale limits
		aliases = {},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "gearId", -- Consider gear limits
		aliases = {},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "user",
		aliases = {"username", "userid", "playerid", "playername"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "team",
		aliases = {},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "teamcolor",
		aliases = {},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "material",
		aliases = {},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "tool",
		aliases = {"gear", "item"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		name = "morph",
		aliases = {},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	
};



-- DICTIONARY
-- This means instead of scanning through the array to find a name match
-- you can simply do ``Args.dictionary.ARGUMENT_NAME`` to return its item
Args.dictionary = {}
for _, item in pairs(Args.array) do
	Args.dictionary[item.name] = item
	for _, alias in pairs(item.aliases) do
		Args.dictionary[alias] = item
	end
end



-- SORTED ARRAY(S)
Args.playerArgsWithoutHiddenDictionary = {}
for _, item in pairs(Args.array) do
	if item.playerArg and not item.hidden then
		Args.playerArgsWithoutHiddenDictionary[item.name] = true
	end
end



return Args