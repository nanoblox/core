-- enumName, enumValue, additionalProperty
return {
	{"Perm", 1}, -- Remains permanently, and syncs with config in studio (i.e. is added to the role itself)
	{"Time", 2}, -- Remains permanently (until removed)
	{"Server", 3}, -- Persists until the server ends
	{"Giver", 4}, -- Persists until the 'giver' (user that gave the role) leaves the server
	{"Temp", 5}, -- Persists until the player leaves
}