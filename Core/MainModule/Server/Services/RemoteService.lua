-- LOCAL
local main = require(game.HDAdmin)
local RemoteService = {}
local remotes = {}


-- METHODS
function RemoteService.createRemote(name, requestLimit, refreshInterval)
	assert(not remotes[name], ("remote '%s' already exists!"):format(name))
	local remote = main.modules.Remote.new(name, requestLimit, refreshInterval)
	remote.folder.Parent = main.client.Remotes
	remotes[name] = remote
	return remote
end

function RemoteService.getRemote(name)
	local remote = remotes[name]
	if not remote then
		return false
	end
	return remote
end


function RemoteService.getRemotes()
	local allRemotes = {}
	for name, remote in pairs(remotes) do
		table.insert(allRemotes, remote)
	end
	return allRemotes
end

function RemoteService.removeRemote(name)
	local remote = remotes[name]
	assert(remote, ("remote '%s' not found!"):format(name))
	remote:destroy()
	remotes[name] = nil
	return true
end


return RemoteService