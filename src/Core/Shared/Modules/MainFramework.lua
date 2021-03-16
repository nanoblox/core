local main = {
	called = false,
}


-- INITIATE
function main.initiate(loader)
	if main.called then
		return false
	end
	main.called = true
	
	-- ROBLOX SERVICES
	-- To index a service, do main.ServiceName (e.g. main.Players, main.TeleportService, main.TweenService, etc)
	setmetatable(main, {
		__index = function(this, index)
			local pass, service
			if index == "ChatService" then
				pass, service = true, require(main.ServerScriptService:WaitForChild("ChatServiceRunner"):WaitForChild("ChatService"))
			else
				pass, service = pcall(game.GetService, game, index)
			end
			if pass then
				this[index] = service
				return service
			end
		end
	})
	
	
	-- SHARED DETAILS
	local isServer = main.RunService:IsServer()
	local isClient = not isServer
	local isStudio = main.RunService:IsStudio()
	local location = (isServer and "server") or "client"
	main.isServer = isServer
	main.isClient = isClient
	main.isStudio = isStudio
	main.shared = main.ReplicatedStorage.Nanoblox.Shared
	main.location = location
	main.modules = {}
	main.services = {}
	
	
	-- LOCATION SPECIFIC DETAILS
	if isServer then
		main.server = main.ServerStorage.Nanoblox.Server
		main.locationGroup = main.server
		main.loader = loader
		main.config = require(loader.Config)
	elseif isClient then
		main.client = main.ReplicatedStorage.Nanoblox.Client
		main.locationGroup = main.client
		main.controllers = {}
		main.localPlayer = main.Players.LocalPlayer
	end
	
	
	-- MODULE LOADER
	local Thread
	local Directory = require(main.shared.Assets.Directory)
	local function loadModule(module, modulePathway, doNotYield)
		
		-- Check is a module
		if not module:IsA("ModuleScript") then
			return
		end
		
		-- Adapt module name to alias
		local moduleName = module.Name
		
		-- Retrieve module data
		local moduleData = Directory.requireModule(module)
		
		-- There should not be two-of-the same module:module, service:service or controlle:controller so throw an error
		if rawget(modulePathway, moduleName) then
			error(("%s duplicate detected!"):format(moduleName))
			
		-- Else setup new module and call init()
		else
			modulePathway[moduleName] = moduleData
			if type(moduleData) == "table" then
				-- Setup pathway for children
				local isChildren = not rawget(moduleData, "_standalone") and module:FindFirstChildOfClass("ModuleScript")
				if isChildren then
					local children = {}
					for _, childModule in pairs(module:GetChildren()) do
						if childModule:IsA("ModuleScript") then
							children[childModule.Name] = childModule
						end
					end
					setmetatable(moduleData, {
						__index = function(_, index)
							local childModule = children[index]
							if childModule then
								children[index] = nil
								local childModuleData = loadModule(childModule, moduleData)
								return childModuleData
							end
						end
					})
					
				end
				-- Call init
				if rawget(moduleData, "init") then
					if doNotYield then
						Thread.spawnNow(function() moduleData.init() end)
					else
						moduleData.init()
					end
				end
			end
		end
		
		return moduleData
	end
	
	
	-- EASY-LOAD MODULES
	setmetatable(main.modules, {
	    __index = function(_, index)
			local moduleFolders = {main.locationGroup.Modules, main.shared.Modules}
			for _, moduleFolder in pairs(moduleFolders) do
				for _, module in pairs(moduleFolder:GetChildren()) do
					local moduleName = module.Name
					if moduleName == index then
						local moduleData = loadModule(module, main.modules, true)
						return moduleData
					end
				end
			end
	    end
	})
	main.enum = main.modules.Enum.getEnums()
	Thread = main.modules.Thread
	
	
	-- SERVICES / CONTROLLERS
	local serviceFolder = (main.server and main.server.Services) or main.client.Controllers
	local serviceGroupName = serviceFolder.Name:lower()
	local serviceGroup = main[serviceGroupName]
	local orderedServices = {}
	local function setupServiceOrController(module, groupName)
		local moduleData = loadModule(module, main[groupName])
		if type(moduleData) == "table" then
			moduleData._order = moduleData._order or 100
			table.insert(orderedServices, module.Name)
		end
	end
	for _, module in pairs(serviceFolder:GetChildren()) do
		setupServiceOrController(module, serviceGroupName)
	end
	local sharedServiceFolder = main.shared:FindFirstChild("Services")
	if sharedServiceFolder then
		for _, module in pairs(serviceFolder:GetChildren()) do
			setupServiceOrController(module, "services")
		end
	end
	
	-- Define order to call service methods based upon any present '_order' values
	table.sort(orderedServices, function(a, b) return serviceGroup[a]._order < serviceGroup[b]._order end)
	local function callServiceMethod(methodName)
		for i, moduleName in pairs(orderedServices) do
			local moduleData = serviceGroup[moduleName]
			local method = type(moduleData) == "table" and moduleData[methodName]
			if method then
				Thread.spawnNow(function()
					method(moduleData)
				end)
			end
		end
	end
	
	-- Once all services initialised, create relavent remotes and call start
	--[[
	-- Disabled as readibility is more important than a slight boost in efficiency
	for i, moduleName in pairs(orderedServices) do
		local moduleData = serviceGroup[moduleName]
		local remotes = type(moduleData) == "table" and moduleData.remotes
		if type(remotes) == "table" then
			for int, val in ipairs(remotes) do
				local remoteName = moduleName.."_"..val
				remotes[val] = main.modules.Remote.new(remoteName)
				remotes[i] = nil
			end
		end
	end--]]
	callServiceMethod("start")
	main._started = true
	if main._startedSignal then
		main._startedSignal:Fire()
	end
	
	-- If server, wait for all system data to load, then call .begin()
	if location == "server" then
		local ConfigService = main.services.ConfigService
		if not ConfigService.setupComplete then
			ConfigService.setupCompleteSignal:Wait()
		end
		callServiceMethod("begin")
	end
	main._begun = true
	if main._begunSignal then
		main._begunSignal:Fire()
	end
	
end



local function setupSignalLoader(propertyName)
	if not main[propertyName] then
		local eventName = propertyName.."Signal"
		local bindableEvent = main[eventName]
		if not bindableEvent then
			bindableEvent = Instance.new("BindableEvent")
			main[eventName] = bindableEvent
		end
		bindableEvent.Event:Wait()
		main.RunService.Heartbeat:Wait()
		if bindableEvent then
			bindableEvent:Destroy()
		end
	end
end

function main.waitUntilStarted()
	setupSignalLoader("_started")
end

function main.waitUntilBegun()
	setupSignalLoader("_begun")
end

function main.getFramework()
	main.waitUntilBegun()
	return main
end


return main