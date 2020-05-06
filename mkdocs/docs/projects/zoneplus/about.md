Zone+ is a lightweight application that utilises regions and raycasting to efficiently determine players within an area.

# Resources
- [Repository](https://github.com/1ForeverHD/HDAdmin/tree/master/Projects)
- [MainModule](https://www.roblox.com/library/4664437268/Zone)
- [Playground](https://www.roblox.com/games/4664430724/Zone)
- [Thread](https://devforum.roblox.com/t/zone-retrieving-players-within-an-area-zone/397465)

# Collaborate
Zone+ is an open-source project; all contributions are much appreciated. You're welcome to report bugs, suggest features and make pull requests at [our repository](https://github.com/1ForeverHD/HDAdmin/tree/master/Projects).

# Referencing
After requiring the MainModule, Zone+ modules can be referenced on the client under the HDAdmin directory in ReplicatedStorage.

| Location                 | Pathway            |
| :--------------     |:--------------   |
| Server       | ``MainModule`` or ``ReplicatedStorage:WaitForChild("HDAdmin"):WaitForChild("Zone+")``   |
| Client       | ``ReplicatedStorage:WaitForChild("HDAdmin"):WaitForChild("Zone+")``   |

# Examples

## Safe Zone
In a server script:
```lua
-- LOCAL
local ZonePlus = require(4664437268)
local ZoneService = require(ZonePlus.ZoneService)
local group = workspace.SafeZone1
local zone = ZoneService:createZone("SafeZone1", group, 15)
local connectionAdded = zone.playerAdded:Connect(function(player)
	print(player.Name, "entered zone:", zone.name)
end)
local connectionRemoving = zone.playerRemoving:Connect(function(player)
	print(player.Name, "exited zone:", zone.name)
end)
zone:initLoop()
```

## Events
In a server script:
```lua
-- LOCAL
local ZonePlus = require(4664437268)
local ZoneService = require(ZonePlus.ZoneService)
local group = workspace.SafeZone1
local zone = ZoneService:createZone("SafeZone1", group, 15)
local connectionAdded = zone.playerAdded:Connect(function(player)
	print(player.Name, "entered zone:", zone.name)
end)
local connectionRemoving = zone.playerRemoving:Connect(function(player)
	print(player.Name, "exited zone:", zone.name)
end)
zone:initLoop()
```