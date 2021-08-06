local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Gives the ability to fly and pass through objects (while *not* being seen by others). Double-jump or press E to toggle."
Command.aliases	= {"Noclip1"}
Command.opposites = {"Clip", "Clip1"}
Command.tags = {"Utility", "Flight"}
Command.prefixes = {}
Command.contributors = {82347291}
Command.blockPeers = false
Command.blockJuniors = false
Command.autoPreview = false
Command.requiresRig = main.enum.HumanoidRigType.None
Command.revokeRepeats = false
Command.preventRepeats = main.enum.TriStateSetting.True
Command.cooldown = 0
Command.persistence = main.enum.Persistence.UntilPlayerDies
Command.args = {"Player", "Speed"}

function Command.invoke(task, args, custom)
	local player = args[1]
	
	-- If another flight task is enabled, kill it
	local potentialTasksToClear = main.services.TaskService.getTasksWithPlayerUserId(player.UserId)
	for _, potentialTask in pairs(potentialTasksToClear) do
		if potentialTask ~= task and potentialTask:findTag("Flight") then
            potentialTask:kill()
        end
    end

	local speed = (custom and custom.speed) or task:getOriginalArg("Speed") or 100
	task:invokeClient(player, speed)
end



return Command