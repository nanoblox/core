local main = require(game.Nanoblox)
local ClientCommand =	{}



function ClientCommand.invoke(task, animationId, speed, isLooped)
	local char = main.localPlayer.Character
	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	local animation = task:give(Instance.new("Animation"))
	animation.AnimationId = "rbxassetid://"..animationId
	animation.Name = "Nanoblox-"..animationId
	animation.Parent = char
	local track = task:give(animator:LoadAnimation(animation))
	track.Looped = isLooped
	track.Stopped:Connect(function()
		task:kill()
	end)
	local fadeTime = 0.2/speed
	task:give(function()
		track:Stop(fadeTime)
	end)
	track:AdjustWeight(100)
	track:Play(fadeTime, nil, speed)
	humanoid.Died:Wait()
end



return ClientCommand