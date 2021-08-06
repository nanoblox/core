-- LOCAL
local main = require(game.Nanoblox)
local System = main.modules.System
local JobService = System.new("Jobs")
JobService.remotes = {}
local jobs = {}
local Job = main.modules.Job
local Signal = main.modules.Signal.new()



-- START
function JobService.start()

	-- REMOTES
	local invokeClientCommand = main.modules.Remote.new("invokeClientCommand")
    JobService.remotes.invokeClientCommand = invokeClientCommand

	local revokeClientCommand = main.modules.Remote.new("revokeClientCommand")
    JobService.remotes.revokeClientCommand = revokeClientCommand

	local callClientJobMethod = main.modules.Remote.new("callClientJobMethod")
    JobService.remotes.callClientJobMethod = callClientJobMethod

	local replicationRequest = main.modules.Remote.new("replicationRequest")
	replicationRequest.onServerEvent:Connect(function(player, jobUID, targetPool, packedArgs, packedData)
		local job = JobService.getJob(jobUID)
		local clockTime = os.clock()
		local errorMessage
		local targetPoolName = main.enum.TargetPool.getName(targetPool)
		if not job then
			errorMessage = "Replication blocked: Job not found!"
		elseif job.callerUserId ~= player.UserId then
			errorMessage = "Replication blocked: Requester's UserId does not match caller's UserId!"
		elseif not job.command.preReplication then
			errorMessage = "Replication blocked: ServerCommand.preReplication(job, targetPool, packedData) must be specified!"
		elseif not targetPoolName then
			errorMessage = "Replication blocked: Invalid argument, 'targetPool' must be a TargetPool enum!"
		elseif typeof(packedArgs) ~= "table" then
			errorMessage = "Replication blocked: Invalid argument, 'packedArgs' must be a table!"
		elseif typeof(packedData) ~= "table" then
			errorMessage = "Replication blocked: Invalid argument, 'packedData' must be a table!"
		end
		if not errorMessage then
			if clockTime >= (job._nextReplicationsThisSecondRefresh or 0) then
				job._nextReplicationsThisSecondRefresh = clockTime + 1
				job.replicationRequestsThisSecond = 1
			end
			local success, blockMessage = job.command.preReplication(job, targetPool, packedData)
			if not success then
				if not blockMessage then
					blockMessage = ("Unspecified command rejection for '%s'."):format(job.command.name)
				end
				errorMessage = ("Replication blocked: %s"):format(tostring(blockMessage))
			end
		end
		if not errorMessage then
			local success, playersArrayOrErrorMessage = pcall(function() return main.enum.TargetPool.getProperty(targetPoolName)(unpack(packedArgs)) end)
			if not success then
				errorMessage = playersArrayOrErrorMessage
			else
				for _, plr in pairs(playersArrayOrErrorMessage) do
					JobService.remotes.replicateClientCommand:fireClient(plr, job.UID, packedData)
				end
				job.totalReplicationRequests += 1
				job.replicationRequestsThisSecond += 1
			end
		end
		if errorMessage then
			warn(errorMessage)
			--!!!notice here player or caller??, probably player
			return
		end
	end)
	JobService.remotes.replicationRequest = replicationRequest

	local replicateClientCommand = main.modules.Remote.new("replicateClientCommand")
    JobService.remotes.replicateClientCommand = replicateClientCommand


	-- GLOBALS
	local callerLeftSender = main.services.GlobalService.createSender("callerLeft")
	local callerLeftReceiver = main.services.GlobalService.createReceiver("callerLeft")
	callerLeftReceiver.onGlobalEvent:Connect(function(callerUserId)
		local jobsNow = JobService.getJobs()
		for _, job in pairs(jobsNow) do
			if job.callerUserId == callerUserId and not job.isDead then
				job.callerLeft:Fire()
			end
		end
	end)
	JobService.callerLeftSender = callerLeftSender
	JobService.callerLeftReceiver = callerLeftReceiver

end



-- EVENTS
local commandNameToJob = main.modules.State.new() -- This allows for super quick retrieval of a group of jobs with the same commandName
local playerUserIdToJobGroup = main.modules.State.new() -- This allows for super quick retrieval of a group of jobs with the same playerUserId
local callerUserIdToJobGroup = main.modules.State.new() -- This allows for super quick retrieval of a group of jobs with the same callerUserId

