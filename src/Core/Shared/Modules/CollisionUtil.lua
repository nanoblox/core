-- LOCAL
local main = require(game.Nanoblox)
local CollisionUtil = {}



-- SETUP
local collisionGroupNames = {"NanobloxPlayers", "NanobloxClones", "NanobloxPlayersWithNoCollision"}
if main.isServer then
	for _, name in pairs(collisionGroupNames) do
		main.PhysicsService:CreateCollisionGroup(name)
	end
	main.PhysicsService:CollisionGroupSetCollidable("NanobloxClones", "NanobloxPlayers", false)
	main.PhysicsService:CollisionGroupSetCollidable("NanobloxPlayersWithNoCollision", "Default", false)
	main.PhysicsService:CollisionGroupSetCollidable("NanobloxPlayersWithNoCollision", "NanobloxPlayers", false)
end



-- METHODS
function CollisionUtil.setCollisionGroup(object, groupName, ignoreDescendantCheck)
    if object:IsA("BasePart") then
        main.PhysicsService:SetPartCollisionGroup(object, groupName)
    end
	if typeof(object) == "Instance" then
		for _, child in pairs(object:GetChildren()) do
			CollisionUtil.setCollisionGroup(child, groupName, true)
		end
		if not ignoreDescendantCheck then
			object.DescendantAdded:Connect(function(descendant)
				CollisionUtil.setCollisionGroup(descendant, groupName, true)
			end)
		end
	end
end

function CollisionUtil.getIdFromName(collisionGroupName)
	return main.PhysicsService:GetCollisionGroupId(collisionGroupName)
end

function CollisionUtil.applyGroupToCharacter(character)
	CollisionUtil.setCollisionGroup(character, "NanobloxPlayers")
end

function CollisionUtil.joinPlayerCollisionGroup(player)
	if player.Character then
		CollisionUtil.applyGroupToCharacter(player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		CollisionUtil.applyGroupToCharacter(character)
	end)
end



return CollisionUtil