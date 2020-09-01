local main = require(game.HDAdmin)
local Qualifiers = {}



-- ARRAY
Qualifiers.array = {
	
	-----------------------------------
	{
		names = {"_user"},
		description	= "Default action, returns any players with matching beginning names or userids",
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"me", "you"},
		description	= "",
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"all", "everyone"},
		description	= "",
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"random"},
		description	= "",
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"others"},
		description	= "",
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"team-%s", "$%s"},
		description	= "",
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"role-%s", "@%s"},
		description	= "",
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"percent-%s", "percentage-%s", "%s%"},
		description	= "",
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"admins"},
		description	= "",
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"nonadmins"},
		description	= "",
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"premium", "prem"},
		description	= "",
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"friends"},
		description	= "",
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"nonfriends"},
		description	= "",
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"r6"},
		description	= "",
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"r15"},
		description	= "",
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"rthro"},
		description	= "",
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"nonrthro"},
		description	= "",
		parse = function(stringToParse)
			
		end,
	};
	
	
	
	-----------------------------------
	
};



-- DICTIONARY
-- This means instead of scanning through the array to find a name match
-- you can simply do ``Qualifiers.dictionary.QUALIFIER_NAME`` to return its details
Qualifiers.dictionary = {}
for _, details in pairs(Qualifiers.array) do
	for _, name in pairs(details.names) do
		Qualifiers.dictionary[name] = details
	end
end



return Qualifiers