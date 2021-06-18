local main = require(game.Nanoblox)
local ClientCommand =	{}



function ClientCommand.invoke(task, player, animationId, speed, isLooped)
	local animTrack = main.modules.PlayerUtil.loadTrack(player, animationId)
	local animation = animTrack and animTrack.Animation
	local fadeTime = 0.2/speed
	if not animTrack then
		return
	end
	task:give(animTrack)
	task:give(animation)
	animTrack:AdjustWeight(100)
	animTrack.Looped = isLooped
	animTrack.Priority = Enum.AnimationPriority.Action
	animTrack:Play(fadeTime, nil, speed)
	task:give(function()
		animTrack:Stop(fadeTime)
	end)
	if player == main.localPlayer then
		animTrack.Stopped:Connect(function()
			task:kill()
		end)
		player.Character.Humanoid.Died:Wait()
	end
end



return ClientCommand