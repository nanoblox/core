local main = require(game.Nanoblox)
local ClientCommand =	{}



function ClientCommand.invoke(job, player, animationId, speed, isLooped)
	local animTrack = main.modules.PlayerUtil.loadTrack(player, animationId)
	local animation = animTrack and animTrack.Animation
	local fadeTime = 0.2/speed
	if not animTrack then
		return
	end
	local weight = (isLooped and 98) or 99
	job:add(animTrack, "Destroy")
	job:add(animation, "Destroy")
	animTrack.Looped = isLooped
	animTrack.Priority = Enum.AnimationPriority.Action
	animTrack:Play(fadeTime, weight, speed)
	job:add(function()
		animTrack:Stop(fadeTime)
	end, true)
	animTrack.Stopped:Connect(function()
		job:kill()
	end)
	player.Character.Humanoid.Died:Wait()
end



return ClientCommand