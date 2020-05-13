# Constructors
--------------------
### new
```lua
Zone.new(group, additionalHeight)
```
Constructs a new zone where ``group`` is an instance (such as a Model or Folder) containing parts to represent the zone, and ``additionalHeight``, a number defining how many studs to extend the zone upwards, defaulting to ``0``.



<br>



# Methods
--------------------
### update
```lua
Zone:update()
```
Reconstructs the region and clusters forming the zone.

--------------------
### getPlayersInRegion
```lua
Zone:getPlayersInRegion()
```
Returns an array of players within the zones region (the rough area surrounding the zone).

--------------------
### getPlayer
```lua
Zone:getPlayer(player)
```
Returns the group part the player is standing on or within if in the zone, otherwise ``false``.

--------------------
### getPlayers
```lua
Zone:getPlayers()
```
Returns an array of players within the zone.

--------------------
### initLoop
```lua
Zone:initLoop(interval)
```
Automatically initiates a loop which calls ``Zone:getPlayers()`` every x second, defaults to ``0.5``.

--------------------
### endLoop
```lua
Zone:endLoop()
```
Cancels any loop created with ``Zone:initLoop()``.

--------------------
### getRandomPoint
```lua
Zone:getRandomPoint()
```
Returns a random point, a CFrame value, within the zone, along with the group part directly below, and its intersection vector relative to the point.

```
local randomCFrame, hitPart, hitIntersection = zone:getRandomPoint()
```

--------------------
### destroy
```lua
Zone:destroy()
```
Destroys all instances, connections and signals associcated with the zone, and ends any loop running.

--------------------



<br>



# Events
--------------------
### playerAdded
```lua
Zone.playerAdded
```
Fired when a player enters the zone.

!!! info Info
	``Zone:getPlayers()`` must be called at frequent intervals, or Zone:initLoop() once (which calls this repeatedly), for this event to function.

```lua
Zone.playerAdded:Connect(function(player))

end)
```

--------------------
### playerRemoving
```lua
Zone.playerRemoving
```
Fired when a player leaves the zone.

!!! info Info
	``Zone:getPlayers()`` must be called at frequent intervals, or Zone:initLoop() once (which calls this repeatedly), for this event to function.
    
```lua
Zone.playerRemoving:Connect(function(player))

end)
```

--------------------
### updated
```lua
Zone.updated
```
Fired when the zone updates (i.e. a group part is changed, such as its position or size, or a part is added or removed from the group).
```lua
Zone.updated:Connect(function())

end)
```



<br>



# Properties
--------------------
### autoUpdate
```lua
Zone.autoUpdate
```
A bool deciding whether the zone should automatically update when its group parts change.

--------------------
### respectUpdateQueue
```lua
Zone.respectUpdateQueue
```
A bool that when set to ``true`` delays the automatic updating of the zone, preventing multiple calls within a short time period.

--------------------
### group
*(read only)*
```lua
Zone.group
```
The container instance originally passed when constructing the zone.

--------------------
### groupParts
*(read only)*
```lua
Zone.groupParts
```
An array of all BaseParts within ``group``. 

--------------------
### clusters
*(read only)*
```lua
Zone.clusters
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
Zone.additionalHeight
```
The number originally passed when constructing the zone, or 0. Describes how far to extend the zone in the global Y direction.

--------------------
### region
*(read only)*
```lua
Zone.region
```
A Region3 formed from ``groupParts``.

--------------------
### boundMin
*(read only)*
```lua
Zone.boundMin
```
A Vector3 used to form ``region``, describing the zones minimum point.

--------------------
### boundMax
*(read only)*
```lua
Zone.boundMax
```
A Vector3 used to form ``region``, describing the zones maximum point.

--------------------
### regionHeight
*(read only)*
```lua
Zone.regionHeight
```
A number describing the Y-value difference between ``boundMin`` and ``boundMax``.