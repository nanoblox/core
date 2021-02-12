local ParsedData = {}

--// CONSTANTS //--

local MAIN = require(game.HDAdmin)

ParsedData.REJECTIONS = {
	MISSING_COMMAND_DESCRIPTION = 1,
	MISSING_COMMANDS = 2,
	MALFORMED_COMMAND_DESCRIPTION = 3,
	MALFORMED_QUALIFIER_DESCRIPTION = 4
}

--// VARIABLES //--



--// FUNCTIONS //--

function ParsedData.new()
    return {
        commandStatement = nil,

        commandDescription = nil,
        qualifierDescription = nil,
        extraArgumentDescription = nil,

        commandCaptures = nil,
        modifierCaptures = nil,
        qualifierCaptures = nil,

        commandDescriptionResidue = nil,
        organizedParsedData = nil,

        requiresQualifier = nil,
        hasTextArgument = nil,

        failed = nil,
        parserRejection = nil
    }
end

function ParsedData.validate(parsedDataTable, parserRejection)
	if (parserRejection == ParsedData.REJECTIONS.MISSING_COMMAND_DESCRIPTION) then
		
		if (parsedDataTable.commandDescription == "") then parsedDataTable.failed = true end
		
	elseif (parserRejection == ParsedData.REJECTIONS.MISSING_COMMANDS) then
		
		if (#parsedDataTable.commandCaptures == 0) then parsedDataTable.failed = true end
		
	elseif (parserRejection == ParsedData.REJECTIONS.MALFORMED_COMMAND_DESCRIPTION) then
		
		if (parsedDataTable.commandDescriptionResidue ~= "") then parsedDataTable.failed = true end
		
	else
		
	end
	
	if (parsedDataTable.failed) then parsedDataTable.parserRejection = parserRejection end
end

function ParsedData.generateOrganizedParsedData(parsedDataTable)
	
	local commands = {}
	for _, capture in pairs(parsedDataTable.CommandCaptures) do
		for command, arguments in pairs(capture) do
			commands[command] = arguments
		end
	end
		
	local modifiers = {}
	for _, capture in pairs(parsedDataTable.ModifierCaptures) do
		for modifier, arguments in pairs(capture) do
			modifiers[modifier] = arguments
		end
	end
	
	local qualifiers = {}
	for _, capture in pairs(parsedDataTable.QualifierCaptures) do
		for qualifier, arguments in pairs(capture) do
			qualifiers[qualifier] = arguments
		end
	end
	
	parsedDataTable.OrganizedParsedData = {
		Commands = commands,
		Modifiers = modifiers,
		Qualifiers = qualifiers
	}
end

--[[

]]--
function ParsedData.parsedDataTableRequiresQualifier(parsedDataTable)
	local parser = MAIN.modules.Parser
	local algorithm = MAIN.modules.Parser.Algorithm

	local qualifierRequiredEnums = MAIN.enum.QualifierRequired
	local parsedDataTableRequiresQualifier = nil

	for _, capture in pairs(parsedDataTable.CommandCaptures) do
		for commandName, _ in pairs(capture) do
			local requiresQualifier = parser.requiresQualifier(commandName)
			if (requiresQualifier == qualifierRequiredEnums.Always) then
				parsedDataTableRequiresQualifier = qualifierRequiredEnums.Always
				break
			elseif (requiresQualifier == qualifierRequiredEnums.Never) then
				parsedDataTableRequiresQualifier = qualifierRequiredEnums.Never
			end
		end
	end

	if (parsedDataTableRequiresQualifier == nil) then
		parsedDataTableRequiresQualifier = qualifierRequiredEnums.Sometimes
	end

	if (parsedDataTableRequiresQualifier == qualifierRequiredEnums.Sometimes) then

		parsedDataTable.requiresQualifier = true
		local qualifierCaptures = algorithm.parseQualifierDescription(parsedDataTable).qualifierCaptures

		if (qualifierCaptures == nil) then
			return false
		else
			local playerNames = {}
			for _, player in pairs(game:GetService("Players"):GetPlayers()) do
				table.insert(playerNames, player.Name:lower())
			end

			for _, capture in pairs(qualifierCaptures) do
				for qualifier, _ in pairs(capture) do
					if (table.find(MAIN.modules.Parser.Qualifiers.sortedNameAndAliasLengthArray, qualifier:lower())) or 
						(table.find(playerNames, qualifier:lower())) 
					then
						return true
					end
				end
			end

			return false
		end
	else
		return (parsedDataTableRequiresQualifier == qualifierRequiredEnums.Always)
	end
end

--[[

]]--
function ParsedData.parsedDataTableHasTextArgument(parsedDataTable)
    local parser = MAIN.modules.Parser

	for _, capture in pairs(parsedDataTable.CommandCaptures) do
		for command, _ in pairs(capture) do
			if (parser.hasTextArgument(command)) then
				return true
			end
		end
	end
	return false
end

return ParsedData