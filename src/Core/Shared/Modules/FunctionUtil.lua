-- LOCAL
local main = require(game.Nanoblox)
local FunctionUtil = {}



-- METHODS
function FunctionUtil.preventMultiFrameUpdates(func)
	-- This prevents the funtion being called twice within a single frame
	-- If called more than once, the function will initally be delayed again until the next frame, then all others cancelled
	local callsThisFrame = 0
	local updatedThisFrame = false
	local newFunc = function(...)
		callsThisFrame += 1
		if not updatedThisFrame then
			local args = table.pack(...)
			main.modules.Thread.spawn(function()
				updatedThisFrame = false
				if callsThisFrame > 1 then
					callsThisFrame = 1
					return func(unpack(args))
				end
				callsThisFrame = 0
			end)
			updatedThisFrame = true
			return func(...)
		end
	end
	return newFunc
end



return FunctionUtil