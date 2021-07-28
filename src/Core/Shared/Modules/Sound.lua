-- LOCAL
local main = require(game.Nanoblox)
local Sound = {
    sounds = {}
}



-- FUNCTIONS
function Sound.getSound(soundId)
    for soundInstance, sound in pairs(Sound.sounds) do
        if sound.soundId == soundId then
            return sound
        end
    end
end

function Sound.getSoundByInstance(soundInstance)
    return Sound.sounds[soundInstance]
end

function Sound.getOrCreateSound(soundId, soundType)
    local sound = Sound.getSound(soundId)
    if not sound then
        sound = Sound.new(soundId, soundType)
    end
    return sound
end



-- CONSTRUCTOR
function Sound.new(soundId, soundType)
	local self = {}
    local objectPropertiesToUpdate = {
        SoundId = function(value)
            local newValue = tonumber(tostring(soundId):match("%d+")) or 0
            self.soundId = newValue
            return newValue
        end,
    }
    local meta = {
        __index = function(table, index)
            local propertyOrMethod = rawget(Sound, index)
            if propertyOrMethod then
                return propertyOrMethod
            end
            local soundInstance = rawget(self, "soundInstance")
            local success, returnValue = pcall(function() return soundInstance[index] end)
            if not success then
                return nil
            end
            if typeof(returnValue) == "function" then
                returnValue = {}
                setmetatable(returnValue, {
                    __call = function(table, passingTable, ...)
                        soundInstance[index](soundInstance, ...)
                    end,
                })
            end
            return returnValue
        end,
        __newindex = function(table, index, value)
            local updatePropFunc = objectPropertiesToUpdate[index]
            if updatePropFunc then
                updatePropFunc(value)
            end
            if rawget(self, index) then
                self[index] = value
            else
                rawget(self, "soundInstance")[index] = value
            end
        end,
    }
    
    local janitor = main.modules.Janitor.new()
    local settingModule = (main.isServer and main.services.SettingService) or main.controllers.SettingController
    local soundIdParsed = objectPropertiesToUpdate.SoundId(soundId)
    local soundInstance = janitor:add(Instance.new("Sound"), "Destroy")
    local soundTypeFinal = soundType or (main.isServer and main.enum.SoundType.Command) or (main.isClient and main.enum.SoundType.Interface)
    local soundTypeName = main.enum.SoundType.getName(soundTypeFinal)
    soundInstance.SoundId = "rbxassetid://"..soundIdParsed
    soundInstance:SetAttribute("NanobloxSoundType", soundTypeName)
    
    self.janitor = janitor
    self.soundId = soundIdParsed
    self.soundInstance = soundInstance
    self.soundType = soundTypeFinal
    self.soundTypeName = soundTypeName
    self.isDestroyed = false
    self.originalValues = {}
    self.settingModule = settingModule
    self.changedJanitor = janitor:add(main.modules.Janitor.new(), "Destroy")
    self.updateSoundFunction = false
    
    setmetatable(self, meta)

    local defaultSoundProperties = settingModule.getPlayerSetting("soundProperties")
    for propertyName, _ in pairs(defaultSoundProperties) do
        self.originalValues[propertyName] = soundInstance[propertyName]
    end

    if main.isClient then
        self.updateSoundFunction = function(propertyName, settingValue)
            local currentValue = self.originalValues[propertyName]
            local modifiedValue = currentValue * settingValue
            self:untrackChanges(propertyName)
            soundInstance[propertyName] = modifiedValue
            self:trackChanges(propertyName)
        end
        local soundProperties = settingModule.getPlayerSetting("soundProperties")
        for propertyName, typeValues in pairs(soundProperties) do
            self.updateSoundFunction(propertyName, typeValues[self.soundTypeName])
            janitor:add(typeValues.changed:Connect(function(settingName, value)
                if settingName == self.soundTypeName then
                    self.updateSoundFunction(propertyName, value)
                end
            end), "Disconnect")
        end
    end

    if main.isServer then
        self.updateSoundFunction = function(propertyName, settingValue, player)
            local currentValue = self.originalValues[propertyName]
            local modifiedValue = currentValue * settingValue
            main.services.SoundService.remotes.updateSoundProperty:fireClient(player, soundInstance, propertyName, modifiedValue)
        end
        local function updateSounds(player)
            -- This ensures the Sound instance is replicated to the client
            local originalParent = soundInstance.Parent
            pcall(function() soundInstance.Parent = player.PlayerGui end)
            soundInstance.Parent = originalParent
            -- Delay by a frame to ensure PlayerService creates the User
            main.modules.Thread.spawn(function()
                local user = main.modules.PlayerStore:getUser(player)
                if not user then
                    return
                end
                user:waitUntilLoaded()
                if self.isDestroyed then
                    return
                end
                local soundProperties = settingModule.getUsersPlayerSetting(user, "soundProperties")
                for propertyName, typeValues in pairs(soundProperties) do
                    self.updateSoundFunction(propertyName, typeValues[self.soundTypeName], player)
                    janitor:add(typeValues.changed:Connect(function(settingName, value)
                        if settingName == self.soundTypeName then
                            self.updateSoundFunction(propertyName, value, player)
                        end
                    end), "Disconnect")
                end
            end)
        end
        for _, player in pairs(main.Players:GetPlayers()) do
            updateSounds(player)
        end
        janitor:add(main.Players.PlayerAdded:Connect(function(player)
            updateSounds(player)
        end), "Disconnect")
    end

    self:trackChanges()

    Sound.sounds[soundInstance] = self

    return self
