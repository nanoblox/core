local ParsedData = {}

--// CONSTANTS //--

local MAIN = require(game.Nanoblox)

--// VARIABLES //--

--// FUNCTIONS //--

--[[



]]
function ParsedData.generateEmptyParsedData()
	return {
		commandStatement = nil,

		commandDescription = nil,
		qualifierDescription = nil,
		extraArgumentDescription = nil,

		commandCaptures = {},
		modifierCaptures = {},
		qualifierCaptures = {},
		prematureQualifierParsing = false,
		unrecognizedQualifiers = {},

		commandDescriptionResdiue = nil,

		requiresQualifier = false,
		hasTextArgument = false,

		isValid = true,
		parserRejection = nil,
	}
end

--[[



]]
function ParsedData.parsedDataSetRequiresQualifierFlag(parsedData, optionalPlayer)
	local parserModule = MAIN.modules.Parser

	local qualifierRequiredEnum = MAIN.enum.QualifierRequired
	local parsedDataRequiresQualifier = qualifierRequiredEnum.Sometimes

	for _, capture in pairs(parsedData.commandCaptures) do
		for commandName, _ in pairs(capture) do
			local commandRequiresQualifier = parserModule.requiresQualifier(commandName)
			if commandRequiresQualifier == qualifierRequiredEnum.Always then
				parsedDataRequiresQualifier = qualifierRequiredEnum.Always
				break
			elseif commandRequiresQualifier == qualifierRequiredEnum.Never then
				parsedDataRequiresQualifier = qualifierRequiredEnum.Never
			end
		end
	end

	if parsedDataRequiresQualifier ~= qualifierRequiredEnum.Sometimes then
		parsedData.requiresQualifier = (parsedDataRequiresQualifier == qualifierRequiredEnum.Always)
	else
		parsedData.requiresQualifier = true
		ParsedData.parseQualifierDescription(parsedData)
		parsedData.prematureQualifierParsing = true

		if next(parsedData.qualifiersCaptures) ~= nil then
			parsedData.requiresQualifier = true
		else
			local utilityModule = MAIN.modules.Parser.Utility
			local settingService = MAIN.services.SettingService
			local playerSearchEnums = MAIN.enums.PlayerSearch

			local players = game:GetService("Players"):GetPlayers()
			local userNames = {}
			for _, player in pairs(players) do
				table.insert(userNames, player.Name:lower())
			end

			local playerIdentifier = settingService.getPlayerSetting("playerIdentifier", optionalPlayer)
			local playerDefinedSearch = settingService.getPlayerSetting("playerDefinedSearch", optionalPlayer)
			local playerUndefinedSearch = settingService.getPlayerSetting("playerUndefinedSearch", optionalPlayer)

			for _, qualifier in pairs(parsedData.unrecognizedQualifiers) do
				local qualifierHasPlayerIdentifier = (qualifier:sub(1, 1) == playerIdentifier)
				local qualifierWithoutIdentifier = utilityModule.ternary(
					qualifierHasPlayerIdentifier,
					qualifier:sub(2, #qualifier),
					qualifier
				)

				local isUserNameSearch = utilityModule.ternary(
					qualifierHasPlayerIdentifier,
					playerDefinedSearch == playerSearchEnums.UserName,
					playerUndefinedSearch == playerSearchEnums.UserName
				)
				local isUserNameAndDisplayNameSearch = utilityModule.ternary(
					qualifierHasPlayerIdentifier,
					playerDefinedSearch == playerSearchEnums.UserNameAndDisplayName,
					playerUndefinedSearch == playerSearchEnums.UserNameAndDisplayName
				)

				if isUserNameSearch or isUserNameAndDisplayNameSearch then
					if table.find(userNames, qualifierWithoutIdentifier:lower()) then
						parsedData.requiresQualifier = true
						return
					end
				end
			end

			parsedData.requiresQualifier = false
		end
	end
end

--[[



]]
function ParsedData.parsedDataSetHasTextArgumentFlag(parsedData)
	local parserModule = MAIN.modules.Parser

	for _, capture in pairs(parsedData.commandCaptures) do
		for commandName, _ in pairs(capture) do
			if parserModule.hasTextArgument(commandName) then
				parsedData.hasTextArgument = true
				return
			end
		end
	end
	parsedData.hasTextArgument = false
end

--[[



]]
function ParsedData.parsedDataUpdateIsValidFlag(parsedData, parserRejection)
	local parserRejectionEnum = MAIN.enum.ParserRejection

	if parserRejection == parserRejectionEnum.MissingCommandDescription then
		if parsedData.commandDescription == "" then
			parsedData.isValid = false
		end
	elseif parserRejection == parserRejectionEnum.MissingCommands then
		if #parsedData.commandCaptures == 0 then
			parsedData.isValid = false
		end
	elseif parserRejection == parserRejectionEnum.MalformedCommandDescription then
		if parsedData.commandDescriptionResidue ~= "" then
			parsedData.isValid = false
		end
	end

	if not parsedData.isValid then
		parsedData.parserRejection = parserRejection
	end
end

--[[



]]
function ParsedData.generateOrganizedParsedData(allParsedData)
	local organizedData = {}
	for _, parsedData in pairs(allParsedData) do
		if parsedData.isValid then
			local commands = {}
			for _, capture in pairs(parsedData.commandCaptures) do
				for command, arguments in pairs(capture) do
					commands[command] = arguments
				end
			end

			local modifiers = {}
			for _, capture in pairs(parsedData.modifierCaptures) do
				for modifier, arguments in pairs(capture) do
					modifiers[modifier] = arguments
				end
			end

			local qualifiers = {}
			for _, capture in pairs(parsedData.qualifierCaptures) do
				for qualifier, arguments in pairs(capture) do
					qualifiers[qualifier] = arguments
				end
			end

			table.insert(organizedData, {
				commands = commands,
				modifiers = modifiers,
				qualifiers = qualifiers,
			})
		end
	end
	return organizedData
end

--[[



]]
function ParsedData.parseCommandStatement(parsedData)
	local parserRejectionEnum = MAIN.enum.ParserRejection
	local algorithmModule = MAIN.modules.Parser.Algorithm

	local descriptions = algorithmModule.getDescriptionsFromCommandStatement(parsedData.commandStatement)

	parsedData.commandDescription = descriptions[1]
	parsedData.qualifierDescription = descriptions[2]
	parsedData.extraArgumentDescription = descriptions[3]

	ParsedData.parsedDataUpdateIsValidFlag(parsedData, parserRejectionEnum.MISSING_COMMAND_DESCRIPTION)
end

--[[



]]
function ParsedData.parseCommandDescription(parsedData)
	local parserRejectionEnum = MAIN.enum.ParserRejection
	local algorithmModule = MAIN.modules.Parser.Algorithm

	local capturesAndResidue = algorithmModule.parseCommandDescription(parsedData.commandDescription)

	parsedData.commandCaptures = capturesAndResidue[1]
	parsedData.modifierCaptures = capturesAndResidue[2]
	parsedData.commandDescriptionResidue = capturesAndResidue[3]

	ParsedData.parsedDataUpdateIsValidFlag(parsedData, parserRejectionEnum.MISSING_COMMANDS)
	ParsedData.parsedDataUpdateIsValidFlag(parsedData, parserRejectionEnum.MALFORMED_COMMAND_DESCRIPTION)
end

--[[



]]
function ParsedData.parseCommandDescriptionAndSetFlags(parsedData, optionalPlayer)
	ParsedData.parseCommandDescription(parsedData)
	if parsedData.isValid then
		ParsedData.parsedDataSetRequiresQualifierFlag(parsedData, optionalPlayer)
		ParsedData.parsedDataSetHasTextArgumentFlag(parsedData)
	end
end

--[[



]]
function ParsedData.parseQualifierDescription(parsedData)
	if not parsedData.requiresQualifier then
		return
	end
	if parsedData.prematureQualifierParsing then
		return
	end

	local algorithmModule = MAIN.modules.Parser.Algorithm

	local qualifierCapturesAndUnrecognizedQualifiers =
		algorithmModule.parseQualifierDescription(parsedData.qualifierDescription)
	parsedData.qualifierCaptures = qualifierCapturesAndUnrecognizedQualifiers[1]
	parsedData.unrecognizedQualifiers = qualifierCapturesAndUnrecognizedQualifiers[2]
end

--[[



]]
function ParsedData.parseExtraArgumentDescription(parsedData, allParsedDatas, originalMessage)
	if not parsedData.hasTextArgument then
		if not parsedData.requiresQualifier then
			table.insert(parsedData.extraArgumentDescription, parsedData.qualifierDescription)
			parsedData.qualifierDescription = nil
		end

		for _, extraArgument in pairs(parsedData.extraArgumentDescription) do
			for _, capture in pairs(parsedData.commandCaptures) do
				for _, arguments in pairs(capture) do
					table.insert(arguments, extraArgument)
				end
			end
		end
	else
		local foundIndex = 0

		for counter = 1, #allParsedDatas + 1 do
			foundIndex = select(2, string.find(originalMessage, ";", foundIndex + 1))
		end

		foundIndex = select(2, string.find(originalMessage, parsedData.commandDescription, foundIndex + 1, true)) + 2

		if parsedData.requiresQualifier then
			foundIndex = select(2, string.find(originalMessage, parsedData.qualifierDescription, foundIndex, true)) + 2
		end

		local extraArgument = string.sub(originalMessage, foundIndex)
		for _, capture in pairs(parsedData.commandCaptures) do
			for _, arguments in pairs(capture) do
				table.insert(arguments, extraArgument)
			end
		end
	end
end

--// INSTRUCTIONS //--

return ParsedData
