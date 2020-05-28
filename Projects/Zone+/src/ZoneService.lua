-- LOCAL
local ZoneService = {}
local Zone = require(script.Parent.Zone)
local errorStart = "Zone+ | "
local zones = {}



-- METHODS
function ZoneService:createZone(name, group, additionalHeight)
	local zone = zones[name]
	if zone then
		warn(("%sFailed to create zone '%s': a zone already exists under that name."):format(errorStart, name))
		return false
	end
	if not group then
		warn(("%sFailed to create zone '%s': a group of parts must be specified as the second argument to setup a zone."):format(errorStart, name))
		return false
	end
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
	if not zone then
		warn(("%sFailed to remove Zone '%s': zone not found."):format(errorStart, name))
		return false
	end
	zone:destroy()
	zones[name] = nil
	return true
end



return ZoneService