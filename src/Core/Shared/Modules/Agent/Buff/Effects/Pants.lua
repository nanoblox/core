return function(player)
    local pants = player.Character and player.Character:FindFirstChildOfClass("Pants")
    local instancesAndProps = {}
    if pants then
        instancesAndProps = {{pants, "PantsTemplate"}}
    end
    return instancesAndProps
end