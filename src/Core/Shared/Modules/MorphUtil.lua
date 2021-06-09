-- LOCAL
local main = require(game.Nanoblox)
local MorphUtil = {}



-- METHODS
function MorphUtil.loadBundleId(bundleIdToParse)
	return main.modules.Promise.defer(function(resolve, reject)
		-- Check valid number
		local bundleId = tonumber(bundleIdToParse)
		if not bundleId then
			return reject(string.format("'%s' must be a number instead of '%s'!", "BundleDescription", tostring(bundleIdToParse)))
		end
		-- Check if bundle has already been cached
		local storageDetail = main.modules.Parser.Args.getStorage("BundleDescription")
		local cachedItem = storageDetail:get(bundleIdToParse)
		if cachedItem then
			return resolve(cachedItem)
		end
		-- Verify is an actual bundle and save if it is
		local success, bundleDetails = pcall(function() return main.AssetService:GetBundleDetailsAsync(bundleId) end)
		if not success then
			return reject(string.format("Unable to load bundle details from bundleId '%s'.", tostring(bundleIdToParse)))
		end
		local description
		for _, item in next, bundleDetails.Items do
			if item.Type == "UserOutfit" then
				success, description = pcall(function() return main.Players:GetHumanoidDescriptionFromOutfitId(item.Id) end)
				if not success then
					return reject(string.format("Bundle '%s' failed to load: %s", bundleIdToParse, tostring(description)))
				end
				break
			end
		end
		if not description then
			return reject(string.format("Unable to load bundle description from bundleId '%s'.", tostring(bundleIdToParse)))
		end
		storageDetail:cache(bundleIdToParse, description)
		resolve(description)
	end)
end

function MorphUtil.getDescriptionFromBundleId(bundleIdToParse, humanoid)
	return main.modules.Promise.defer(function(resolve, reject)
		local storageDetail = main.modules.Parser.Args.getStorage("BundleDescription")
		local cachedDescription = storageDetail:get(bundleIdToParse)
		if not cachedDescription then
			local success, loadedDescription = main.modules.MorphUtil.loadBundleId(bundleIdToParse):await()
			if not success then
				return reject(loadedDescription)
			end
			cachedDescription = loadedDescription
		end
		local description = cachedDescription
		if humanoid then
			description = humanoid:GetAppliedDescription()
			local defaultDescription = Instance.new("HumanoidDescription")
			for _, property in next, {"BackAccessory", "BodyTypeScale", "ClimbAnimation", "DepthScale", "Face", "FaceAccessory", "FallAnimation", "FrontAccessory", "GraphicTShirt", "HairAccessory", "HatAccessory", "Head", "HeadColor", "HeadScale", "HeightScale", "IdleAnimation", "JumpAnimation", "LeftArm", "LeftArmColor", "LeftLeg", "LeftLegColor", "NeckAccessory", "Pants", "ProportionScale", "RightArm", "RightArmColor", "RightLeg", "RightLegColor", "RunAnimation", "Shirt", "ShouldersAccessory", "SwimAnimation", "Torso", "TorsoColor", "WaistAccessory", "WalkAnimation", "WidthScale"} do
				local cachedProperty = cachedDescription[property]
				if cachedProperty ~= defaultDescription[property] and cachedProperty ~= Color3.fromRGB(163, 162, 165) then -- property is not the default value
					description[property] = cachedProperty
				end
			end
			defaultDescription:Destroy()
		end
		resolve(description)
	end)
end

function MorphUtil._getDescriptionPromise(userIdOrUsername)
	return main.modules.Promise.new(function(resolve, reject)
		local userId
		local itemType = typeof(userIdOrUsername)
		if itemType == "number" then
			userId = userIdOrUsername
		elseif itemType == "string" then
			local success, value = main.modules.PlayerUtil.getUserIdFromName(userIdOrUsername):await()
			if not success then
				return reject(value)
			end
			userId = value
		end
		local storageDetail = main.modules.Parser.Args.getStorage("UserDescription")
		local cachedDescription = storageDetail:get(userId)
		if cachedDescription then
			return resolve(cachedDescription)
		end
		local success, description = pcall(function() return main.Players:GetHumanoidDescriptionFromUserId(userId) end)
		if not success then
			return reject(description)
		end
		storageDetail:cache(userId, description)
		resolve(description)
	end)
end

function MorphUtil.getDescriptionFromUserId(userId)
	return MorphUtil._getDescriptionPromise(userId)
end

function MorphUtil.getDescriptionFromUsername(username)
	return MorphUtil._getDescriptionPromise(username)
end

function MorphUtil.getDescriptionFromPlayer(player)
	local character = player and player.Character
	return MorphUtil.getDescriptionFromCharacter(character)
end

function MorphUtil.getDescriptionFromCharacter(character)
	local humanoid = character and character:FindFirstChild("Humanoid")
	local description = humanoid and humanoid:GetAppliedDescription()
	return description
end



return MorphUtil