return function(player)
    local instancesAndProps = {}
    if player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                table.insert(instancesAndProps, {part, "CollisionGroupId"})
            end
        end
    end
    return instancesAndProps
end