local Algorithm = {}

--// CONSTANTS //--

local MAIN = require(game.HDAdmin)

--// VARIABLES //--

--[[

]]--
function Algorithm.getCommandStatementsFromBatch(batch)
    local parser = MAIN.modules.Parser
    local utility = MAIN.modules.Parser.Utility

	return utility.getMatches(batch, parser.patterns.CommandStatementsFromBatch)
end

function Algorithm.getDescriptionsFromCommandStatement(commandStatement)
    local parser = MAIN.modules.Parser
    local utility = MAIN.modules.Parser.Utility

	local descriptions = utility.getMatches(commandStatement, parser.patterns.DescriptionsFromCommandStatement)
	
	local extraArgumentDescription = {}
	if (#descriptions >= 3) then
		for counter = 3, #descriptions do
			table.insert(extraArgumentDescription, descriptions[counter])
		end
	end
	
    return descriptions[1] or "", descriptions[2] or "", extraArgumentDescription
end

--[[

]]--
function Algorithm.parseCommandDescription(commandDescription)
    local utility = MAIN.modules.Parser.Utility

	local commandCaptures, commandDescriptionResidue = utility.getCaptures(
		commandDescription, 
		MAIN.services.CommandService.getTable("sortedNameAndAliasLengthArray")
	)
	local modifierCaptures, commandDescriptionResidue = utility.getCaptures(
		commandDescriptionResidue,
		MAIN.modules.Parser.Modifiers.sortedNameAndAliasLengthArray
	)

    return commandCaptures, modifierCaptures, commandDescriptionResidue
end

--[[

]]--
function Algorithm.parseQualifierDescription(qualifierDescription)
    local parser = MAIN.modules.Parser
    local utility = MAIN.modules.Parser.Utility

	local qualifierCaptures, qualifierDescriptionResidue = utility.getCaptures(
		qualifierDescription,
		MAIN.modules.Parser.Qualifiers.sortedNameAndAliasLengthArray
	)

	--// Unrecognized qualifiers that could not have been identifiers
	local unrecognizedQualifier = string.match(
		qualifierDescriptionResidue,
		string.format("(.-)%s", parser.patterns.CapsuleFromKeyword)
	)
	if (unrecognizedQualifier ~= nil) then
		return nil
	end

	--// Unrecognized qualifiers that are identifiers
	for _, match in pairs(utility.getMatches(qualifierDescriptionResidue, parser.patterns.ArgumentsFromCollection)) do
		if (match ~= "") then
			table.insert(qualifierCaptures, {[match] = {}})
		end
	end

	return qualifierCaptures
end

--[[

]]--
function Algorithm.parseExtraArgumentDescription(parsedDataTable, parsedDataTables, message)
	if not (parsedDataTable.HasTextArgument) then
		if not (parsedDataTable.RequiresQualifier) then
			table.insert(parsedDataTable.ExtraArgumentDescription, 1, parsedDataTable.QualifierDescription)
			parsedDataTable.QualifierDescription = ""
		end

		for _, extraArgument in pairs(parsedDataTable.ExtraArgumentDescription) do
			for _, capture in pairs(parsedDataTable.CommandCaptures) do
				for _, arguments in pairs(capture) do
					table.insert(arguments, extraArgument)
				end
			end
		end
	else
		local foundIndex = 0

		for counter = 1, #parsedDataTables + 1 do
			foundIndex = select(2, string.find(message, ";", foundIndex + 1))
		end

		foundIndex = select(2, string.find(message, parsedDataTable.CommandDescription, foundIndex + 1, true)) + 2

		if (parsedDataTable.RequiresQualifier) then
			foundIndex = select(2, string.find(message, parsedDataTable.QualifierDescription, foundIndex, true)) + 2
		end

		local extraArgument = string.sub(message, foundIndex)
		for _, capture in pairs(parsedDataTable.CommandCaptures) do
			for _, arguments in pairs(capture) do
				table.insert(arguments, extraArgument)
			end
		end
	end
end

--// INSTRUCTIONS //--



return Algorithm