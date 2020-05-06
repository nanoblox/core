Zone+ is a lightweight application that utilises regions and raycasting to efficiently determine players within an area.

# Resources
- [Repository](https://github.com/1ForeverHD/HDAdmin/tree/master/Projects)
- [MainModule](https://www.roblox.com/library/4664437268/Zone)
- [Playground](https://www.roblox.com/games/4664430724/Zone)
- [Thread](https://devforum.roblox.com/t/zone-retrieving-players-within-an-area-zone/397465)
- [TypeScript Port by DanzLua](https://www.npmjs.com/package/@rbxts/zone-plus)

# Collaborate
Zone+ is an open-source project; all contributions are much appreciated. You're welcome to report bugs, suggest features and make pull requests at [our repository](https://github.com/1ForeverHD/HDAdmin/tree/master/Projects).

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

<details>
  <summary>Safe Zone (using additionalHeight, a loop and 2000 randomly generated parts)</summary>
  
```lua
-- Get ZoneService
local ZonePlus = require(4664437268)
local ZoneService = require(ZonePlus.ZoneService)


-- Setup zone
local group = workspace.SafeZone1
local zone = ZoneService:createZone("SafeZone1", group, 15)


-- Generate 2000 random parts within zone - not necessary, it just looks cool :)
for i = 1,2000 do
	local randomCFrame = zone:getRandomPoint()
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 0.5
	part.Size = Vector3.new(1,1,1)
	part.Color = Color3.fromRGB(0, 255, 255)
	part.CFrame = randomCFrame
	part.Parent = workspace
end


-- Create a safe zone by checking for players within the zone every X seconds
local players = game:GetService("Players")
local safeZoneCheckInterval = 0.2
local forceFieldName = "PineappleDoesNotGoOnPizza"
local forceFieldTemplate = Instance.new("ForceField")
forceFieldTemplate.Name = forceFieldName

while true do
	wait(safeZoneCheckInterval)
	
	-- Get players in zone
	local playersInZone = zone:getPlayers()
	local playersInZoneDictionary = {}
	for _, plr in pairs(playersInZone) do
		playersInZoneDictionary[plr] = true
	end
	
	-- Add/remove forcefield accordingly
	for _, plr in pairs(players:GetPlayers()) do
		local char = plr.Character
		local forceField = char and char:FindFirstChild(forceFieldName)
		if playersInZoneDictionary[plr] then
			if not forceField then
				forceField = forceFieldTemplate:Clone()
				forceField.Parent = char
			end
		elseif forceField then
			forceField:Destroy()
		end
	end
	
end
```
  
</details>

<a><img src="https://i.imgur.com/rhAnDH7.gif" width="100%"/></a>





<details>
  <summary>Safe Zone (using uncancollided parts and zone events)</summary>
  
```lua
-- Get ZoneService
local ZonePlus = require(4664437268)
local ZoneService = require(ZonePlus.ZoneService)


-- Setup zone
local group = workspace.SafeZone2
local zone = ZoneService:createZone("SafeZone2", group, 0)


-- Create a safe zone by listening for players entering and leaving the zone
local safeZoneCheckInterval = 0.2
local forceFieldName = "PineapplesForLife"
local forceFieldTemplate = Instance.new("ForceField")
forceFieldTemplate.Name = forceFieldName

local connectionAdded = zone.playerAdded:Connect(function(player)
	local char = player.Character
	local forceField = char and char:FindFirstChild(forceFieldName)
	if not forceField then
		forceField = forceFieldTemplate:Clone()
		forceField.Parent = char
	end
end)
local connectionRemoving = zone.playerRemoving:Connect(function(player)
	local char = player.Character
	local forceField = char and char:FindFirstChild(forceFieldName)
	if forceField then
		forceField:Destroy()
	end
end)
zone:initLoop(safeZoneCheckInterval)
```
  
</details>

<a><img src="https://i.imgur.com/IHt0Ozf.gif" width="100%"/></a>





<details>
  <summary>Coin Spawner</summary>
  
```lua
-- Get ZoneService
local ZonePlus = require(4664437268)
local ZoneService = require(ZonePlus.ZoneService)


-- Setup zone
local group = workspace.CoinSpawner
local zone = ZoneService:createZone("CoinSpawner", group, 15)


-- Spawn coins within a random position in the zone, and position equal distances above the ground
local distanceAboveGround = 4
local totalCoins = 40

local coinTemplate = Instance.new("Part")
coinTemplate.Name = "Coin"
coinTemplate.Anchored = true
coinTemplate.CanCollide = false
coinTemplate.Transparency = 0
coinTemplate.Size = Vector3.new(1,4,4)
coinTemplate.Color = Color3.fromRGB(255, 176, 0)
coinTemplate.Reflectance = 0.3
coinTemplate.Shape = Enum.PartType.Cylinder
coinTemplate.Parent = nil

local function spawnCoin()
	local randomCFrame, hitPart, hitIntersection = zone:getRandomPoint()
	local coin = coinTemplate:Clone()
	coin.CFrame = CFrame.new(hitIntersection + Vector3.new(0, distanceAboveGround, 0))
	coin.Touched:Connect(function()
		spawnCoin()
		coin:Destroy()
	end)
	coin.Parent = workspace
end

for i = 1, totalCoins do
	spawnCoin()
end
```
  
</details>

<a><img src="https://i.imgur.com/ZUS5xhQ.gif" width="100%"/></a>





<details>
  <summary>Voting Pads</summary>
  
```lua
-- Get ZoneService
local ZonePlus = require(4664437268)
local ZoneService = require(ZonePlus.ZoneService)


-- Config
local voteTime = 10


-- Vote
local votePads = workspace.VotingPads
local voteMachine = workspace.VoteMachine9000
local container = voteMachine.SurfaceGui.Container
local votes = container.Votes
local status = container.Status

local function beginVote()
	
	-- Setup voting zones
	local zones = {}
	for _, group in pairs(votePads:GetChildren()) do
		local zoneName = group.Name
		local frame = votes[zoneName]
		local zone = ZoneService:createZone(zoneName, group, 15)
		local function updateVote(increment)
			zone.votes = zone.votes + increment
			frame.TextLabel.Text = zone.votes
		end
		zone.votes = 0
		zone.playerAdded:Connect(function(player)
			updateVote(1)
		end)
		zone.playerRemoving:Connect(function(player)
			updateVote(-1)
		end)
		zone:initLoop(0.1)
		updateVote(0)
		frame.Visible = true
		table.insert(zones, zone)
	end
	
	-- Countdown
	for i = 1, voteTime do
		status.Text = ("Vote! (%s)"):format(voteTime+1-i)
		wait(1)
	end
	
	-- Determine winner
	local winners = {}
	local winningScore = 0
	for _, zone in pairs(zones) do
		local score = zone.votes
		if score > winningScore then
			winningScore = score
		end
	end
	for _, zone in pairs(zones) do
		local score = zone.votes
		local frame = votes[zone.name]
		if score == winningScore then
			frame.Visible = true
			table.insert(winners, zone)
		else
			frame.Visible = false
		end
		ZoneService:removeZone(zone.name)
	end
	
	-- Display results
	if winningScore == 0 then
		status.Text = "No votes were made."
	elseif #winners > 1 then
		status.Text = "It's a tie!"
	else
		status.Text = ("The winner is %s!"):format(winners[1].name)
	end
	wait(3)
	
	-- Hide frames and restart
	status.Text = "Beginning new round..."
	for _, frame in pairs(votes:GetChildren()) do
		frame.Visible = false
	end
	wait(1)
	
end

while true do
	beginVote()
	wait(1)
end
```
  
</details>

<a><img src="https://i.imgur.com/rJlHmEv.gif" width="100%"/></a>