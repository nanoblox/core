local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Destroys on hats on the player"
Command.aliases	= {"RemoveHats", "ClearAccessories", "RemoveAccessories"}
Command.opposites = {}
Command.tags = {"Appearance", "Accessory"}
Command.prefixes = {}
Command.contributors = {82347291}
Command.blockPeers = false
Command.blockJuniors = false
Command.autoPreview = false
Command.requiresRig = main.enum.HumanoidRigType.None
Command.revokeRepeats = false
Command.preventRepeats = main.enum.TriStateSetting.False
Command.cooldown = 0
Command.persistence = main.enum.Persistence.None
Command.args = {"Player"}

function Command.invoke(job, args)
	local player = unpack(args)
	-- First, clear the existing HumanoidDescription
	local humanoid = main.modules.PlayerUtil.getHumanoid(player)
	local hd = humanoid and humanoid:GetAppliedDescription()
	local arg = main.modules.Parser.Args.get("accessoryDictionary")
	if hd then
		for propertName, _ in pairs(arg.uniquePropertyNames) do
			hd[propertName] = ""
		end
		humanoid:ApplyDescription(hd)
	end
	-- Next, silently destroy any accessory related buffs (so that they don't reapply the accessories)
	-- We also clear the accessory properties if the buff value itself is a HumanoidDescription
	local agent = main.modules.PlayerUtil.getAgent(player)
	local hdBuffs = agent:getBuffsWithEffect("HumanoidDescription")
	for _, buff in pairs(hdBuffs) do
		if buff.property == nil then
			if typeof(buff.value) == "Instance" and buff.value:IsA("HumanoidDescription") then
				for propertName, _ in pairs(arg.uniquePropertyNames) do
					buff.value[propertName] = ""
				end
			end
		elseif string.match(buff.property, "Accessory") then
			buff:assassinate()
		end
	end
	-- Third, end any accessory related jobs
	local potentialJobsToClear = main.services.JobService.getJobsWithPlayerUserId(player.UserId)
	for _, potentialJob in pairs(potentialJobsToClear) do
		if potentialJob ~= job and potentialJob:findTag("Accessory") then
            potentialJob:kill()
        end
    end
	-- Finally, destroy any accessories that may remain on the character
	local character = player and player.Character
	if character then
		for _, accessory in pairs(character:GetChildren()) do
			if accessory:IsA("Accessory") then
				accessory:Destroy()
			end
		end
	end
end



return Command