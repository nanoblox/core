-- LOCAL
local main = require(game.HDAdmin)
local Parser = {}



-- METHODS
function Parser.parseMessage(message)
	-- You are welcome to split this method into submethods to achieve
	-- the final parsed result (i.e. an array of parsed batches)
	-- The following examples below demonstrate how to reference data,
	-- such as role and settings values, with V3. To view a records default values,
	-- either load up 'Config' (under HDAdmin.Core.Config) the values
	-- within a services .generateRecord method
	
	-- Data grabber examples to help you with the parser:
	local commandRecord = main.services.CommandService:getRecord("commandName")
	local commandRecords = main.services.CommandService:getAllRecords()
	local clientSettings = main.services.SettingsService:getRecord("Client")
	local prefixes = clientSettings.prefixes
	local collective = clientSettings.collective
	local spaceSeparator = clientSettings.spaceSeparator
	local Args = main.modules.Parser.Args
	local argsDictionary = Args.dictionary
	local Modifiers = main.modules.Parser.Modifiers
	local modifiersDictionary = Modifiers.dictionary
	local Qualifiers = main.modules.Parser.Qualifiers
	local qualifiersDictionary = Qualifiers.dictionary
end



return Parser