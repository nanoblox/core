local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Grants the player with flight. Double-jump or press E to toggle."
Command.aliases	= {"Fly1", "Flight", "Flight1"}
Command.opposites = {}
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
	local speed = (custom and custom.speed) or task:getOriginalArg("Speed") or 50
	local propertyLock = (custom and custom.propertyLock) or "PlatformStand"
	local noclip = (custom and custom.noclip) or false

	local hrp = main.modules.PlayerUtil.getHRP(player)
	local humanoid = main.modules.PlayerUtil.getHumanoid(player)
	if not hrp or not humanoid then
		return
	end

	-- If another flight task is enabled, kill it
	local potentialTasksToClear = main.services.TaskService.getTasksWithPlayerUserId(player.UserId)
	for _, potentialTask in pairs(potentialTasksToClear) do
		if potentialTask ~= task and potentialTask:findTag("Flight") then
            potentialTask:kill()
        end
    end
	
	local flyForce = task:add(Instance.new("BodyPosition"), "Destroy")
	flyForce.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	flyForce.Position = hrp.Position + Vector3.new(0, 4, 0)
	flyForce.Name = "NanobloxFlyForce"
	flyForce.Parent = hrp

	local bodyGyro = task:add(Instance.new("BodyGyro"), "Destroy")
	bodyGyro.D = 50
	bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bodyGyro.P = (noclip and 2000) or 200
	bodyGyro.Name = "NanobloxFlyGyro"
	bodyGyro.CFrame = hrp.CFrame
	bodyGyro.Parent = hrp
	
	task:invokeClient(player, flyForce, bodyGyro, speed, noclip, propertyLock)
end



return Command