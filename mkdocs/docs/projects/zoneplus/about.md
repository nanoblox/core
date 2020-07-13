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
In a ``Script`` within ``ServerScriptService``:
```lua
local ZonePlus = require(4664437268) -- Initiate Zone+
local ZoneService = require(ZonePlus.ZoneService) -- Retrieve and require ZoneService
local group = workspace.YourGroupHere -- A container (i.e. Model or Folder) of parts that represent the zone
local zone = ZoneService:createZone("ZoneName", group, 15) -- Construct a zone called 'ZoneName' using 'group' and with an extended height of 15 

local playersInZone = zone:getPlayers() -- Retrieves an array of players within the zone

zone.playerAdded:Connect(function(player) -- Fires when a player enters the zone
    print(player.Name.." entered!")
end)
zone.playerRemoving:Connect(function(player)  -- Fires when a player exits the zone
    print(player.Name.." left!")
end)
zone:initLoop() -- Initiates loop (default 0.5) which enables the events to work
```

# Example (client-sided)
In a ``Script`` within ``ServerScriptService``:
```lua
require(4664437268) -- Initiate Zone+
```

Then in a ``LocalScript`` within ``StarterPlayerScripts``:
```lua
local ZonePlus = game:GetService("ReplicatedStorage"):WaitForChild("HDAdmin"):WaitForChild("Zone+")
local ZoneService = require(ZonePlus.ZoneService)
local group = workspace.YourGroupHere
local zone = ZoneService:createZone("ZoneName", group, 15)
local localPlayer = game:GetService("Players").LocalPlayer

local isClientInZone = zone:getPlayer(localPlayer) -- Checks whether the local player is within the zone

zone.playerAdded:Connect(function() -- Fires when the localPlayer enters the zone
    print(localPlayer.Name.." entered!")
end)
zone.playerRemoving:Connect(function()  -- Fires when the localPlayer exits the zone
    print(localPlayer.Name.." left!")
end)
zone:initClientLoop() -- Initiates loop (default 0.5) which *only* checks for the local player, enabling events to work
```

!!! info Info
    It's important you use methods such as ``zone:getPlayer(localPlayer)`` and ``zone:initClientLoop()`` (instead of ``zone:getPlayers()`` and ``zone:initLoop()``) if you only intend to check for the local player.

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

------------------------------

### Ambient Areas
Play sounds within specific areas.

!!!note Note
    This example is client-sided and found within StarterPlayerScripts in the Topbar+ Playground.

<video src="https://thumbs.gfycat.com/TangibleFamiliarBufeo-mobile.mp4" controls></video>