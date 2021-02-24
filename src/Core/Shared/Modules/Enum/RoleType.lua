-- enumName, enumValue, additionalProperty
return {
	{"Perm", 1}, -- Persists until the player leaves
	{"Time", 2}, -- Persists until the 'giver' (user that gave the role) leaves the server
	{"Server", 3}, -- Persists until the server ends
	{"Giver", 4}, -- Remains permanently (until removed)
	{"Temp", 5}, -- Remains permanently, and syncs with config in studio (i.e. is added to the role itself)
}