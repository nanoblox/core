-- LOCAL
local main = require(game.Nanoblox)
local CameraUtil = {}
local camera = workspace.CurrentCamera



-- METHODS
function CameraUtil.setSubject(instance)
	camera.CameraSubject = instance
end

function CameraUtil.get(propertyName)
	return camera[propertyName]
end



return CameraUtil