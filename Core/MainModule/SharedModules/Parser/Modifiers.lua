local main = require(game.HDAdmin)
local Modifiers = {}



-- ARRAY
Modifiers.array = {
	
	-----------------------------------
	{
		names = {"loop", "repeat", "l-"},
		description	= "",
		action = function(iterations, reiterateDelayAmount)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"global", "g-"},
		description	= "",
		action = function()
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"delay", "d-"},
		description	= "",
		action = function(delayAmount)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"epoch", "e-"},
		description	= "",
		action = function(executionTime)
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"preview", "p-"},
		description	= "",
		action = function()
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"spawn", "s-"},
		description	= "",
		action = function()
			
		end,
	};
	
	
	
	-----------------------------------
	{
		names = {"random", "r-"},
		description	= "",
		action = function()
			
		end,
	};
	
	
	
	-----------------------------------
	
};



-- DICTIONARY
-- This means instead of scanning through the array to find a name match
-- you can simply do ``Modifiers.dictionary.MODIFIER_NAME`` to return its details
Modifiers.dictionary = {}
for _, details in pairs(Modifiers.array) do
	for _, name in pairs(details.names) do
		Modifiers.dictionary[name] = details
	end
end



return Modifiers