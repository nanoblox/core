local main = require(game.Nanoblox)
local httpService = game:GetService("HttpService")
local bodyUtilPathway = script.BodyUtil
local Maid = main.modules.Maid
local Signal = main.modules.Signal
local Effects = require(script.Effects)
local Buff = {}
Buff.__index = Buff



-- CONSTRUCTOR
function Buff.new(effect, property, weight)
    local self = {}
	setmetatable(self, Buff)

	local effectModule = Effects[effect]
    if not effectModule then
        error(("'%s' is not a valid Buff Effect!"):format(tostring(effect)))
    end

    local buffId = httpService:GenerateGUID(true)
    self.buffId = buffId
    self.timeUpdated = os.clock()
    local maid = Maid.new()
    self._maid = maid
    self.isDestroyed = false
    self.effect = effect
    self.additional = property
    self.weight = weight or 1
    self.updated = maid:give(Signal.new())
    self.agent = nil
    self.appliedValueTables = {}
    self.incremental = nil
    self.previousIncremental = nil
    self.accessories = {}
    self.tempBuffs = {}
    self.tempBuffDetails = {}

	return self
end



-- METHODS
function Buff:_changeValue(value)
    local newValue = value
    if typeof(value) == "BrickColor" then
        newValue = Color3.new(value.r, value.g, value.b)

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
                        local accessoryClone = self._maid:give(accessory:Clone())
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
    self.timeUpdated = os.clock()
    self:_update(true)
    return self
end

function Buff:increment(value, optionalTweenInfo)
    assert(type(value) == "number", "incremental value must be a number!")
    self.previousIncremental = self.incremental
    self.incremental = true
    self.tweenInfo = optionalTweenInfo
    self.value = self:_changeValue(value)
    self.timeUpdated = os.clock()
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
    self:_update()
    return self
end

function Buff:_update(onlyUpdateThisBuff)
    if onlyUpdateThisBuff or self.onlyUpdateThisBuff then
        self.updated:Fire(self.effect, self.additional)
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
    main.modules.Thread.delay(0.1, function()
        -- We have this delay here to prevent 'appearance' commands from resetting then immidately snapping to a new buff (as there's slight frame different between killing and executing tasks).
        self:_update()
        self._maid:clean()
    end)
    return self
end
Buff.Destroy = Buff.destroy



return Buff