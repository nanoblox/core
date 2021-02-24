-- enumName, enumValue, additionalProperty
return {
	{"None", 1}, -- kills the task after all tracking threads have completed immidately after being invoked
	{"UntilDeath", 2}, -- waits until the player dies before killing the task
	{"UntilRespawn", 3}, -- waits until the player respawns before killing the task
	{"UntilLeave", 4}, -- waits until the player leave before killing the task
	{"UntilRevoke", 5}, -- the task will only be killed when revoke is manually called (i.e. ;unCommandName), or when its associated player leaves
}