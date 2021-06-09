local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name -- the name used to display and execute the command
Command.aliases	= {} -- additional names (typically shorthand) which activate the command
Command.description = "Morphs you into that person" -- a brief description which appears in the menu
Command.contributors = {82347291} -- the names or IDs or people who developed this command
Command.opposites = {} -- the names to undo (revoke) the command, e.g. 'invisible' would have 'visible'
Command.prefixes = {} -- any additional prefixes from the system prefix to activate the command
Command.tags = {"Appearance"} -- tags (lowercase strings) associated with commands for grouping and searching; these are also used by roles to inherit commands (e.g. 'level1', 'level2', etc)
Command.blockPeers = false -- when 'true', prevents users of the same role (i.e. 'peers') executing the command on each other
Command.blockJuniors = false -- when 'true', prevents users of lower roles (i.e. 'junior') executing the command on higher ('i.e. 'senior') roles
Command.autoPreview = false -- preview the commands menu before executing
Command.requiresRig = main.enum.HumanoidRigType.None -- 'None' can be changed to 'R15' or 'R6' which will limit the command to only player characters of that rig type
Command.preventRepeats = main.enum.TriStateSetting.False -- prevents two of the same commands being used on the same user or server at once
Command.revokeRepeats = false -- before creating the task, remove all tasks with the same commandName for the associated user or server
Command.persistence = main.enum.Persistence.UntilCallerRespawns -- when set to 'None', the command will revoke after being invoked - to change this, replace 'None' with 'UntilRevoke', UntilPlayerDies', 'UntilPlayerRespawns', 'UntilPlayerLeaves', 'UntilCallerLeaves' or 'UntilPlayerOrCallerLeave'
Command.args = {"UserDescription"} -- the arguments to be processed and passed through the the command; see the 'Args' module for a list of all arguments

function Command.invoke(task, args)
	local description = unpack(args)
	if description then
		task:buffCaller("HumanoidDescription"):set(description)
	end
end



return Command