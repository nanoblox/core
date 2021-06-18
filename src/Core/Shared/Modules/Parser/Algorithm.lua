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

	local descriptions = utilityModule.getMatches(
		commandStatement,
		parserModule.patterns.descriptionsFromCommandStatement
	)

	local extraArgumentDescription = {}
	if #descriptions >= 3 then
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

	local commandCapsuleCaptures, commandDescriptionResidue = utilityModule.getCapsuleCaptures(
		commandDescription,
		MAIN.services.CommandService.getTable("sortedNameAndAliasLengthArray")
	)
	local commandPlainCaptures, commandDescriptionResidue = utilityModule.getPlainCaptures(
		commandDescriptionResidue,
		MAIN.services.CommandService.getTable("sortedNameAndAliasLengthArray")
	)
	local commandCaptures = utilityModule.combineCaptures(commandCapsuleCaptures, commandPlainCaptures)

	local modifierCapsuleCaptures, commandDescriptionResidue = utilityModule.getCapsuleCaptures(
		commandDescriptionResidue,
		MAIN.modules.Parser.Modifiers.sortedNameAndAliasLengthArray
	)
	local modifierPlainCaptures, commandDescriptionResidue = utilityModule.getPlainCaptures(
		commandDescriptionResidue,
		MAIN.modules.Parser.Modifiers.sortedNameAndAliasLengthArray

	)
	local modifierCaptures = utilityModule.combineCaptures(modifierCapsuleCaptures, modifierPlainCaptures)

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

	local qualifierCaptures, qualifierDescriptionResidue = utilityModule.getCapsuleCaptures(
		qualifierDescription,
		MAIN.modules.Parser.Qualifiers.sortedNameAndAliasLengthArray
	)

	local qualifiers = utilityModule.getMatches(
		qualifierDescriptionResidue,
		parserModule.patterns.argumentsFromCollection
	)
	local unrecognizedQualifiers = {}

	local qualifierDictionary = MAIN.modules.Parser.Qualifiers.lowerCaseNameAndAliasToArgDictionary
	for _, match in pairs(qualifiers) do
		if match ~= "" then
			if not qualifierDictionary[match:lower()] then
				table.insert(unrecognizedQualifiers, match)
			end
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
