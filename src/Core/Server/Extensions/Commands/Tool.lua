local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Adds the tool to the players backpack. If the name is 'all', then all tools will be given."
Command.aliases	= {"Tools"}
Command.opposites = {}
Command.tags = {"Utility"}
Command.prefixes = {}
Command.contributors = {82347291}
Command.blockPeers = false
Command.blockJuniors = false
Command.autoPreview = false
Command.requiresRig = main.enum.HumanoidRigType.None
Command.revokeRepeats = false
Command.preventRepeats = main.enum.TriStateSetting.Default
Command.cooldown = 0
Command.persistence = main.enum.Persistence.None
Command.args = {"Player", "Tools"}

function Command.invoke(task, args)
	local player, tools = unpack(args)
	if tools then
		for _, tool in pairs(tools) do
			tool:Clone().Parent = player.Backpack
		end
	end
end



return Command