JobService.jobAdded = Signal.new()
JobService.jobChanged = Signal.new()
JobService.jobRemoved = Signal.new()

JobService.recordAdded:Connect(function(UID, record)
	--warn(("JOB '%s' ADDED!"):format(UID))
	local job = Job.new(record)
	job.UID = UID
	jobs[UID] = job
	job:begin()
	if job.playerUserId then
		playerUserIdToJobGroup:getOrSetup(job.playerUserId, job.commandNameLower):set(UID, job)  -- This allows for super quick retrieval of a group of jobs with the same playerUserId
	end
	if job.callerUserId then
		callerUserIdToJobGroup:getOrSetup(job.callerUserId, job.commandNameLower):set(UID, job)  -- This allows for super quick retrieval of a group of jobs with the same callerUserId
	end
	commandNameToJob:getOrSetup(job.commandNameLower):set(UID, job)
	JobService.jobAdded:Fire(job)
end)

JobService.recordRemoved:Connect(function(UID)
	local job = jobs[UID]
	if job then
		job:destroy()
		job[UID] = nil
	end
	local playerJobCommandGroup = playerUserIdToJobGroup:find(job.playerUserId, job.commandNameLower)
	if playerJobCommandGroup then
		playerJobCommandGroup:set(UID, nil)
	end
	local callerJobCommandGroup = callerUserIdToJobGroup:find(job.callerUserId, job.commandNameLower)
	if callerJobCommandGroup then
		callerJobCommandGroup:set(UID, nil)
	end
	local jobCommandGroup = commandNameToJob:find(job.commandNameLower)
	if jobCommandGroup then
		jobCommandGroup:set(UID, nil)
	end
	JobService.jobRemoved:Fire(job)
end)

JobService.recordChanged:Connect(function(UID, propertyName, propertyValue, propertyOldValue)
	--warn(("JOB '%s' CHANGED %s to %s"):format(UID, tostring(propertyName), tostring(propertyValue)))
	local job = jobs[UID]
	if job then
		job[propertyName] = propertyValue
	end
	JobService.jobChanged:Fire(job, propertyName, propertyValue, propertyOldValue)
end)



-- METHODS
function JobService.generateRecord(key)
	return {
		executionTime = os.time(),
		executionOffset = os.time() - tick(),
		callerUserId = nil,
		commandName = "",
		args = {},
		qualifiers = {},
		playerUserId = nil,
	}
end

function JobService.createJob(isGlobal, properties)
	local key = (properties and properties.UID) or main.modules.DataUtil.generateUID(10)
	properties.UID = key
	---
	local command = main.services.CommandService.getCommand(properties.commandName)
	if not command then
		return false
	end
	local commandNameLower = string.lower(properties.commandName)
	properties.commandNameLower = commandNameLower
	local runningJobs = JobService.getJobsWithCommandNameAndOptionalPlayerUserId(commandNameLower, properties.playerUserId)
	if command.revokeRepeats then
		for _, job in pairs(runningJobs) do
			job.cooldown = 0
			job:kill()
		end
	else
		local preventRepeats = command.preventRepeats
		if preventRepeats == main.enum.TriStateSetting.Default then
			preventRepeats = main.services.SettingService.getGroup("System").preventRepeatCommands
		end
		if preventRepeats and #runningJobs > 0 then
			local firstRunningJob = runningJobs[1]
			local jobCooldownEndTime = firstRunningJob.cooldownEndTime
			local additionalUserMessage = ""
			local associatedPlayer = firstRunningJob.player
			if associatedPlayer then
				additionalUserMessage = (" on '%s' (@%s)"):format(associatedPlayer.DisplayName, associatedPlayer.Name)
			end
			if jobCooldownEndTime then
				local remainingTime = (math.ceil((jobCooldownEndTime-os.clock())*100))/100
				warn(("Wait %s seconds until command '%s' has cooldown before using again%s!"):format(remainingTime, command.name, additionalUserMessage)) --!!!notice
				return
			end
			warn(("Wait until command '%s' has finished before using again%s!"):format(command.name, additionalUserMessage)) --!!!notice
			return
		end
	end
	---
	JobService:createRecord(key, isGlobal, properties)
	local job = JobService.getJob(key)
	return job
