local main = require(game.Nanoblox)
local ClientCommand =	{}



function ClientCommand.invoke(task, player)
	local clone = task:add(main.modules.Clone.new(), "destroy")
	task:getAsset("CreepyMelonDescription")
		:andThen(function(asset)
			-- The asset is automatically tracked by the task therefore we don't need to add it to the janitor ourselves
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

function ClientCommand.revoke(task, ...)
	
end

function ClientCommand.replication(task, ...)
	
end



return ClientCommand