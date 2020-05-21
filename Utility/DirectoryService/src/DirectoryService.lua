local module = {}



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
function module:getLocationDetails(location)
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
			playerPathway = "PlayerGui.HDAdmin",--"PlayerScripts",
		},
		["StarterCharacterScripts"] = {
			realLocation = game:GetService("StarterPlayer").StarterCharacterScripts,
			playerPathway = "Character",
		},
	}
	return realLocations[location]
end

function module:createDirectory(pathway, contents)
	local pathwayTable = getPathwayTable(pathway)
	local location = table.remove(pathwayTable, 1)
	local locationDetails = self:getLocationDetails(location)
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



return module