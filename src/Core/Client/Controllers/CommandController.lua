-- LOCAL
local main = require(game.Nanoblox)
local CommandController = {}
local clientJobs = {}



-- START
function CommandController.start()
	
	local invokeClientCommand = main.modules.Remote.new("invokeClientCommand")
	invokeClientCommand.onClientInvoke = function(jobProperties)
		local job = main.modules.Job.new(jobProperties)
		clientJobs[job.UID] = job
		job:execute():await()
		if job.killAfterExecution then
			job:kill()
		end
		return
	end

	local revokeClientCommand = main.modules.Remote.new("revokeClientCommand")
	revokeClientCommand.onClientEvent:Connect(function(jobUID, ...)
		local job = clientJobs[jobUID]
		if job then
			job.revokeArguments = table.pack(...)
			job:kill()
			clientJobs[jobUID] = nil
		end
	end)

	local callClientJobMethod = main.modules.Remote.new("callClientJobMethod")
	callClientJobMethod.onClientEvent:Connect(function(jobUID, methodName)
		local job = clientJobs[jobUID]
		if job then
			local method = job[methodName]
			if method then
				method(job)
			end
		end
	end)

	local replicateClientCommand = main.modules.Remote.new("replicateClientCommand")
	replicateClientCommand.onClientEvent:Connect(function(jobUID, packedData)
		local job = clientJobs[jobUID]
		local clientCommand = job and job.command
		local replicationFunction = clientCommand and clientCommand.replication
		if replicationFunction then
			replicationFunction(job, unpack(packedData))
		end
	end)

	local previewCommand = main.modules.Remote.new("previewCommand")
	previewCommand.onClientEvent:Connect(function(statement)
		--!!! preview command statement
	end)

	local replicationRequest = main.modules.Remote.new("replicationRequest")
	CommandController.replicationRequest = replicationRequest
	
end



return CommandController