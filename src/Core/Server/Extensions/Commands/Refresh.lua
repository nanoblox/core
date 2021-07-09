local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Reloads the player's character in the same position"
Command.aliases	= {"re"}
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
Command.args = {"Player"}

function Command.invoke(task, args)
	local player = unpack(args)
	local originalCFrame
	local hrp = main.modules.PlayerUtil.getHRP(player)
	if hrp then
		originalCFrame = hrp.CFrame
	end
	player:LoadCharacter()
	local newHrp = player.Character:WaitForChild("HumanoidRootPart")
	if originalCFrame then
		newHrp.CFrame = originalCFrame
	end
end



return Command