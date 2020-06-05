-- LOCAL
local ZoneService = {}
local Zone = require(script.Parent.Zone)
local zones = {}



-- METHODS
function ZoneService:createZone(name, group, additionalHeight)
	local zone = zones[name]
	assert(not zones[name], ("zone '%s' already exists!"):format(name))
	assert(typeof(group) == "Instance", "bad argument #2 - zone group must be an instance (folder, model, etc)!")
	local zone = Zone.new(group, additionalHeight)
	zone.name = name
	zones[name] = zone
	return zone
end

function ZoneService:getZone(name)
	local zone = zones[name]
	if not zone then
		return false
	end
	return zone
end

function ZoneService:getAllZones()
	local allZones = {}
	for name, zone in pairs(zones) do
		table.insert(allZones, zone)
	end
	return allZones
end

function ZoneService:removeZone(name)
	local zone = zones[name]
	assert(zone, ("zone '%s' not found!"):format(name))
	zone:destroy()
	zones[name] = nil
	return true
end



return ZoneService