local main = require(game.Nanoblox)
local Commands = {}



local function setupCommands(group, tags)
	local groupClass = group.ClassName
	local thisTag = (groupClass == "Folder" or groupClass == "Configuration") and group.Name:lower()
	local newTags = tags and {table.unpack(tags)} or {}
	if thisTag then
		table.insert(newTags, thisTag)
	end
	for _, instance in pairs(group:GetChildren()) do
		if instance:IsA("ModuleScript") then
			local command = require(instance)
			local UID = instance.Name
			command.tags = (typeof(command.tags == "table") and command.tags) or {}
			command.UID = UID
			for _, tagToAdd in pairs(newTags) do
				table.insert(command.tags, tagToAdd)
			end
			local client = instance:FindFirstChild("Client") or instance:FindFirstChild("client")
			if client then
				client.Name = UID
				client.Parent = main.shared.Modules.ClientCommands
			end
			if Commands[UID] then
				warn(("Duplicate Nanoblox command detected: '%s'"):format(UID))
			end
			Commands[UID] = command
		else
			setupCommands(instance, newTags)
		end
	end
end
setupCommands(script)



return Commands