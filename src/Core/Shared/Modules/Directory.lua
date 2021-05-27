local Directory = {}



-- SERVICES
local players = game:GetService("Players")
local starterGui = game:GetService("StarterGui")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local EARLY_JOINER_GUI_NAME = "NanobloxEarlyJoiner"



-- LOCAL FUNCTIONS
local function createFolder(folderName, folderParent)
	local folder
	for a,b in pairs(folderParent:GetChildren()) do
		if not b:IsA("Configuration") and b.Name == folderName then
			folder = b
			break
		end
	end
	if not folder then
        if folderName == EARLY_JOINER_GUI_NAME then
		    folder = Instance.new("ScreenGui")
            folder.ResetOnSpawn = false
        else
            folder = Instance.new("Folder")
        end
		folder.Name = folderName
		folder.Parent = folderParent
	end
	return folder
end

local function getPathwayTable(pathway)
	return pathway:split(".")
end

local function setupDirectory(pathwayTable, startParent, finalFunction)
	local currentParent = startParent
	local total = #pathwayTable
	for i = 1, total do
		local folderName = pathwayTable[i]
		local folder = createFolder(folderName, currentParent)
		if i == total and finalFunction then
			return(finalFunction(folder))
		end
		currentParent = folder
	end
end



-- METHODS
function Directory.getLocationDetails(location)
	local realLocations = {
		["ServerStorage"] = {
			realLocation = game:GetService("ServerStorage"),
		},
		["ReplicatedStorage"] = {
			realLocation = game:GetService("ReplicatedStorage"),
		},
		["StarterGui"] = {
			realLocation = game:GetService("StarterGui"),
			playerPathway = "PlayerGui",
		},
		["StarterPlayerScripts"] = {
			realLocation = game:GetService("StarterPlayer").StarterPlayerScripts,
			playerPathway = "PlayerGui."..EARLY_JOINER_GUI_NAME, -- For early joiners, we add it to "PlayerGui.NanobloxEarlyJoiner" instead of "PlayerScripts" as this is the only client location to replicated from server to client
        },
		["StarterCharacterScripts"] = {
			realLocation = game:GetService("StarterPlayer").StarterCharacterScripts,
			playerPathway = "Character",
		},
	}
	return realLocations[location]
end

function Directory.createDirectory(pathway, contents)
	local pathwayTable = getPathwayTable(pathway)
	local location = table.remove(pathwayTable, 1)
	local locationDetails = Directory.getLocationDetails(location)
	local currentParent = locationDetails.realLocation
	local finalFunction = function(finalFolder)
		local playerPathway = locationDetails.playerPathway
		if playerPathway then
			local playerPathwayTable = getPathwayTable(playerPathway)
			local playerFinalFunction = function(playerFinalFolder)
				for _, object in pairs(contents) do
					if not playerFinalFolder:FindFirstChild(object.Name) then
						object:Clone().Parent = playerFinalFolder
					end
				end
			end
			for _, plr in pairs(players:GetPlayers()) do
				coroutine.wrap(function()
					local character = plr.Character or plr.CharacterAdded:Wait()
					runService.Heartbeat:Wait()
					setupDirectory(playerPathwayTable, plr, playerFinalFunction)
				end)()
			end
		end
		for _, object in pairs(contents) do
			if not finalFolder:FindFirstChild(object.Name) then
				object.Parent = finalFolder
			end
		end
		return finalFolder
	end
	if #pathwayTable == 0 then
		return(finalFunction(currentParent))
	end
	return(setupDirectory(pathwayTable, currentParent, finalFunction))
end

--local MERGED_MODULE_NAME = "NanobloxModuleToMerge"
function Directory.merge(source, target, keepSource, treatSourceAsContainer)
	local sourceClass = source.ClassName
	local targetClass = target.ClassName
	if sourceClass == targetClass or treatSourceAsContainer then
		if (sourceClass == "Folder" or sourceClass == "Configuration" or treatSourceAsContainer) then
			for _, sourceChild in pairs(source:GetChildren()) do
				local targetChild = target:FindFirstChild(sourceChild.Name)
				if not targetChild then
					local newSourceChild = (keepSource and sourceChild:Clone()) or sourceChild
					newSourceChild.Parent = target
				else
					Directory.merge(sourceChild, targetChild)
				end
			end
			if not keepSource then
				source:Destroy()
			end
			return
		elseif sourceClass == "ModuleScript" then
			-- I was originally intending for modules to merge together although after more consideration this is quite restrictive and confusing
			-- Instead I'll just have the source module replace the target module entirely
			--[[
			local newSource = (keepSource and source:Clone()) or source
			newSource.Name = MERGED_MODULE_NAME
			newSource.Parent = target
			return
			--]]
		end
	end
	local targetParent = target.Parent
	target:Destroy()
	local newSource = (keepSource and source:Clone()) or source
	newSource.Parent = targetParent
end

function Directory.requireModule(module)
	local success, moduleData = pcall(function() return require(module) end)
	if not success then
		error(("Module '%s' failed to load: %s"):format(tostring(module.Name), moduleData))
	end
	local moduleToMerge = nil--module:FindFirstChild(MERGED_MODULE_NAME)
	if moduleToMerge then
		local moduleToMergeData = require(moduleToMerge)
		if type(moduleData) == "table" and type(moduleToMergeData) == "table" then
			for key, value in pairs(moduleToMergeData) do
				moduleData[key] = value
			end
		end
		moduleToMerge:Destroy()
	end
	return moduleData
end

-- This moves and replaces any matching children
function Directory.move(source, newParent)
	local sourceName = source.Name
	local target = newParent:FindFirstChild(sourceName)
	local targetClass = target and target.ClassName
	if source.ClassName == targetClass and (targetClass == "Folder" or targetClass == "Configuration") then
		for _, childSource in pairs(source:GetChildren()) do
			Directory.move(childSource, target)
		end
	else
		if target then
			target:Destroy()
		end
		source.Parent = newParent
	end
end



return Directory