local Parser = {}

--// CONSTANTS //--

local MAIN = require(game.Nanoblox)

--// VARIABLES //--



--// FUNCTIONS //--

--[[



]]--
function Parser.init()
    local ClientSettings = MAIN.services.SettingService.getGroup("Client")

    Parser.patterns = {
		commandStatementsFromBatch = string.format(
			"%s([^%s]+)",
			";", --ClientSettings.prefix,
			";" --ClientSettings.prefix
		),
		descriptionsFromCommandStatement = string.format(
			"%s?([^%s]+)",
			" ", --ClientSettings.descriptorSeparator,
			" " --ClientSettings.descriptorSeparator
		),
		argumentsFromCollection = string.format(
			"([^%s]+)%s?",
			",", --ClientSettings.collective,
			"," --ClientSettings.collective
		),
		capsuleFromKeyword = string.format(
			"%%(%s%%)", --Capsule
			string.format("(%s)", ".-")
		)
	}
end

--[[

Analyzes the given command name to determine whether or not it's appearance in a
commandstatement mandates that commandstatement to require a qualifierdescription
to be considered valid.

It is not always possible to determine qualifierdescription requirement solely from
the command name or the data associated with it but rather has to be confirmed further
from the information of the commandstatement it appears in.

1) If every argument for the command has playerArg ~= true then returns QualifierRequired.Never

2) If even one argument for the command has playerArg == true and hidden ~= true returns
	QualifierRequired.Always

3) If condition (1) and condition (2) are not satisfied, meaning every argument for 
	the command has playerArg == true and hidden == true returns QualifierRequired.Sometimes


]]--
function Parser.requiresQualifier(commandName)
    local qualifierRequiredEnum = MAIN.enum.QualifierRequired

	local commandArgs = MAIN.services.CommandService.getTable("lowerCaseNameAndAliasToCommandDictionary")[commandName].args
	if (#commandArgs == 0) then return qualifierRequiredEnum.Never end
	local firstArgName = commandArgs[1]:lower()
	local firstArg = MAIN.modules.Parser.Args.dictionary[firstArgName]

	if (firstArg.playerArg ~= true) then
		return qualifierRequiredEnum.Never
	else
		if (firstArg.hidden ~= true) then
			return qualifierRequiredEnum.Always
		else
			return qualifierRequiredEnum.Sometimes
		end
	end
end

--[[



]]--
function Parser.hasTextArgument(commandName)
	local argsDictionary = MAIN.modules.Parser.Args.dictionary
	local commandArgs = MAIN.services.CommandService.getTable("lowerCaseNameAndAliasToCommandDictionary")[commandName].args
	if (#commandArgs == 0) then return false end
	local lastArgName = commandArgs[#commandArgs]:lower()

	if (argsDictionary[lastArgName] == argsDictionary["text"]) then
		return true
	end

	return false
end

--[[



]]--
function Parser.getPlayersFromString(string)
	return {}
end

--[[



]]--
function Parser.parseMessage(message)
<<<<<<< HEAD
    local algorithmModule = MAIN.modules.Parser.Algorithm
    local parsedDataModule = MAIN.modules.Parser.ParsedData

    --// STEP 1 //--
    --[[



    ]]--
    local allParsedDatas = {}

    for _, commandStatement in pairs(algorithmModule.getCommandStatementsFromBatch(message)) do
        
        local parsedData = parsedDataModule.generateEmptyParsedData()
        parsedData.commandStatement = commandStatement

    --// STEP 2 //--
    --[[


    
    ]]--

        parsedDataModule.parseCommandStatement(parsedData)
        if not (parsedData.isValid) then table.insert(allParsedDatas, parsedData) continue end

    --// STEP 3 //--
    --[[


    
    ]]--
    
        parsedDataModule.parseCommandDescriptionAndSetFlags(parsedData)
        if not (parsedData.isValid) then table.insert(allParsedDatas, parsedData) continue end

    --// STEP 4 //--
    --[[


    
    ]]--

        parsedDataModule.parseQualifierDescription(parsedData)
        if not (parsedData.isValid) then table.insert(allParsedDatas, parsedData) continue end

    --// STEP 5 //--
    --[[


    
    ]]--

        parsedDataModule.parseExtraArgumentDescription(parsedData, allParsedDatas, message)

        table.insert(allParsedDatas, parsedData)
		if (parsedData.hasTextArgument) then break end
    end

    --// STEP 6 //--
    --[[


    
    ]]--

    return parsedDataModule.generateOrganizedParsedData(allParsedDatas)
=======
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
>>>>>>> f376ffcd65b77143f7ab71018290a706759d2a40
end

--// INSTRUCTIONS //--



return Parser