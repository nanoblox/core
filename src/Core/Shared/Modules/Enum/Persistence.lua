-- enumName, enumValue, additionalProperty
return {
	{"None", 1}, -- kills the task after all tracking threads have completed
	{"UntilRevoke", 2}, -- the task will only be killed when revoke is manually called (i.e. ;unCommandName), or when its associated player leaves
	{"UntilPlayerDies ", 3}, -- waits until the player (i.e. target) dies or leaves before killing the task
	{"UntilPlayerRespawns", 4}, -- waits until the player (i.e. target) respawns or leaves before killing the task
	{"UntilPlayerLeaves", 5}, -- waits until the player (i.e. target) leaves before killing the task
	{"UntilCallerLeaves", 6}, -- waits until the caller (i.e. the person who executed the command) leaves before killing the task
	{"UntilPlayerOrCallerLeave", 7}, -- waits until the caller *or* player leave before killing the task
}