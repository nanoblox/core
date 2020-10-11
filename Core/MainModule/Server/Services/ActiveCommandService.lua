-- LOCAL
local main = require(game.HDAdmin)
local System = main.modules.System
local ActiveCommandService = System.new("ActiveCommands")
local systemUser = ActiveCommandService.user



-- BEGIN
function ActiveCommandService:begin()
	
end



-- EVENTS
ActiveCommandService.recordAdded:Connect(function(UID, record)
	warn(("ACTIVE_COMMAND '%s' ADDED!"):format(UID))
end)

ActiveCommandService.recordRemoved:Connect(function(UID)
	warn(("ACTIVE_COMMAND '%s' REMOVED!"):format(UID))
end)

ActiveCommandService.recordChanged:Connect(function(UID, propertyName, propertyValue, propertyOldValue)
	warn(("ACTIVE_COMMAND '%s' CHANGED %s to %s"):format(UID, tostring(propertyName), tostring(propertyValue)))
end)



-- METHODS
function ActiveCommandService.generateRecord(key)
	return {
		executionTime = os.time(),
		executionOffset = os.time() - tick(),
		userId = 0,
		commandName = "",
		commandArgs = {},
		qualifiers = {},
	}
end

function ActiveCommandService.createActiveCommand(isGlobal, properties)
	local key = (properties and properties.UID) or main.modules.DataUtil.generateUID(10)
	local record = ActiveCommandService:createRecord(key, isGlobal, properties)
	return record
end

function ActiveCommandService.getActiveCommand(name)
	return ActiveCommandService:getRecord(name)
end

function ActiveCommandService.updateActiveCommand(UID, propertiesToUpdate)
	ActiveCommandService:updateRecord(UID, propertiesToUpdate)
	return true
end

function ActiveCommandService.removeActiveCommand(UID)
	ActiveCommandService:removeRecord(UID)
	return true
end



return ActiveCommandService