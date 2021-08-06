-- enumName, enumValue, additionalProperty
return {
	{"None", 1}, -- kills the job after all tracking threads have completed
	{"UntilRevoked", 2}, -- the job will only be killed when revoke is manually called (i.e. ;unCommandName), or when its associated player leaves
	{"UntilPlayerDies", 3}, -- waits until the player dies or leaves before killing the job
	{"UntilPlayerRespawns", 4}, -- waits until the player respawns or leaves before killing the job
	{"UntilPlayerLeaves", 5}, -- waits until the player leaves before killing the job
	{"UntilCallerDies", 6}, -- waits until the caller dies or leaves before killing the job.
	{"UntilCallerRespawns", 7}, -- waits until the caller respawns or leaves before killing the job.
	{"UntilCallerLeaves", 8}, -- waits until the caller (i.e. the person who executed the command) leaves before killing the job
	{"UntilPlayerOrCallerLeave", 9}, -- waits until the caller *or* player leave before killing the job
}