end
Sound.createSound = Sound.new



-- METHODS
function Sound:clone()
    return Sound.new(self.soundId, self.soundType)
end
Sound.Clone = Sound.clone

function Sound:trackChanges(specificPropertyName)
    -- This listens for changes to the Volume, Pitch, etc
    local propertyCaps = {
        Default = 5,
        Pitch = 2.5,
        Volume = 5,
    }
    local defaultSoundProperties = self.settingModule.getPlayerSetting("soundProperties")
    for propertyName, _ in pairs(defaultSoundProperties) do
        if specificPropertyName == nil or propertyName == specificPropertyName then
            local totalChangesThisFrame = 0
            self.changedJanitor:add(self.soundInstance:GetPropertyChangedSignal(propertyName):Connect(function(a,b,c)
                -- Clients can modify sounds on a scale between 0-2, therefore we cap properties at half their limit
                local value = self.soundInstance[propertyName]
                local cap = propertyCaps[propertyName] or propertyCaps.Default
                if value > cap then
                    self.soundInstance[propertyName] = cap
                    return
                end
                totalChangesThisFrame += 1
                main.modules.Thread.spawn(function()
                    totalChangesThisFrame -= 1
                end)
                local only1ChangeSoFar = totalChangesThisFrame == 1
                if only1ChangeSoFar then
                    self.originalValues[propertyName] = value
                end
                local playersToUpdate = (main.isServer and main.Players:GetPlayers()) or {main.localPlayer}
                for _, player in pairs(playersToUpdate) do
                    local soundProperties = (main.isServer and self.settingModule.getUsersPlayerSetting(main.modules.PlayerStore:getUser(player), "soundProperties")) or self.settingModule.getPlayerSetting("soundProperties")
                    local settingValue = soundProperties[propertyName][self.soundTypeName]
                    self.updateSoundFunction(propertyName, settingValue, player)
                end
                if not only1ChangeSoFar then
                    self.originalValues[propertyName] = value
                end
            end), "Disconnect", propertyName)
        end
    end
end

function Sound:untrackChanges(specificPropertyName)
    local defaultSoundProperties = self.settingModule.getPlayerSetting("soundProperties")
    for propertyName, _ in pairs(defaultSoundProperties) do
        if specificPropertyName == nil or propertyName == specificPropertyName then
            self.changedJanitor:remove(propertyName)
        end
    end
end

function Sound:destroy()
    Sound.sounds[self.soundInstance] = nil
    self.janitor:destroy()
    self.isDestroyed = true
end
Sound.Destroy = Sound.destroy



return Sound