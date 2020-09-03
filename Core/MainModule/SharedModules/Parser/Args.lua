local main = require(game.HDAdmin)
local Args = {}



-- ARRAY
Args.array = {
	
	-----------------------------------
	{
		names = {"player"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"players"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"optionalplayers"},
		description	= "Hides the players argument for general use and only displays it within the preview menu.",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		-- Consider filters for specific players or broadcast
		names = {"text", "string", "reason", "question", "teamname"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"code", "lua"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"number", "integer", "studs", "speed", "intensity"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"degrees"},
		description	= "",
		defaultValue = 180,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"role"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"colour", "color", "color3", "uigradient", "colorgradient", "gradient"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"bool", "boolean", "trueOrFalse", "yesOrNo"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"stat", "statName"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"scale"}, -- Consider scale limits
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"gearId"}, -- Consider gear limits
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"user", "username", "userid", "playerid", "playername"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"team"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"teamcolor"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"material"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"tool", "gear", "item"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"morph"},
		description	= "",
		defaultValue = 0,
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	
};



-- DICTIONARY
-- This means instead of scanning through the array to find a name match
-- you can simply do ``Args.dictionary.ARGUMENT_NAME`` to return its details
Args.dictionary = {}
for _, details in pairs(Args.array) do
	for _, name in pairs(details.names) do
		Args.dictionary[name] = details
	end
end



return Args