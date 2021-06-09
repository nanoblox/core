local main = require(game.Nanoblox)
local ClientCommand =	{}



function ClientCommand.invoke(task, player)
	local clone = task:give(main.modules.Clone.new())
	task:getAsset("CreepyMelonDescription")
		:andThen(function(asset)
			clone:become(asset)
			clone:setSize(2)
			clone:setDepth(1)
			clone:setCollidable(false)
			clone:watch(player)
			clone:face(player)
			clone:follow(player, 10)
			clone.humanoid.WalkSpeed = 8
			asset.Parent = workspace
		end)
		:catch(warn)
end

function ClientCommand.revoke(task, ...)
	
end

function ClientCommand.replication(task, ...)
	
end



return ClientCommand