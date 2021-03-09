return function(player)
    local character = player.Character
    local props = {}
    if character then
        for _, basePart in pairs(character:GetDescendants()) do
            if basePart:IsA("BasePart") then
                table.insert(props, basePart)
            end
        end
    end
    return props
end