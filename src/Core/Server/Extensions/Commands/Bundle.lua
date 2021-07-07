local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Morphs you into that bundle"
Command.aliases	= {"Bund"}
Command.opposites = {}
Command.tags = {"Appearance"}
Command.prefixes = {}
Command.contributors = {82347291}
Command.blockPeers = false
Command.blockJuniors = false
Command.autoPreview = false
Command.requiresRig = main.enum.HumanoidRigType.None
Command.revokeRepeats = false
Command.preventRepeats = main.enum.TriStateSetting.False
Command.cooldown = 0
Command.persistence = main.enum.Persistence.UntilPlayerRespawns
Command.args = {"Player", "BundleDescription", "BodyParts"}

function Command.invoke(task, args)
	local _, description = unpack(args)
	if description then
		local bodyParts = task:getOriginalArg("BodyParts")
		if bodyParts then
			for _, bodyPartName in pairs(bodyParts) do
				if bodyPartName ~= "Accessories" then
					task:buffPlayer("HumanoidDescription", bodyPartName):set(description[bodyPartName])
				end
			end
		else
			task:buffPlayer("HumanoidDescription"):set(description)
		end
	end
end



return Command