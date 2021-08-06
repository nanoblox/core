local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Loads GearId and if succesful adds gear to the players backpack."
Command.aliases	= {}
Command.opposites = {}
Command.tags = {"Fun"}
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
Command.args = {"Player", "Gear"}

function Command.invoke(job, args)
	local player, gear = unpack(args)
	if gear then
		gear:Clone().Parent = player.Backpack
	end
end



return Command