return function(player)
    local shirt = player.Character and player.Character:FindFirstChildOfClass("Shirt")
    local instancesAndProps = {}
    if shirt then
        instancesAndProps = {{shirt, "ShirtTemplate"}}
    end
    return instancesAndProps
end