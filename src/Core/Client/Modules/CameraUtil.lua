-- LOCAL
local main = require(game.Nanoblox)
local camera = workspace.CurrentCamera
local CameraUtil = {
	camera = camera
}



-- METHODS
function CameraUtil.setSubject(instance)
	camera.CameraSubject = instance
end

function CameraUtil.get(propertyName)
	return camera[propertyName]
end



return CameraUtil