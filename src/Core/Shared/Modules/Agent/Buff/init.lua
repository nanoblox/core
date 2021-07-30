local main = require(game.Nanoblox)
local httpService = game:GetService("HttpService")
local bodyUtilPathway = script.BodyUtil
local Janitor = main.modules.Janitor
local Signal = main.modules.Signal
local Effects = require(script.Effects)
local Buff = {}
Buff.__index = Buff



-- CONSTRUCTOR
function Buff.new(effect, property, weight, additional)
    local self = {}
	setmetatable(self, Buff)

	local effectModule = Effects[effect]
    if not effectModule then
        error(("'%s' is not a valid Buff Effect!"):format(tostring(effect)))
    end

    local buffId = (additional and additional.customBuffId) or main.modules.DataUtil.generateUID()
    self.buffId = buffId
    self.timeUpdated = os.clock()
    local janitor = Janitor.new()
    self.janitor = janitor
    self.isDestroyed = false
    self.effect = effect
    self.property = property
    self.weight = weight or 1
    self.updated = janitor:add(Signal.new(), "destroy")
    self.agent = nil
    self.appliedValueTables = {}
    self.incremental = nil
    self.previousIncremental = nil
    self.accessories = {}
    self.tempBuffs = {}
    self.tempBuffDetails = {}
    self.assignedTempBuffs = {}
    self.readyToUpdateClient = false

    if additional then
		for k, v in pairs(additional) do
			self[k] = v
		end
	end

    if self.effect == "HideCharacter" then
        table.insert(self.tempBuffDetails, {{"BodyTransparency"}, {1}})
        table.insert(self.tempBuffDetails, {{"Humanoid", "WalkSpeed"}, {0}})
        main.modules.Thread.delay(0.1, function()
            -- This allows enough time for the Humanoid to register as 'stopped'
            if not self.isDestroyed then
                local collisionId = main.modules.CollisionUtil.getIdFromName("NanobloxPlayersWithNoCollision") or 0
                table.insert(self.tempBuffDetails, {{"CollisionGroupId"}, {collisionId}})
                table.insert(self.tempBuffDetails, {{"HumanoidRootPart", "Anchored"}, {true}})
                self:_update(true)
            end
        end)
        self.requiredTempValue = true
        self:set(true)
        self:setWeight(self.weight+0.1) -- +999
        main.modules.Thread.spawn(self._update, self, true)
    end

    if main.isServer then
        self.janitor:add(main.modules.Thread.spawn(function()
            -- We delay by 1 frame as a buff method (such as :set, :setWeight, etc) may be called immediately afterwards
            if not self.isDestroyed then
                self.readyToUpdateClient = true
                local remote = self.agent.createClientBuffRemote
                remote:fireAllClients(buffId, self.effect, self.property, self.weight, self.setterMethodName, self.value)
                self.janitor:add(main.Players.PlayerAdded:Connect(function(player)
                    remote:fireClient(player, buffId, self.effect, self.property, self.weight, self.setterMethodName, self.value)
                end), "Disconnect")
            end
        end), "destroy")
    end

	return self
end



-- METHODS
function Buff:_changeValue(value)
    local newValue = value

    if typeof(value) == "BrickColor" then
        newValue = Color3.new(value.r, value.g, value.b)

    elseif self.effect == "CollisionGroupId" then
        newValue = tostring(value)

    elseif typeof(value) == "Instance" then
        if value:IsA("HumanoidDescription") then
            local function setupAccessories(container, rigTypePathways)
                for _, accessory in pairs(container:GetChildren()) do
                    if accessory:IsA("Folder") or accessory:IsA("Configuration") then
                        local r15Name = accessory:GetAttribute("R15BodyPart") or accessory.Name
                        local r6Name = accessory:GetAttribute("R6BodyPart") or accessory.Name
                        local newRigTypePathways = main.modules.TableUtil.copy(rigTypePathways)
                        table.insert(newRigTypePathways.R15, r15Name)
                        table.insert(newRigTypePathways.R6, r6Name)
                        setupAccessories(accessory, newRigTypePathways)
                    else
                        local accessoryClone = self.janitor:add(accessory:Clone(), "Destroy")
                        self.accessories[accessoryClone] = rigTypePathways
                    end
                end
            end
            setupAccessories(value, {
                R15 = {},
                R6 = {},
            })
            
            local BodyUtil = require(bodyUtilPathway)
            for _, folder in pairs(value:GetChildren()) do
                local bodyGroupName = folder.Name
                local transparencyAttribute = folder:GetAttribute("Transparency")
                if transparencyAttribute and BodyUtil.bodyGroups[bodyGroupName] and tonumber(transparencyAttribute) and transparencyAttribute ~= 0 then
                    table.insert(self.tempBuffDetails, {{"BodyTransparency", bodyGroupName}, {transparencyAttribute}})
                end
            end
        end
    end
    return newValue
end

function Buff:set(value, optionalTweenInfo)
    self.previousIncremental = self.incremental
    self.incremental = false
    self.tweenInfo = optionalTweenInfo
    self.value = self:_changeValue(value)
    self.setterMethodName = "set"
    self.timeUpdated = os.clock()
    if self.readyToUpdateClient then
        self.agent.callClientBuffRemote:fireAllClients(self.buffId, "set", value)
    end
    self:_update(true)
    return self
end

function Buff:increment(value, optionalTweenInfo)
    assert(type(value) == "number", "incremental value must be a number!")
    self.previousIncremental = self.incremental
    self.incremental = true
    self.tweenInfo = optionalTweenInfo
    self.value = self:_changeValue(value)
    self.setterMethodName = "increment"
    self.timeUpdated = os.clock()
    if self.readyToUpdateClient then
        self.agent.callClientBuffRemote:fireAllClients(self.buffId, "increment", value)
    end
    self:_update(true)
    return self
end

function Buff:decrement(value, optionalTweenInfo)
    self:increment(-value, optionalTweenInfo)
    return self
end

function Buff:setWeight(weight)
    self.weight = weight or 1
    self.timeUpdated = os.clock()
    if self.readyToUpdateClient then
        self.agent.callClientBuffRemote:fireAllClients(self.buffId, "setWeight", weight)
    end
    self:_update()
    return self
end

function Buff:_update(onlyUpdateThisBuff)
    if onlyUpdateThisBuff or self.onlyUpdateThisBuff then
        self.updated:Fire(self.effect, self.property)
    else
        self.updated:Fire()
    end
end

function Buff:_getAppliedValueTable(effect, instance)
    local parentTab = self.appliedValueTables[effect]
    if not parentTab then
        parentTab = {}
        self.appliedValueTables[effect] = parentTab
    end
    local tab = parentTab[instance]
    if not tab then
        tab = {}
        parentTab[instance] = tab
    end
    return tab
end

function Buff:destroy()
    if self.isDestroyed then return end
    self.isDestroyed = true
    if self.readyToUpdateClient then
        self.agent.callClientBuffRemote:fireAllClients(self.buffId, "destroy")
    end
    main.modules.Thread.delay(0.1, function()
        -- We have this delay here to prevent 'appearance' commands from resetting then immidately snapping to a new buff (as there's slight frame different between killing and executing tasks).
        self:_update()
        self.janitor:destroy()
    end)
    return self
end
Buff.Destroy = Buff.destroy



return Buff