local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Changes the color of the players body"
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
Command.args = {"Player", "Color", "BodyParts"}

function Command.invoke(job, args)
	local _, color = unpack(args)
	if color then
		local bodyParts = job:getOriginalArg("BodyParts")
		if bodyParts then
			for _, bodyPartName in pairs(bodyParts) do
				if bodyPartName ~= "Accessories" then
					job:buffPlayer("BodyColor", bodyPartName):set(color)
				end
			end
		else
			job:buffPlayer("BodyColor"):set(color)
		end
	end
end



return Command