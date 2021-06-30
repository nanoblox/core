-- LOCAL
local Sound = {}
local main = require(game.Nanoblox)



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
            local returnValue = soundInstance[index]
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
    
    local maid = main.modules.Maid.new()
    local soundIdParsed = objectPropertiesToUpdate.SoundId(soundId)
    local soundInstance = maid:give(Instance.new("Sound"))
    soundInstance.SoundId = "rbxassetid://"..soundIdParsed
    
    self.maid = maid
    self.soundId = soundIdParsed
    self.soundInstance = soundInstance
    self.soundType = soundType or (main.isServer and main.enum.SoundType.Command) or (main.isClient and main.enum.SoundType.Interface)
    self.soundTypeName = main.enum.SoundType.getName(self.soundType)
    self.destroyed = false
    
    setmetatable(self, meta)

    if main.isServer then
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
                if self.destroyed then
                    return
                end
                local playerSettings = user.perm:getOrSetup("playerSettings")
                local soundProperties = main.services.SettingService.getUsersPlayerSetting(user, "soundProperties")
                local clientProperties = {}
                local SoundService = main.services.SoundService
                for propertyName, typeValues in pairs(soundProperties) do
                    local setting = playerSettings:getOrSetup(propertyName)
                    clientProperties[propertyName] = typeValues[self.soundTypeName]
                    maid:give(setting.changed:Connect(function(settingName, value)
                        if settingName == self.soundTypeName then
                            SoundService.remotes.updateSoundProperties:fireClient(player, soundInstance, {
                                [propertyName] = value
                            })
                        end
                    end))
                end
                SoundService.remotes.updateSoundProperties:fireClient(player, soundInstance, clientProperties)
            end)
        end
        for _, player in pairs(main.Players:GetPlayers()) do
            updateSounds(player)
        end
        maid:give(main.Players.PlayerAdded:Connect(function(player)
            updateSounds(player)
        end))
    end

    return self
end



-- METHODS
function Sound:clone()
    return Sound.new(self.soundId, self.soundType)
end
Sound.Clone = Sound.clone

function Sound:destroy()
    self.maid:clean()
    self.destroyed = true
end
Sound.Destroy = Sound.destroy



return Sound