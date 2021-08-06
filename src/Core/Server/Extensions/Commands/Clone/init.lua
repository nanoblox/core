local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = ""
Command.aliases	= {}
Command.opposites = {}
Command.tags = {}
Command.prefixes = {}
Command.contributors = {}
Command.blockPeers = false
Command.blockJuniors = false
Command.autoPreview = false
Command.requiresRig = main.enum.HumanoidRigType.None
Command.revokeRepeats = false
Command.preventRepeats = main.enum.TriStateSetting.False
Command.cooldown = 0
Command.persistence = main.enum.Persistence.UntilCallerLeaves
Command.args = {"Player", "UserId"}

Command.restrictions = {
	maxClones = 5,
}

function Command.invoke(task, args)
	-- This ensures users without permission cannot exceed maxClones
	local tasks = main.services.TaskService.getTasksWithCommandNameAndCallerUserId(task.commandName, task.callerUserId)
	local totalTasks = #tasks
	if task.restrict and totalTasks > Command.restrictions.maxClones then
		warn(("You do not have permission to exceed %s clones!"):format(Command.restrictions.maxClones)) --!!!notice
		return task:kill()
	end
	
    local player, userId = unpack(args)
	local playerHead = main.modules.PlayerUtil.getHead(player)
	local callerHRP = main.modules.PlayerUtil.getHRP(player)
	local hrpZ = (callerHRP and callerHRP.Size.Z) or 2
	local cloneCFrame = playerHead and playerHead.CFrame * CFrame.new(0, playerHead.Size.Y+10, -hrpZ-2)
	if userId and cloneCFrame then

		-- This creates the clone and spawns it in front of the caller
		local clonePlayer = main.Players:GetPlayerByUserId(userId)
		local cloneOrUserId = clonePlayer or userId
		local clone = task:add(main.modules.Clone.new(cloneOrUserId), "destroy")
		clone:setCFrame(cloneCFrame)

		-- It's important we kill the task (after the games respawn interval) in case the clone dies
		clone.Humanoid.Died:Connect(function()
			clone:setAnchored(false)
			clone:BreakJoints()
			task:delay(main.Players.RespawnTime, task.kill, task)
		end)
	end
end



return Command