end

function JobService.getJob(UID)
	local job = jobs[UID]
	if not job then
		return false
	end
	return job
end

function JobService.getJobs()
	local allJobs = {}
	for name, job in pairs(jobs) do
		table.insert(allJobs, job)
	end
	return allJobs
end

function JobService.getJobsWithCommandName(commandName)
	local jobsArray = {}
	local jobCommandGroup = commandNameToJob:find(commandName)
	if jobCommandGroup then
		for _, job in pairs(jobCommandGroup) do
			table.insert(jobsArray, job)
		end
	end
	return jobsArray
end

function JobService.getJobsWithPlayerUserId(playerUserId)
	local jobsArray = {}
	local playerJobCommandGroups = playerUserIdToJobGroup:find(playerUserId)
	if playerJobCommandGroups then
		for _, groupOfJobs in pairs(playerJobCommandGroups) do
			for _, job in pairs(groupOfJobs) do
				table.insert(jobsArray, job)
			end
		end
	end
	return jobsArray
end

function JobService.getJobsWithCallerUserId(callerUserId)
	local jobsArray = {}
	local callerJobCommandGroups = callerUserIdToJobGroup:find(callerUserId)
	if callerJobCommandGroups then
		for _, groupOfJobs in pairs(callerJobCommandGroups) do
			for _, job in pairs(groupOfJobs) do
				table.insert(jobsArray, job)
			end
		end
	end
	return jobsArray
end

function JobService.getJobsWithCommandNameAndPlayerUserId(commandName, playerUserId)
	local jobsArray = {}
	local playerJobCommandGroup = playerUserIdToJobGroup:find(playerUserId, commandName)
	if playerJobCommandGroup then
		for _, job in pairs(playerJobCommandGroup) do
			table.insert(jobsArray, job)
		end
	end
	return jobsArray
end

function JobService.getJobsWithCommandNameAndCallerUserId(commandName, callerUserId)
	local jobsArray = {}
	local callerJobCommandGroup = callerUserIdToJobGroup:find(callerUserId, commandName)
	if callerJobCommandGroup then
		for _, job in pairs(callerJobCommandGroup) do
			table.insert(jobsArray, job)
		end
	end
	return jobsArray
end

function JobService.getJobsWithCommandNameAndOptionalPlayerUserId(commandName, optionalPlayerUserId)
	local jobsArray = (optionalPlayerUserId and JobService.getJobsWithCommandNameAndPlayerUserId(commandName, optionalPlayerUserId)) or JobService.getJobsWithCommandName(commandName)
	return jobsArray
end

function JobService.updateJob(UID, propertiesToUpdate)
	local job = JobService.getJob(UID)
	assert(job, ("job '%s' not found!"):format(tostring(UID)))
	JobService:updateRecord(UID, propertiesToUpdate)
	return true
end

function JobService.removeJob(UID)
	local job = JobService.getJob(UID)
	assert(job, ("job '%s' not found!"):format(tostring(UID)))
	JobService:removeRecord(UID)
	return true
end

function JobService.removeJobsWithCommandName(commandName)
	local jobsArray = JobService.getJobsWithCommandName(commandName)
	for _, job in pairs(jobsArray) do
		JobService.removeJob(job.UID)
	end
end

function JobService.removeJobsWithPlayerUserId(playerUserId)
	local jobsArray = JobService.getJobsWithPlayerUserId(playerUserId)
	for _, job in pairs(jobsArray) do
		JobService.removeJob(job.UID)
	end
end

function JobService.removeJobsWithCommandNameAndPlayerUserId(commandName, playerUserId)
	local jobsArray = JobService.getJobsWithCommandNameAndPlayerUserId(commandName, playerUserId)
	for _, job in pairs(jobsArray) do
		JobService.removeJob(job.UID)
	end
end

function JobService.removeJobsWithCommandNameAndOptionalPlayerUserId(commandName, optionalPlayerUserId)
	local jobsArray = JobService.getJobsWithCommandNameAndOptionalPlayerUserId(commandName, optionalPlayerUserId)
	for _, job in pairs(jobsArray) do
		JobService.removeJob(job.UID)
	end
end



return JobService