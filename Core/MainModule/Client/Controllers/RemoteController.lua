-- LOCAL
local main = require(game.HDAdmin)
local module = {}
local remotes = {}
local ERROR_START = "HD Admin | RemoteController | "
local remotesStorage = main.client.Remotes


-- METHODS
function module:getRemote(name)
	local remote = remotes[name]
	if not remote then
		local remoteFolder = remotesStorage:FindFirstChild(name)
		if not remoteFolder then
			local waitForFolder = main.modules.Signal.new()
			local childAdded = remotesStorage.ChildAdded:Connect(function(child)
				if child.Name == name then
					remoteFolder = child
					waitForFolder:Fire()
				end
			end)
			waitForFolder:Wait()
			waitForFolder:Destroy()
			childAdded:Disconnect()
			main.RunService.Heartbeat:Wait()
		end
		remote = main.modules.Remote.new(name, remoteFolder)
		remotes[name] = remote
	end
	return remote
end


-- DESTROY
remotesStorage.ChildRemoved:Connect(function(child)
	local name = child.Name
	local remote = remotes[name]
	if remote then
		remotes[name] = nil
	end
end)


return module
