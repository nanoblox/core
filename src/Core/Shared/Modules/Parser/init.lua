local Parser = {}

--// CONSTANTS //--

local MAIN = require(game.HDAdmin)

--// VARIABLES //--



--// FUNCTIONS //--

--[[



]]--
function Parser.init()
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

	local firstArgName = MAIN.services.CommandService.getTable("dictionary")[commandName].args[1]
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
        if (parsedData.hasFailed) then table.insert(allParsedDatas, parsedData) continue end

    --// STEP 3 //--
    --[[


    
    ]]--
    
        parsedDataModule.parseCommandDescriptionAndSetFlags(parsedData)
        if (parsedData.hasFailed) then table.insert(allParsedDatas, parsedData) continue end

    --// STEP 4 //--
    --[[


    
    ]]--

        parsedDataModule.parseQualifierDescription(parsedData)
        if (parsedData.hasFailed) then table.insert(allParsedDatas, parsedData) continue end

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
end

--// INSTRUCTIONS //--



return Parser