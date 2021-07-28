local main = require(game.Nanoblox)
local CloneController = {}

function CloneController.start()
    local Clone = main.modules.Clone
    Clone.workspaceStorage = main.workspaceFolder[Clone.storageName]
    Clone.replicatedStorage = main.ReplicatedStorage.Nanoblox[Clone.storageName]

    -- This is to fix an internal Roblox bug that incorrectly creates two Waist joints within a clones torso
    -- when HumanoidDescription:ApplyDescription is called on the server
    local trackingClones = {}
    local function trackClone(cloneCharacter)
        if not trackingClones[cloneCharacter] then
            trackingClones[cloneCharacter] = true
            local function trackTorso(torso)
                local function getWaists()
                    local waists = {}
                    for _, waist in pairs(torso:GetChildren()) do
                        if waist.Name == "Waist" then
                            table.insert(waists, waist)
                        end
                    end
                    return waists
                end
                local waists = getWaists()
                if #waists > 1 then
                    waists[1]:Destroy()
                end
            end
            local torso = cloneCharacter:FindFirstChild("UpperTorso") -- R6 does not have a Waist so it's not checked for
            if torso then
                trackTorso(torso)
                cloneCharacter.ChildAdded:Connect(function(child)
                    main.RunService.Heartbeat:Wait()
                    if child.Name == "UpperTorso" then
                        trackTorso(child)
                    end
                end)
            end
        end
    end
    Clone.workspaceStorage.ChildAdded:Connect(function(cloneCharacter)
        trackClone(cloneCharacter)
    end)
    for _, cloneCharacter in pairs(Clone.workspaceStorage:GetChildren()) do
        trackClone(cloneCharacter)
    end
end

return CloneController
