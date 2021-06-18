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
Command.args = {"Player", "AnimationId", "AnimationSpeed"}

function Command.invoke(task, args)
	local player, animationId, speed = unpack(args)
	-- This constructs the animation on the server so it can replicate to all other clients
	local animTrack = main.modules.PlayerUtil.loadTrack(player, animationId)
	local animation = animTrack and animTrack.Animation
	if not animTrack then
		return
	end
	task:give(animTrack)
	task:give(animation)
	-- For a bizarre reason, there is no animTrack.Loaded event, so we have to repeat wait until its length is greater than 0 instead
	task:delayUntil(function() return animTrack.Length > 0 end, function()
		local isLooped = animTrack.looped
		-- If is looped, bypass the client invocation expiry of 90 seconds
		if isLooped then
			task.persistence = main.enum.Persistence.UntilPlayerDies
		end
		animTrack.Priority = Enum.AnimationPriority.Action
		animTrack.Looped = isLooped
		-- If speed defaulted (i.e. was not specified, set to 1)
		speed = speed or 1
		-- We invoke all clients, instead of just the individual whos playing, to make animations perfectly syncronised and to be able to set the track.Priority
		task:invokeAllAndFutureClients(player, animationId, speed, isLooped)
	end)
end



return Command