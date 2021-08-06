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

function Command.invoke(job, args, custom)
	local player = args[1]
	
	-- If another flight job is enabled, kill it
	local potentialJobsToClear = main.services.JobService.getJobsWithPlayerUserId(player.UserId)
	for _, potentialJob in pairs(potentialJobsToClear) do
		if potentialJob ~= job and potentialJob:findTag("Flight") then
            potentialJob:kill()
        end
    end

	local speed = (custom and custom.speed) or job:getOriginalArg("Speed") or 100
	job:invokeClient(player, speed)
end



return Command