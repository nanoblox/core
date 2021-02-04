local main = require(game.Nanoblox)
local command =	{}


command.name = script.Name -- the name used to display and execute the command
command.aliases	= {} -- additional names (typically shorthand) which activate the command
command.description = "" -- a brief description which appears in the menu
command.contributors = {} -- the names or IDs or people who developed this command
command.opposites = {} -- the names to undo (revoke) the command, e.g. 'invisible' would have 'visible'
command.prefixes = {} -- any additional prefixes from the system prefix to activate the command
command.tags = {} -- tags associated with commands for grouping and searching; these are also used by roles to inherit commands (e.g. 'level1', 'level2', etc)
command.blockPeers = false -- when 'true', prevents users of the same role (i.e. 'peers') executing the command on each other
command.blockJuniors = false -- when 'true', prevents users of lower roles (i.e. 'junior') executing the command on higher ('i.e. 'senior') roles
command.autoPreview = false -- preview the commands menu before executing
command.requiresRig = nil -- e.g. Enum.HumanoidRigType.R15

command.args = {} -- the arguments to be processed and passed through the the command; see the 'Args' module for a list of all arguments
function command:invoke(this, caller, args)
	
end
function command:revoke(this, caller, args)

end



return command