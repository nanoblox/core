local Directory = {}



-- SERVICES
local players = game:GetService("Players")
local starterGui = game:GetService("StarterGui")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")



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
		folder = Instance.new("Folder")
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
			playerPathway = "PlayerGui.Nanoblox",--"PlayerScripts",
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

function Directory.merge(sourceArg, targetArg, keepSource)
	local source = (keepSource and sourceArg:Clone()) or sourceArg
	local target = targetArg
	local sourceClass = source.ClassName
	local targetClass = target.ClassName
	if sourceClass == targetClass then
		if sourceClass == "ModuleScript" then
			local sourceRef = require(source)
			local targetRef = require(target)
			if type(sourceRef) == "table" and type(targetRef) == "table" then
				for key, value in pairs(sourceRef) do
					targetRef[key] = value
				end
			end
			source:Destroy()
			return
		end
		if sourceClass == "Model" or sourceClass == "Folder" or sourceClass == "Configuration" then
			for _, sourceChild in pairs(source) do
				local targetChild = target:FindFirstChild(sourceChild.Name)
				if not targetChild then
					sourceChild.Parent = target
				else
					Directory.merge(sourceChild, targetChild)
				end
			end
			source:Destroy()
			return
		end
	end
	local targetParent = target.Parent
	target:Destroy()
	source.Parent = targetParent
end



return Directory