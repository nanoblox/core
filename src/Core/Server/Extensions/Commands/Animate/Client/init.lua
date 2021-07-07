local main = require(game.Nanoblox)
local ClientCommand =	{}



function ClientCommand.invoke(task, player, animationId, speed, isLooped)
	local animTrack = main.modules.PlayerUtil.loadTrack(player, animationId)
	local animation = animTrack and animTrack.Animation
	local fadeTime = 0.2/speed
	if not animTrack then
		return
	end
	local weight = (isLooped and 98) or 99
	task:give(animTrack)
	task:give(animation)
	animTrack.Looped = isLooped
	animTrack.Priority = Enum.AnimationPriority.Action
	animTrack:Play(fadeTime, weight, speed)
	task:give(function()
		animTrack:Stop(fadeTime)
	end)
	animTrack.Stopped:Connect(function()
		task:kill()
	end)
	player.Character.Humanoid.Died:Wait()
end



return ClientCommand