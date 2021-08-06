local main = require(game.Nanoblox)
local ClientCommand =	{}



function ClientCommand.invoke(job, player)
	local clone = job:add(main.modules.Clone.new(), "destroy")
	job:getAsset("CreepyMelonDescription")
		:andThen(function(asset)
			-- The asset is automatically tracked by the job therefore we don't need to add it to the janitor ourselves
			clone:become(asset)
			clone:setSize(2)
			clone:setDepth(1)
			clone:setCollidable(false)
			clone:watch(player)
			clone:face(player)
			clone:follow(player, 10)
			clone.humanoid.WalkSpeed = 8
		end)
		:catch(warn)
end

function ClientCommand.revoke(job, ...)
	
end

function ClientCommand.replication(job, ...)
	
end



return ClientCommand