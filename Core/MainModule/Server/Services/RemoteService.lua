-- LOCAL
local main = require(game.HDAdmin)
local module = {}
local remotes = {}


-- METHODS
function module:createRemote(name, requestLimit, refreshInterval)
	assert(not remotes[name], ("remote '%s' already exists!"):format(name))
	local remote = main.modules.Remote.new(name, requestLimit, refreshInterval)
	remote.folder.Parent = main.client.Remotes
	remotes[name] = remote
	return remote
end

function module:getRemote(name)
	local remote = remotes[name]
	if not remote then
		return false
	end
	return remote
end

function module:removeRemote(name)
	local remote = remotes[name]
	assert(remote, ("remote '%s' not found!"):format(name))
	remote:destroy()
	remotes[name] = nil
	return true
end


return module