local localPlayer = game:GetService("RunService"):IsClient() and game:GetService("Players").LocalPlayer
return function(player, property)
    local instancesAndProps = {}
    if localPlayer == player then
        local camera = workspace.CurrentCamera
        instancesAndProps = {{camera, property}}
    end
    return instancesAndProps
end