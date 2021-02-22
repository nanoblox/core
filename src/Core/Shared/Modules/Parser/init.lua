local Parser = {}

--// CONSTANTS //--

local MAIN = require(game.HDAdmin)

--// VARIABLES //--



--// FUNCTIONS //--

function Parser:init()
	
	local ClientSettings = MAIN.services.SettingService.getGroup("Client")

	Parser.patterns = {
		CommandStatementsFromBatch = string.format(
			"%s([^%s]+)",
			";", --ClientSettings.prefix,
			";" --ClientSettings.prefix
		),
		DescriptionsFromCommandStatement = string.format(
			"%s?([^%s]+)",
			" ", --ClientSettings.descriptorSeparator,
			" " --ClientSettings.descriptorSeparator
		),
		ArgumentsFromCollection = string.format(
			"([^%s]+)%s?",
			",", --ClientSettings.collective,
			"," --ClientSettings.collective
		),
		CapsuleFromKeyword = string.format(
			"%%(%s%%)",
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
	local qualifierRequiredEnums = MAIN.enum.QualifierRequired

	local firstArgName = MAIN.services.CommandService.getTable("dictionary")[commandName].args[1]
	local firstArg = MAIN.modules.Parser.Args.dictionary[firstArgName]
	
	if (firstArg.playerArg ~= true) then
		return qualifierRequiredEnums.Never
	else
		if (firstArg.hidden ~= true) then
			return qualifierRequiredEnums.Always
		else
			return qualifierRequiredEnums.Sometimes
		end
	end
end

--[[

]]--
function Parser.hasTextArgument(commandName)
	local argsDictionary = MAIN.modules.Parser.Args.dictionary
	for _, arg in pairs(MAIN.services.CommandService.getTable("dictionary")[commandName].args) do
		if (argsDictionary[arg] == argsDictionary["text"]) then
			return true
		end
	end
	return false
end

--[[

]]--
function Parser.parseMessage(message)
	local algorithm = MAIN.modules.Parser.Algorithm
	local parsedData = MAIN.modules.Parser.ParsedData

	--// STEP 1 //--
	--[[
		
	]]--
	local parsedDataTables = {}

	for _, commandStatement in pairs(algorithm.getCommandStatementsFromBatch(message)) do
		
		local parsedDataTable = parsedData.new()
		parsedDataTable.commandStatement = commandStatement
	
	--// STEP 2 //--
	--[[

	]]--

		algorithm.getDescriptionsFromCommandStatement(parsedDataTable)
		if (parsedDataTable.failed) then table.insert(parsedDataTables, parsedDataTable) continue end
	
	--// STEP 3 //--
	--[[

	]]--

		algorithm.parseCommandDescription(parsedDataTable)
		if (parsedDataTable.failed) then table.insert(parsedDataTables, parsedDataTable) continue end
		parsedDataTable.requiresQualifier = parsedData.parsedDataTableRequiresQualifier(parsedDataTable)
		if (parsedDataTable.failed) then table.insert(parsedDataTables, parsedDataTable) continue end
		parsedDataTable.hasTextArgument = parsedData.parsedDataTableHasTextArgument(parsedDataTable)

	--// STEP 4 //--
	--[[

	]]--

		algorithm.parseQualifierDescription(parsedDataTable)
		if (parsedDataTable.failed) then table.insert(parsedDataTables, parsedDataTable) continue end

	--// STEP 5 //--
	--[[

	]]--

		algorithm.parseExtraArgumentDescription(parsedDataTable, parsedDataTables, message)
	
	--// STEP 6 //--
	--[[

	]]--

		parsedDataTable:GenerateOrganizedParsedData()
		table.insert(parsedDataTables, parsedDataTable)
		if (parsedDataTable.hasTextArgument) then break end
		
	end
	
	local result = {}

	for _, parsedDataTable in pairs(parsedDataTables) do
		table.insert(result, parsedDataTable.organizedParsedData)
	end
	
	return result
end

--// INSTRUCTIONS //--



return Parser
