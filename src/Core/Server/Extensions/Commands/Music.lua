local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Plays sound throughout the server."
Command.aliases	= {"Sound"}
Command.opposites = {}
Command.tags = {"Utility", "Sound"}
Command.prefixes = {}
Command.contributors = {82347291}
Command.blockPeers = false
Command.blockJuniors = false
Command.autoPreview = false
Command.requiresRig = main.enum.HumanoidRigType.None
Command.revokeRepeats = true
Command.preventRepeats = main.enum.TriStateSetting.Default
Command.cooldown = 0
Command.persistence = main.enum.Persistence.UntilRevoked
Command.args = {"SoundId"}

function Command.invoke(job, args)
	local soundId = unpack(args)
	local sound = job:add(main.modules.Sound.new(soundId, main.enum.SoundType.Music), "destroy")
	sound.Name = "NanobloxMusic"
	sound.Parent = main.workspaceFolder
	sound:Play()
end



return Command