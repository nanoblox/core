Zone+ is a lightweight application that utilises regions and raycasting to efficiently determine players within an area.

# Resources
- [Repository](https://github.com/1ForeverHD/HDAdmin/tree/master/Projects)
- [MainModule](https://www.roblox.com/library/4664437268/Zone)
- [Playground](https://www.roblox.com/games/4664430724/Zone)
- [Thread](https://devforum.roblox.com/t/zone-retrieving-players-within-an-area-zone/397465)
- [TypeScript Port by DanzLua](https://www.npmjs.com/package/@rbxts/zone-plus)

# Collaborate
Zone+ is an open-source project; all contributions are much appreciated. You're welcome to report bugs, suggest features and make pull requests at our repository.

# Referencing
After requiring the MainModule, Zone+ modules can be referenced on the server and client under the HDAdmin directory in ReplicatedStorage.

| Location                 | Pathway            |
| :--------------     |:--------------   |
| Server       | ``MainModule`` or ``ReplicatedStorage:WaitForChild("HDAdmin"):WaitForChild("Zone+")``   |
| Client       | ``ReplicatedStorage:WaitForChild("HDAdmin"):WaitForChild("Zone+")``   |

# Example (server-sided)
On the server:
```lua
local ZonePlus = require(4664437268) -- Initiate Zone+
local ZoneService = require(ZonePlus.ZoneService) -- Retrieve and require ZoneService
local group = workspace.YourGroupHere -- A container (i.e. Model or Folder) of parts that represent the zone
local zone = ZoneService:createZone("ZoneName", group, 15) -- Construct a zone called 'ZoneName' using 'group' and with an extended height of 15 
local playersInZone = zone:getPlayers() -- Retrieves an array of players within the zone
```

# Example (client-sided)
Zone+ is primarily intended for server-sided use, however also supports client use.

On the server:
```lua
require(4664437268) -- Initiate Zone+
```

On the client:
```lua
local ZoneService = require(game:GetService("ReplicatedStorage"):WaitForChild("HDAdmin"):WaitForChild("Zone+").ZoneService)
local group = workspace.YourGroupHere
local zone = ZoneService:createZone("ZoneName", group, 15)
local playersInZone = zone:getPlayers()
```

# Uses
For coded examples, visit the Zone+ Playground.

------------------------------

### Safe Zone (1)
Setup a zone with an arbitrary space (using the ``additionalHeight`` parameter), retrieve all players within the zone at frequent intervals, and apply or remove a forcefield accordingly. This example also generates 2000 random parts as a visual representation of ``additionalHeight``.

<a><img src="https://i.imgur.com/rhAnDH7.gif" width="100%"/></a>

------------------------------

### Safe Zone (2)
Detect and apply a forcefield to players within an uncancollided red zone using the ``playerAdded`` and ``playerRemoving`` events.

<a><img src="https://i.imgur.com/IHt0Ozf.gif" width="100%"/></a>

------------------------------

### Coin Spawner
Randomly generate coins a few studs above any surface within the zone.

<a><img src="https://i.imgur.com/ZUS5xhQ.gif" width="100%"/></a>

------------------------------

### Voting Pads
Utilise zones to determine the amount of players on a particular pad.

<a><img src="https://i.imgur.com/rJlHmEv.gif" width="100%"/></a>