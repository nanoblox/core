-- enumName, enumValue, additionalProperty
return {
	{"Always", 1}, -- Parser was able to determine from the commandName that a qualifierDescription is always required
	{"Never", 2}, -- Parser was able to determine from the commandName that a qualifierDescription is never required
	{"Sometimes", 3}, -- Parser was not able to determine from the commandName whether or not a qualifierDescription is required
}