-- LOCAL
local main = require(game.Nanoblox)
local CollisionUtil = {}



-- SETUP
local PLAYER_COLLISION_GROUP_NAME = "NanobloxPlayers"
local CLONE_COLLISION_GROUP_NAME = "NanobloxClones"
CollisionUtil.playerCollisionGroupName = PLAYER_COLLISION_GROUP_NAME
CollisionUtil.cloneCollisionGroupName = CLONE_COLLISION_GROUP_NAME
if main.isServer then
	main.PhysicsService:CreateCollisionGroup(PLAYER_COLLISION_GROUP_NAME)
	main.PhysicsService:CreateCollisionGroup(CLONE_COLLISION_GROUP_NAME)
	main.PhysicsService:CollisionGroupSetCollidable(CLONE_COLLISION_GROUP_NAME, PLAYER_COLLISION_GROUP_NAME, false)
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

function CollisionUtil.applyGroupToCharacter(character)
	CollisionUtil.setCollisionGroup(character, PLAYER_COLLISION_GROUP_NAME)
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