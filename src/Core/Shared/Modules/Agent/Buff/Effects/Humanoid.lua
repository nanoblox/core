return function(player, property)
    local char = player and player.Character
    local humanoid = char and char:FindFirstChild("Humanoid")
    local instancesAndProps = {}
    if humanoid and tostring(property) ~= "nil" then
        instancesAndProps = {{humanoid, property}}
    end
    return instancesAndProps
end