# Methods

--------------------
### createZone
```lua
ZoneService:createZone(name, group, additionalHeight)
```
Creates, stores and returns a zone, where ``name`` is a unique string identifying the zone, ``group``, an instance (such as a Model or Folder) containing parts to represent the zone, and ``additionalHeight``, a number defining how many studs to extend the zone upwards, defaulting to ``0``.

--------------------
### getZone
```lua
ZoneService:getZone(name)
```
Returns a zone of the corresponding name.

--------------------
### getAllZones
```lua
ZoneService:getAllZones()
```
Returns an array containing every zone.

--------------------
### removeZone
```lua
ZoneService:removeZone(name)
```
Destroys and removes references of the corresponding zone.
