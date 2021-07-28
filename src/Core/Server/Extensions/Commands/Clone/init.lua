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
Command.args = {"UserId"}

function Command.invoke(task, args)
    local userId = unpack(args)
	local callerHead = main.modules.PlayerUtil.getHead(task.caller)
	local callerHRP = main.modules.PlayerUtil.getHRP(task.caller)
	local hrpZ = (callerHRP and callerHRP.Size.Z) or 2
	local cloneCFrame = callerHead and callerHead.CFrame * CFrame.new(0, callerHead.Size.Y+10, -hrpZ-2)
	if userId and cloneCFrame then
		local player = main.Players:GetPlayerByUserId(userId)
		local playerOrUserId = player or userId
		local clone = task:give(main.modules.Clone.new(playerOrUserId))
		clone:setCFrame(cloneCFrame)
	end
end



return Command