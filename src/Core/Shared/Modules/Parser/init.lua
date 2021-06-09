local Parser = {}

--// CONSTANTS //--

local MAIN = require(game.Nanoblox)

--// VARIABLES //--

--// FUNCTIONS //--

--[[



]]
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
		),
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


]]
function Parser.requiresQualifier(commandName)
	local qualifierRequiredEnum = MAIN.enum.QualifierRequired

	local commandArgs =
		MAIN.services.CommandService.getTable("lowerCaseNameAndAliasToCommandDictionary")[commandName].args
	if #commandArgs == 0 then
		return qualifierRequiredEnum.Never
	end
	local firstArgName = commandArgs[1]:lower()
	local firstArg = MAIN.modules.Parser.Args.get(firstArgName)

	if firstArg.playerArg ~= true then
		return qualifierRequiredEnum.Never
	else
		if firstArg.hidden ~= true then
			return qualifierRequiredEnum.Always
		else
			return qualifierRequiredEnum.Sometimes
		end
	end
end

--[[



]]
function Parser.hasEndlessArgument(commandName)
	local argsDictionary = MAIN.modules.Parser.Args.dictionary
	local commandArgs =
		MAIN.services.CommandService.getTable("lowerCaseNameAndAliasToCommandDictionary")[commandName].args
	if #commandArgs == 0 then
		return false
	end
	local lastArgName = commandArgs[#commandArgs]:lower()
	local lastArg = argsDictionary[lastArgName]

	return lastArg and lastArg.endlessArg == true
end

--[[



]]
function Parser.getPlayersFromString(playerString, optionalUser)
	local selectedPlayers = {}
	local utilityModule = MAIN.modules.Parser.Utility
	local settingService = MAIN.services.SettingService
	local playerSearchEnums = MAIN.enum.PlayerSearch
	local players = game:GetService("Players"):GetPlayers()

	local playerIdentifier = settingService.getPlayerSetting("playerIdentifier", optionalUser)
	local playerDefinedSearch = settingService.getPlayerSetting("playerDefinedSearch", optionalUser)
	local playerUndefinedSearch = settingService.getPlayerSetting("playerUndefinedSearch", optionalUser)

	local hasPlayerIdentifier = (playerString:sub(1, 1) == playerIdentifier)
	local playerStringWithoutIdentifier = utilityModule.ternary(
		hasPlayerIdentifier,
		playerString:sub(2, #playerString),
		playerString
	)

	local isUserNameSearch = utilityModule.ternary(
		hasPlayerIdentifier,
		playerDefinedSearch == playerSearchEnums.UserName,
		playerUndefinedSearch == playerSearchEnums.UserName
	)
	local isDisplayNameSearch = utilityModule.ternary(
		hasPlayerIdentifier,
		playerDefinedSearch == playerSearchEnums.DisplayName,
		playerUndefinedSearch == playerSearchEnums.DisplayName
	)
	local isUserNameAndDisplayNameSearch = utilityModule.ternary(
		hasPlayerIdentifier,
		playerDefinedSearch == playerSearchEnums.UserNameAndDisplayName,
		playerUndefinedSearch == playerSearchEnums.UserNameAndDisplayName
	)
	
	if isUserNameSearch or isUserNameAndDisplayNameSearch then
		for _, player in pairs(players) do
			if string.find(player.Name, playerStringWithoutIdentifier) == 1 then
				if table.find(selectedPlayers, player) == nil then
					table.insert(selectedPlayers, player)
				end
			end
		end
	end

	if isDisplayNameSearch or isUserNameAndDisplayNameSearch then
		for _, player in pairs(players) do
			if string.find(player.DisplayName, playerStringWithoutIdentifier) == 1 then
				if table.find(selectedPlayers, player) == nil then
					table.insert(selectedPlayers, player)
				end
			end
		end
	end

	return selectedPlayers
end

--[[



]]
function Parser.parseMessage(message, optionalUser)
	local algorithmModule = MAIN.modules.Parser.Algorithm
	local parsedDataModule = MAIN.modules.Parser.ParsedData

	--// STEP 1 //--
	--[[



    ]]
	local allParsedDatas = {}

	for _, commandStatement in pairs(algorithmModule.getCommandStatementsFromBatch(message)) do
		local parsedData = parsedDataModule.generateEmptyParsedData()
		parsedData.commandStatement = commandStatement

		--// STEP 2 //--
		--[[



    ]]

		parsedDataModule.parseCommandStatement(parsedData)
		if not parsedData.isValid then
			table.insert(allParsedDatas, parsedData)
			continue
		end

		--// STEP 3 //--
		--[[



    ]]

		parsedDataModule.parseCommandDescriptionAndSetFlags(parsedData, optionalUser)
		if not parsedData.isValid then
			table.insert(allParsedDatas, parsedData)
			continue
		end

		--// STEP 4 //--
		--[[



    ]]

		parsedDataModule.parseQualifierDescription(parsedData)
		if not parsedData.isValid then
			table.insert(allParsedDatas, parsedData)
			continue
		end

		--// STEP 5 //--
		--[[



    ]]

		parsedDataModule.parseExtraArgumentDescription(parsedData, allParsedDatas, message)

		table.insert(allParsedDatas, parsedData)
		if parsedData.hasTextArgument then
			break
		end
	end

	--// STEP 6 //--
	--[[



    ]]

	return parsedDataModule.generateOrganizedParsedData(allParsedDatas)
end

--// INSTRUCTIONS //--

return Parser
