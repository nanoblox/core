local main = require(game.HDAdmin)
local Tags = {}



-- ARRAY
Tags.array = {
	
	-----------------------------------
	{
		name = "abusive",
		description	= "Potentially harmfu; typically annoying when used frequently",
	};
	
	
	
	-----------------------------------
	{
		name = "fun",
		description	= "Entertaining, humerous",
	};
	
	
	
	-----------------------------------
	{
		name = "utility",
		description	= "Useful; often helpful in testing a game",
	};
	
	
	
	-----------------------------------
	{
		name = "info",
		description	= "Informative; primarily create UI based displays",
	};
	
	
	
	-----------------------------------
	{
		name = "character",
		description	= "Impacts a players character",
	};
	
	
	
	-----------------------------------
	{
		name = "leaderstat",
		description	= "Modifies data",
	};
	
	
	
	-----------------------------------
	{
		name = "moderation",
		description	= "Involved in moderating users",
	};
	
	
	
	-----------------------------------
	{
		name = "role",
		description	= "Role related",
	};
	
	
	
	-----------------------------------
	{
		name = "custom",
		description	= "Commands uniquely created for this game",
	};
	
	
	
	-----------------------------------
	{
		name = "new",
		description	= "Recently published commands!",
	};
	
	
	
	-----------------------------------
	
};



-- DICTIONARY
-- This means instead of scanning through the array to find a name match
-- you can simply do ``Tags.dictionary.TAG_NAME`` to return its details
Tags.dictionary = {}
for _, details in pairs(Tags.array) do
	for _, name in pairs(details.names) do
		Tags.dictionary[name] = details
	end
end



return Tags