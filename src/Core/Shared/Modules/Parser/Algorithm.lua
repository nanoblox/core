local Algorithm = {}

--// CONSTANTS //--

local MAIN = require(game.Nanoblox)

--// VARIABLES //--

--// FUNCTIONS //--

--[[



]]
function Algorithm.getCommandStatementsFromBatch(batch)
	local parserModule = MAIN.modules.Parser
	local utilityModule = MAIN.modules.Parser.Utility

	return utilityModule.getMatches(batch, parserModule.patterns.commandStatementsFromBatch)
end

--[[



]]
function Algorithm.getDescriptionsFromCommandStatement(commandStatement)
	local parserModule = MAIN.modules.Parser
	local utilityModule = MAIN.modules.Parser.Utility

	local descriptions =
		utilityModule.getMatches(commandStatement, parserModule.patterns.descriptionsFromCommandStatement)

	local extraArgumentDescription = {}
	if (#descriptions >= 3) then
		for counter = 3, #descriptions do
			table.insert(extraArgumentDescription, descriptions[counter])
		end
	end

	return {
		descriptions[1] or "",
		descriptions[2] or "",
		extraArgumentDescription,
	}
end

--[[



]]
function Algorithm.parseCommandDescription(commandDescription)
	local utilityModule = MAIN.modules.Parser.Utility

	local commandCaptures, commandDescriptionResidue =
		utilityModule.getCaptures(commandDescription, MAIN.services.CommandService.getTable("sortedNameAndAliasLengthArray"))
	local modifierCaptures, commandDescriptionResidue =
		utilityModule.getCaptures(commandDescriptionResidue, MAIN.modules.Parser.Modifiers.sortedNameAndAliasLengthArray)

	return {
		commandCaptures,
		modifierCaptures,
		commandDescriptionResidue,
	}
end

--[[



]]
function Algorithm.parseQualifierDescription(qualifierDescription)
	local parserModule = MAIN.modules.Parser
	local utilityModule = MAIN.modules.Parser.Utility

	local qualifierCaptures, qualifierDescriptionResidue =
		utilityModule.getCaptures(qualifierDescription, MAIN.modules.Parser.Qualifiers.sortedNameAndAliasLengthArray)

	local unrecognizedQualifiers =
		utilityModule.getMatches(qualifierDescriptionResidue, parserModule.patterns.argumentsFromCollection)

	for _, match in pairs(unrecognizedQualifiers) do
		if (match ~= "") then
			table.insert(qualifierCaptures, { [match] = {} })
		end
	end

	return {
		qualifierCaptures,
		unrecognizedQualifiers,
	}
end

--[[



]]
function Algorithm.parseExtraArgumentDescription(extraArgumentDescription)
end

--// INSTRUCTIONS //--

return Algorithm
