local main = require(game.Nanoblox)
local ClientCommand =	{}



function ClientCommand.invoke(task, ...)
	local commandName = self.Name
	local humanoid = main:GetModule("cf"):GetHumanoid()
	local hrp = main:GetModule("cf"):GetHRP()
	if humanoid and hrp then
		local lastUpdate = tick()
		hrp.Anchored = true
		humanoid.PlatformStand = true
		repeat wait()
			local delta = tick()-lastUpdate
			local look = (main.camera.Focus.p-main.camera.CFrame.p).unit
			local move = main:GetModule("cf"):GetNextMovement(delta, main.commandSpeeds[commandName])
			local pos = hrp.Position
			hrp.CFrame = CFrame.new(pos,pos+look) * move
			lastUpdate = tick()
			
		until not main.commandsActive[commandName]
		if hrp and humanoid then
			hrp.Anchored = false
			hrp.Velocity = Vector3.new()
			humanoid.PlatformStand = false
		end
	end
end



return ClientCommand