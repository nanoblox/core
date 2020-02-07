-- LOCAL
local players = game:GetService("Players")
local httpService = game:GetService("HttpService")
local Signal = require(4644649679)
local Zone = {}
Zone.__index = Zone



-- CONSTRUCTOR
function Zone.new(group, regionHeight, displayBoundParts)
	local self = {}
	setmetatable(self, Zone)

	self.Group = group
	self.RegionHeight = regionHeight or 20
	self.DisplayBoundParts = displayBoundParts or false
	self.GroupParts = {}
	self.Region = self:getRegion()
	self.PreviousPlayers = {}
	self.PlayerAdded = Signal.new()
	self.PlayerRemoving = Signal.new()

	return self
end



-- METHODS
function Zone:getRegion()
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
	for _, part in pairs(self.Group:GetDescendants()) do
		if part:isA("BasePart") then
			table.insert(self.GroupParts, part)
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
	end
	local boundMin = Vector3.new(unpack(bounds.Min.Values))
	local boundMax = Vector3.new(unpack(bounds.Max.Values)) + Vector3.new(0, self.RegionHeight, 0)
	if self.DisplayBoundParts then
		local boundParts = {BoundMin = boundMin, BoundMax = boundMax}
		for boundName, boundCFrame in pairs(boundParts) do
			local part = Instance.new("Part")
			part.Anchored = true
			part.CanCollide = false
			part.Transparency = 0.5
			part.Size = Vector3.new(4,4,4)
			part.Color = Color3.fromRGB(255,0,0)
			part.CFrame = CFrame.new(boundCFrame)
			part.Name = boundName
			part.Parent = self.Group
		end
	end
	local region = Region3.new(boundMin, boundMax)
	return region
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
	local partsInRegion = workspace:FindPartsInRegion3WithWhiteList(self.Region, playerCharacters, #playersArray)
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
		local origin = hrp.Position + Vector3.new(0, 4, 0)
		local lookDirection = origin + Vector3.new(0, -1, 0)
		local ray = Ray.new(origin, (lookDirection - origin).unit * (self.RegionHeight))
		local groupPart = workspace:FindPartOnRayWithWhitelist(ray, self.GroupParts)
		if groupPart then
			return true
		end
	end
end


function Zone:getPlayers()
	local playersInRegion = self:getPlayersInRegion()
	local playersInZone = {}
	local newPreviousPlayers = {}
	for _, player in pairs(playersInRegion) do
		if self:getPlayer(player) then
			if not self.PreviousPlayers[player] then
				self.PlayerAdded:Fire(player)
			end
			table.insert(playersInZone, player)
			newPreviousPlayers[player] = true
		elseif self.PreviousPlayers[player] then
			self.PlayerRemoving:Fire(player)
		end
	end
	self.PreviousPlayers = newPreviousPlayers
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
			


return Zone