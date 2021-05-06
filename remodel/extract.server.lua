--[[
This retrieves assets under NanobloxCore/ClientOrServerOrShared/Assets and writes them into the local repository.
IMPORTANT: Ensure the rojo plugin is disconnected, then paste the following into the command line to execute:
```
remodel run remodel/extract.server.lua
```
If the plugin is not disconnected before running the command then incorrect duplicate assets will be synced into your studio place.
]]

local game = remodel.readPlaceFile("remodel/development.rbxl")
local core = game.ServerScriptService.NanobloxCore
for _, locationContainer in pairs(core:GetChildren()) do
	print(("Scanning %s..."):format(locationContainer.Name))
	local directoryPath = "src/Core/"..locationContainer.Name.."/Assets"
	local directory = remodel.createDirAll(directoryPath)
	local assets = locationContainer.Assets
	for _, asset in ipairs(assets:GetChildren()) do
		print(("Writing model '%s' to %s"):format(asset.Name, directoryPath))
		remodel.writeModelFile(asset, directoryPath.."/"..asset.Name..".rbxmx")
	end
end