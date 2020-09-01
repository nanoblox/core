local main = {
	called = false,
}


-- INITIATE
function main:initiate()
	if self.called then
		return false
	end
	self.called = true
	
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
	local isStudio = main.RunService:IsStudio()
	local mainGroupName = "HDAdmin"
	local serverMainGroup = isServer and main.ServerStorage[mainGroupName].Core
	local clientMainGroup = main.ReplicatedStorage[mainGroupName].Core
	local location = (isServer and "server") or "client"
	main.isServer = isServer
	main.isStudio = isStudio
	main.server = serverMainGroup and serverMainGroup.Server
	main.client = clientMainGroup.Client
	main.sharedModules = clientMainGroup.SharedModules
	main.location = location
	main.locationGroup = main[location]
	main.modules = {}
	main.services = {}
	main.controllers = {}
	
	
	-- CLIENT DETAILS
	if location == "client" then
		main.localPlayer = main.Players.LocalPlayer
	elseif location == "server" then
		main.config = require(serverMainGroup.Config)
	end
	
	
	-- MODULE LOADER
	local Thread
	local function loadModule(module, modulePathway)
		
		-- Check is a module
		if not module:IsA("ModuleScript") then
			return
		end
		
		-- Adapt module name to alias
		local moduleName = module.Name
		
		-- Retrieve module data
		local success, moduleData = pcall(function() return require(module) end)
		
		-- Warn of module error
		if not success then
			warn(mainGroupName.." Error |",module.Name,"|",moduleData)
		
		-- If module already exists, merge conetents
		elseif rawget(modulePathway, moduleName) then
			for funcName, func in pairs(moduleData) do
				if tonumber(funcName) then
					table.insert(modulePathway[moduleName], func)
				else
					main[modulePathway][funcName] = func
				end
			end
			
		-- Else setup new module and call init()
		else
			modulePathway[moduleName] = moduleData
			if type(moduleData) == "table" then
				-- Setup pathway for children
				local isChildren = module:FindFirstChildOfClass("ModuleScript")
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
								if rawget(childModuleData, "start") then
									Thread.spawnNow(function()
										childModuleData:start()
									end)
								end
								return childModuleData
							end
						end
					})
					
				end
				-- Call init
				if rawget(moduleData, "init") then
					moduleData:init()
				end
			end
		end
		
		return moduleData
	end
	
	
	-- EASY-LOAD MODULES
	setmetatable(main.modules, {
	    __index = function(_, index)
			local moduleFolders = {main.locationGroup.Modules, main.sharedModules}
			for _, moduleFolder in pairs(moduleFolders) do
				for _, module in pairs(moduleFolder:GetChildren()) do
					local moduleName = module.Name
					if moduleName == index then
						local moduleData = loadModule(module, main.modules)
						if rawget(moduleData, "start") then
							Thread.spawnNow(function()
								moduleData:start()
							end)
						end
						return moduleData
					end
				end
			end
	    end
	})
	Thread = main.modules.Thread
	main.enum = main.modules.EnumHandler:getEnums()
	
	
	-- SERVICES / CONTROLLERS
	local serviceFolder = (main.server and main.server.Services) or main.client.Controllers
	local serviceGroupName = serviceFolder.Name:lower()
	local serviceGroup = main[serviceGroupName]
	for _, module in pairs(serviceFolder:GetChildren()) do
		loadModule(module, main[serviceGroupName])
	end
	for moduleName, moduleData in pairs(serviceGroup) do
		if type(moduleData) == "table" and moduleData.start then
			Thread.spawnNow(function()
				moduleData:start()
			end)
		end
	end
	
	
	-- COMPLETE
	main._initiated = true
	if main._initiatedSignal then
		main._initiatedSignal:Fire()
	end
	
end


function main:getFramework()
	if not main._initiated then
		local signal = main._initiatedSignal
		if not signal then
			local Signal = require(main.ReplicatedStorage.HDAdmin.Signal)
			signal = Signal.new()
			main._initiatedSignal = signal
		end
		signal:Wait()
	end
	return main
end


return main