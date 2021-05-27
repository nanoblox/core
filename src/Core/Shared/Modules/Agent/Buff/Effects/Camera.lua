local isClient = game:GetService("RunService"):IsClient()
local localPlayer = isClient and game:GetService("Players").LocalPlayer

if not isClient then
    warn(("'%s' buff effect cannnot be used on the server!"):format(script.Name))
end

return function(player, property)
    local instancesAndProps = {}
    if localPlayer == player then
        local camera = workspace.CurrentCamera
        instancesAndProps = {{camera, property}}
    end
    return instancesAndProps
end