-- enumName, enumValue, additionalProperty
return {
	{"None", 1}, -- kills the task after all tracking threads have completed
	{"UntilRevoke", 2}, -- the task will only be killed when revoke is manually called (i.e. ;unCommandName), or when its associated player leaves
	{"UntilPlayerDies", 3}, -- waits until the player dies or leaves before killing the task
	{"UntilPlayerRespawns", 4}, -- waits until the player respawns or leaves before killing the task
	{"UntilPlayerLeaves", 5}, -- waits until the player leaves before killing the task
	{"UntilCallerDies", 6}, -- waits until the caller dies or leaves before killing the task.
	{"UntilCallerRespawns", 7}, -- waits until the caller respawns or leaves before killing the task.
	{"UntilCallerLeaves", 8}, -- waits until the caller (i.e. the person who executed the command) leaves before killing the task
	{"UntilPlayerOrCallerLeave", 9}, -- waits until the caller *or* player leave before killing the task
}