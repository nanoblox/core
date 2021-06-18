local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Plays an animation within the player. The animation must be a Catalog Animation/Emote or owned by the game otherwise it won't play."
Command.aliases	= {"Emote", "Anim", "Animation"}
Command.opposites = {}
Command.tags = {"Fun"}
Command.prefixes = {}
Command.contributors = {82347291}
Command.blockPeers = false
Command.blockJuniors = false
Command.autoPreview = false
Command.requiresRig = main.enum.HumanoidRigType.None
Command.revokeRepeats = true
Command.preventRepeats = main.enum.TriStateSetting.Default
Command.cooldown = 0
Command.persistence = main.enum.Persistence.None
Command.args = {"Player", "AnimationId", "Speed"}

function Command.invoke(task, args)
	local player, animationId, speed = unpack(args)
	-- This enables us to determine whether the animation is looped
	local humanoid = main.modules.PlayerUtil.getHumanoid(player)
	if not humanoid then
		return
	end
	local animator = task:give(Instance.new("Animator"))
	animator.Name = "NanobloxPreviewAnimator"
	animator.Parent = humanoid
	local animation = task:give(Instance.new("Animation"))
	animation.AnimationId = "rbxassetid://"..animationId
	local animTrack = task:give(animator:LoadAnimation(animation))
	-- For a bizarre reason, there is no animTrack.Loaded event, so we have to repeat wait until its length is greater than 0 instead
	task:delayUntil(function() return animTrack.Length > 0 end, function()
		local isLooped = animTrack.looped
		-- If is looped, bypass the client invocation expiry of 90 seconds
		if isLooped then
			task.persistence = main.enum.Persistence.UntilPlayerDies
		end
		animTrack:Destroy()
		animation:Destroy()
		animator:Destroy()
		-- If speed defaulted (i.e. was not specified, set to 1)
		if task:getOriginalArg("Speed") == nil then
			speed = 1
		end
		task:invokeClient(player, animationId, speed, isLooped)
	end)
end



return Command