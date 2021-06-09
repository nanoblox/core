-- enumName, enumValue, additionalProperty
return {
	{ "MissingCommandDescription", 1 }, -- parsedData was missing a commandDescription
	{ "UnbalancedCapsulesInCommandDescription", 2 }, -- parsedData had unbalanced capsules in commandDescription
	{ "UnbalancedCapsulesInQualifierDescription", 3 }, -- parsedData had unbalanced capsules in qualifierDescription
	{ "MissingCommands", 4 }, -- parsedData was missing commands
	{ "MalformedCommandDescription", 5 }, -- parsedData had a malformed command description
}
