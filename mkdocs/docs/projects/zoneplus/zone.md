# Constructors
--------------------
### new
```lua
local zone = Zone.new(group, additionalHeight)
```
Constructs a new zone where ``group`` is an instance (such as a Model or Folder) containing parts to represent the zone, and ``additionalHeight``, a number defining how many studs to extend the zone upwards, defaulting to ``0``.



<br>



# Methods
--------------------
### update
```lua
zone:update()
```
Reconstructs the region and clusters forming the zone. Zones are dynamic (they listen for changes in children, such as the adding or removing of a part, and the resizing and positioning of these children), therefore will update automatically for you.

--------------------
### getPlayersInRegion
```lua
local players = zone:getPlayersInRegion()
```
Returns an array of players within the zones region (the rough area surrounding the zone).

--------------------
### getPlayer
```lua
local hitPart, intersection = zone:getPlayer(player)
```
If within the zone, returns the group part the player is standing on or within (a ``BasePart``) and the intersection point (a ``Vector3``), otherwise ``false``.

--------------------
### getPlayers
```lua
local players = zone:getPlayers()
```
Returns an array of players within the zone.

--------------------
### initLoop
```lua
zone:initLoop(interval)
```
Automatically initiates a loop which calls ``zone:getPlayers()`` every x second, defaults to ``0.5``.

--------------------
### endLoop
```lua
zone:endLoop()
```
Cancels any loop created with ``zone:initLoop()``.

--------------------
### getRandomPoint
```lua
local randomCFrame, hitPart, hitIntersection = zone:getRandomPoint()
```
Returns a random point ( a``CFrame``), within the zone, along with the group part (a ``BasePart``) directly below, and its intersection vector relative to the point (a ``Vector3``).

--------------------
### destroy
```lua
zone:destroy()
```
Destroys all instances, connections and signals associcated with the zone, and ends any loop running.

--------------------



<br>



# Events
--------------------
### playerAdded
```lua
zone.playerAdded
```
Fired when a player enters the zone.

!!! info Info
	``zone:getPlayers()`` must be called at frequent intervals, or zone:initLoop() once (which calls this repeatedly), for this event to function.

```lua
zone.playerAdded:Connect(function(player)

end)
```

--------------------
### playerRemoving
```lua
zone.playerRemoving
```
Fired when a player leaves the zone.

!!! info Info
	``zone:getPlayers()`` must be called at frequent intervals, or zone:initLoop() once (which calls this repeatedly), for this event to function.
    
```lua
zone.playerRemoving:Connect(function(player)

end)
```

--------------------
### updated
```lua
zone.updated
```
Fired when the zone updates (i.e. a group part is changed, such as its position or size, or a part is added or removed from the group).
```lua
zone.updated:Connect(function()

end)
```



<br>



# Properties
--------------------
### autoUpdate
```lua
zone.autoUpdate
```
A bool deciding whether the zone should automatically update when its group parts change.

--------------------
### respectUpdateQueue
```lua
zone.respectUpdateQueue
```
A bool that when set to ``true`` delays the automatic updating of the zone, preventing multiple calls within a short time period.

--------------------
### group
*(read only)*
```lua
zone.group
```
The container instance originally passed when constructing the zone.

--------------------
### groupParts
*(read only)*
```lua
zone.groupParts
```
An array of all BaseParts within ``group``. 

--------------------
### clusters
*(read only)*
```lua
zone.clusters
```
An array of clusters.

***Cluster***

A dictionary describing a collection of touching parts within the zone.

| Key                 | Value            | Desc                                                 |
| :--------------     |:--------------   | :----------------------------------------------------|
| **parts**           | *Array*          | A collection of touching parts that form the cluster |
| **region**          | *Region3*        | A region formed from the clusters parts.             |
| **volume**          | *Number*         | The volume calculated from ``region.Size``           |

--------------------
### additionalHeight
*(read only)*
```lua
zone.additionalHeight
```
The number originally passed when constructing the zone, or 0. Describes how far to extend the zone in the global Y direction.

--------------------
### region
*(read only)*
```lua
zone.region
```
A Region3 formed from ``groupParts``.

--------------------
### boundMin
*(read only)*
```lua
zone.boundMin
```
A Vector3 used to form ``region``, describing the zones minimum point.

--------------------
### boundMax
*(read only)*
```lua
zone.boundMax
```
A Vector3 used to form ``region``, describing the zones maximum point.

--------------------
### regionHeight
*(read only)*
```lua
zone.regionHeight
```
A number describing the Y-value difference between ``boundMin`` and ``boundMax``.
