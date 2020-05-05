-- LOCAL
local players = game:GetService("Players")
local httpService = game:GetService("HttpService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(replicatedStorage:WaitForChild("HDAdmin"):WaitForChild("Signal"))
local Zone = {}
Zone.__index = Zone



-- CONSTRUCTOR
function Zone.new(group, additionalHeight)
	local self = {}
	setmetatable(self, Zone)

	self.group = group
	self.additionalHeight = additionalHeight or 0
	self.previousPlayers = {}
	self.playerAdded = Signal.new()
	self.playerRemoving = Signal.new()
	self.instances = {}
	
	local groupParts = {}
	local groupPartsCopy = {}
	for _, part in pairs(group:GetDescendants()) do
		if part:isA("BasePart") then
			table.insert(groupParts, part)
			table.insert(groupPartsCopy, part)
		end
	end
	self.groupParts = groupParts
	
	local clusters = {}
	local totalVolume = 0
	local function getTouchingParts(part)
		local connection = part.Touched:Connect(function() end)
		local results = part:GetTouchingParts()
		connection:Disconnect()
		local whitelistResult = {}
		for _, touchingPart in pairs(results) do
			if table.find(groupPartsCopy, touchingPart) then
				table.insert(whitelistResult, touchingPart)
			end
		end
		return whitelistResult
	end
	for _, part in pairs(groupPartsCopy) do
		local scanned = {part = true}
		local parts = {}
		local function formCluster(partToScan)
			table.insert(parts, partToScan)
			local touchingParts = getTouchingParts(partToScan)
			for _, touchingPart in pairs(touchingParts) do
				local i = table.find(groupPartsCopy, touchingPart)
				if i then
					table.remove(groupPartsCopy, i)
				end
				if not scanned[touchingPart] then
					scanned[touchingPart] = true
					formCluster(touchingPart)
				end
			end
		end
		formCluster(part)
		local region = self:getRegion(parts)
		local size = region.Size
		local volume = size.X * size.Y * size.Z
		totalVolume = totalVolume + volume
		table.insert(clusters, {
			region = region,
			parts = parts,
			size = size,
			volume = volume,
		})
	end
	for part, details in pairs(clusters) do
		details.weight = details.volume/totalVolume
	end
	self.clusters = clusters
	
	local extra = Vector3.new(4, 4, 4)
	local region, boundMin, boundMax = self:getRegion(groupParts)
	self.region = Region3.new(boundMin-extra, boundMax+extra)
	self.boundMin = boundMin
	self.boundMax = boundMax
	self.regionHeight = boundMax.Y - boundMin.Y
	
	return self
end



-- METHODS
function Zone:displayBounds()
	if not self.displayBoundParts then
		self.displayBoundParts = true
		local boundParts = {BoundMin = self.boundMin, BoundMax = self.boundMax}
		for boundName, boundCFrame in pairs(boundParts) do
			local part = Instance.new("Part")
			part.Anchored = true
			part.CanCollide = false
			part.Transparency = 0.5
			part.Size = Vector3.new(4,4,4)
			part.Color = Color3.fromRGB(255,0,0)
			part.CFrame = CFrame.new(boundCFrame)
			part.Name = boundName
			part.Parent = self.group
			table.insert(self.instances, part)
		end
	end
end

function Zone:getRegion(tableOfParts)
	local bounds = {["Min"] = {}, ["Max"] = {}}
	for boundType, details in pairs(bounds) do
		details.Values = {}
		function details.parseCheck(v, currentValue)
			if boundType == "Min" then
				return (v <= currentValue)
			elseif boundType == "Max" then
				return (v >= currentValue)
			end
		end
		function details:parse(valuesToParse)
			for i,v in pairs(valuesToParse) do
				local currentValue = self.Values[i] or v
				if self.parseCheck(v, currentValue) then
					self.Values[i] = v
				end
			end
		end
	end
	for _, part in pairs(tableOfParts) do
		local sizeHalf = part.Size * 0.5
		local corners = {
			part.CFrame * CFrame.new(-sizeHalf.X, -sizeHalf.Y, -sizeHalf.Z),
			part.CFrame * CFrame.new(-sizeHalf.X, -sizeHalf.Y, sizeHalf.Z),
			part.CFrame * CFrame.new(-sizeHalf.X, sizeHalf.Y, -sizeHalf.Z),
			part.CFrame * CFrame.new(-sizeHalf.X, sizeHalf.Y, sizeHalf.Z),
			part.CFrame * CFrame.new(sizeHalf.X, -sizeHalf.Y, -sizeHalf.Z),
			part.CFrame * CFrame.new(sizeHalf.X, -sizeHalf.Y, sizeHalf.Z),
			part.CFrame * CFrame.new(sizeHalf.X, sizeHalf.Y, -sizeHalf.Z),
			part.CFrame * CFrame.new(sizeHalf.X, sizeHalf.Y, sizeHalf.Z),
		}
		for _, cornerCFrame in pairs(corners) do
			local x, y, z = cornerCFrame:GetComponents()
			local values = {x, y, z}
			bounds.Min:parse(values)
			bounds.Max:parse(values)
		end
	end
	local boundMin = Vector3.new(unpack(bounds.Min.Values))
	local boundMax = Vector3.new(unpack(bounds.Max.Values)) + Vector3.new(0, self.additionalHeight, 0)
	local region = Region3.new(boundMin, boundMax)
	return region, boundMin, boundMax
end


function Zone:getPlayersInRegion()
	local playersArray = players:GetPlayers()
	local playerCharacters = {}
	for _, player in pairs(playersArray) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			table.insert(playerCharacters, hrp)
		end
	end
	local one = playerCharacters[1]
	local partsInRegion = workspace:FindPartsInRegion3WithWhiteList(self.region, playerCharacters, #playersArray)
	local charsChecked = {}
	local playersInRegion = {}
	if #partsInRegion > 0 then
		for _, part in pairs(partsInRegion) do
			local char = part.Parent
			if not charsChecked[char] then
				charsChecked[char] = true
				local player = players:GetPlayerFromCharacter(char)
				if player then
					table.insert(playersInRegion, player)
				end
			end
		end
	end
	return playersInRegion
end


function Zone:getPlayer(player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		local charOffset = hrp.Size.Y * -1.5
		local origin = hrp.Position + Vector3.new(0, self.regionHeight + charOffset, 0)
		local lookDirection = origin + Vector3.new(0, -1, 0)
		local ray = Ray.new(origin, (lookDirection - origin).unit * (self.additionalHeight + self.regionHeight))
		local groupPart = workspace:FindPartOnRayWithWhitelist(ray, self.groupParts)
		if groupPart then
			return true
		end
	end
	return false
end


function Zone:getPlayers()
	local playersInRegion = self:getPlayersInRegion()
	local playersInZone = {}
	local newPreviousPlayers = {}
	local oldPreviousPlayers = self.previousPlayers
	local playersAdded = {}
	-- Check for players in zone
	for _, player in pairs(playersInRegion) do
		if self:getPlayer(player) then
			if not oldPreviousPlayers[player] then
				table.insert(playersAdded, player)
			end
			newPreviousPlayers[player] = true
			table.insert(playersInZone, player)
		end
	end
	-- Update record of players before firing events otherwise the recursive monster will visit in your sleep
	self.previousPlayers = newPreviousPlayers
	-- Fire PlayerAdded event if necessary
	for _, player in pairs(playersAdded) do
		self.playerAdded:Fire(player)
	end
	-- Check if any players left zone
	for player, _ in pairs(oldPreviousPlayers) do
		if not newPreviousPlayers[player] then
			self.playerRemoving:Fire(player)
		end
	end 
	return playersInZone
end



function Zone:initLoop(loopDelay)
	loopDelay = tonumber(loopDelay) or 0.5
	local loopId = httpService:GenerateGUID(false)
	self.currentLoop = loopId
	if not self.loopInitialized then
		self.loopInitialized = true
		coroutine.wrap(function()
			while self.currentLoop == loopId do
				wait(loopDelay)
				self:getPlayers()
			end
		end)()
	end
end

function Zone:endLoop()
	self.currentLoop = nil
end

function Zone:getRandomPoint()
	local pointCFrame
	repeat
		local parts, region 
		local randomWeight = math.random()
		local totalWeight = 0.01
		for _, details in pairs(self.clusters) do
			totalWeight = totalWeight + details.weight
			if totalWeight >= randomWeight then
				parts, region = details.parts, details.region
				break
			end
		end
		local size = region.Size
		local cframe = region.CFrame
		local random = Random.new()
		local randomCFrame = cframe * CFrame.new(random:NextNumber(-size.X/2,size.X/2), random:NextNumber(-size.Y/2,size.Y/2), random:NextNumber(-size.Z/2,size.Z/2))
		local origin = randomCFrame.p
		local lookDirection = origin + Vector3.new(0, -1, 0)
		local ray = Ray.new(origin, (lookDirection - origin).unit * (self.additionalHeight + self.regionHeight))
		local validPart = workspace:FindPartOnRayWithWhitelist(ray, parts)
		if validPart then
			pointCFrame = randomCFrame
		end
	until pointCFrame
	return pointCFrame
end

function Zone:destroy()
	self:endLoop()
	for signalName, signal in pairs(self) do
		if type(signal) == "table" and signal.Destroy then
			signal:Destroy()
		end
	end
	for _, instance in pairs(self.instances) do
		instance:Destroy()
	end
end
			


return Zone