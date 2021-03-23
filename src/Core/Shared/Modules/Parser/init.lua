-- LOCAL
local main = require(game.Nanoblox)
local Parser = {}



-- METHODS
function Parser.parseMessage(message)
	-- You are welcome to split this method into submethods to achieve
	-- the final parsed result (i.e. a batch containing an array of statements)
	-- The following examples below demonstrate how to reference data,
	-- such as role and settings values, with V3. To view a records default values,
	-- either load up 'Config' (under Nanoblox.Core.Config) the values
	-- within a services .generateRecord method
	
	-- Data grabber examples to help you with the parser:
	local CommandService = (main.isServer and main.services.CommandService) or main.controllers.CommandController
	local commandRecord = CommandService.getCommand("commandName")
	local commandRecords = CommandService.getCommands()
	local commandNameOrAliasToRecordDictionary = CommandService.getTable("dictionary")
	local commandRecordsSortedByNameLength = CommandService.getTable("sortedNameAndAliasLengthArray")
	local SettingService = (main.isServer and main.services.SettingService) or main.controllers.SettingController
	local playerSettings = SettingService.getGroup("Player")
	local prefixes = playerSettings.prefixes
	local collective = playerSettings.collective
	local spaceSeparator = playerSettings.spaceSeparator
	local Args = main.modules.Parser.Args
	local argsDictionary = Args.dictionary
	local Modifiers = main.modules.Parser.Modifiers
	local modifiersDictionary = Modifiers.dictionary
	local modifiersSortedArray = Modifiers.sortedNameAndAliasLengthArray
	local Qualifiers = main.modules.Parser.Qualifiers
	local qualifiersDictionary = Qualifiers.dictionary
	print(commandRecords)
	print(commandRecordsSortedByNameLength)

	local batch = {test345 = true}
	return batch
end


return Parser