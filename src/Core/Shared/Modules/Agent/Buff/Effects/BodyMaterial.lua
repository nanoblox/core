return function(player)
    local character = player.Character
    local instancesAndProps = {}
    if character then
        for _, basePart in pairs(character:GetDescendants()) do
            if basePart:IsA("BasePart") then
                table.insert(instancesAndProps, {basePart, "Material"})
            end
        end
    end
    return instancesAndProps
end