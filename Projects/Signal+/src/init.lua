-- SERVICES
local players = game:GetService("Players")
local starterGui = game:GetService("StarterGui")
local replicatedStorage = game:GetService("ReplicatedStorage")



-- SETUP DIRECTORIES
local mainDirectoryName = "HDAdmin"
local function setupDirectory(directoryName, directoryParent)
	local directory = directoryParent:FindFirstChild(directoryName)
	if not directory then
		directory = Instance.new("Folder")
		directory.Name = directoryName
		directory.Parent = directoryParent
	end
	return directory
end

-- ReplicatedStorage
local directoryRs = setupDirectory(mainDirectoryName, replicatedStorage)
local signalPlusRs = setupDirectory("Signal+", directoryRs)
for a,b in pairs(script:GetChildren()) do
	b.Parent = signalPlusRs
end


print("Test automation signal+ 2")
return true