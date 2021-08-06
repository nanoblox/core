local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Teleports Players directly above the TargetPlayer's character."
Command.aliases	= {"Tp2"}
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
Command.args = {"Players", "TargetPlayer"}

function Command.invoke(job, args)
	local players = args[1]
	local targetPlayer = args[2] or job.caller
	local targetHRP = main.modules.PlayerUtil.getHRP(targetPlayer)
	if not targetHRP then
		return
	end
	local removeIndex = table.find(players, targetPlayer)
	if removeIndex then
		table.remove(players, removeIndex)
	end
	for i, player in pairs(players) do
		local playerHRP = main.modules.PlayerUtil.getHRP(player)
		local playerHumanoid = main.modules.PlayerUtil.getHumanoid(player)
		if playerHRP and playerHumanoid then
			----
			job:delay(0.02*i, function()
				local targetCFrame = targetHRP.CFrame + Vector3.new(0, playerHRP.Size.Y*4, 0)
				local wasSeated = main.modules.HumanoidUtil.unseat(playerHumanoid)
				local teleportDelay = (wasSeated and 0.1) or 0
				job:delay(teleportDelay, function()
					playerHRP.CFrame = targetCFrame
				end)
			end)
			----
		end
	end
end



return Command