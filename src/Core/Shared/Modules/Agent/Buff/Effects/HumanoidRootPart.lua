return function(player, property)
    local char = player and player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local instancesAndProps = {}
    if hrp and tostring(property) ~= "nil" then
        instancesAndProps = {{hrp, property}}
    end
    return instancesAndProps
end