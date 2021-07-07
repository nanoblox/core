local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Changes the material of the players body"
Command.aliases	= {}
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
Command.args = {"Player", "Material", "BodyParts"}

function Command.invoke(task, args)
	local _, material = unpack(args)
	if material then
		local bodyParts = task:getOriginalArg("BodyParts")
		if bodyParts then
			for _, bodyPartName in pairs(bodyParts) do
				if bodyPartName ~= "Accessories" then
					task:buffPlayer("BodyMaterial", bodyPartName):set(material)
				end
			end
		else
			task:buffPlayer("BodyMaterial"):set(material)
		end
	end
end



return Command