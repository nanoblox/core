local commands = {
	array = {},
	dictionary = {},
}
--[[
for _, module in pairs(script:GetChildren()) do
	local moduleName = module.Name
	local tagName = "_".. (moduleName:sub(1,1)):lower()..moduleName:sub(2)
	local commandsToAdd = require(module)
	for _, command in pairs(commandsToAdd) do
		command.tags = (typeof(command.tags == "table") and command.tags) or {}
		if not table.find(command.tags, tagName) then
			table.insert(command.tags, tagName)
		end
		table.insert(commands.array, command)
		commands.dictionary[command.name] = command
	end
end--]]
return commands