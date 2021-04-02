local BodyUtil = require(script.Parent.Parent.BodyUtil)

return function(player, additional)
    local instancesAndProps = {}
    local parts = BodyUtil.getPartsByBodyGroup(player, additional)
    for _, part in pairs(parts) do
        table.insert(instancesAndProps, {part, "Transparency"})
        if part.Name == "Head" then
            local face = part:FindFirstChild("face") or part:FindFirstChildOfClass("Decal")
            if face then
                table.insert(instancesAndProps, {face, "Transparency"})
            end
        end
    end
    return instancesAndProps
end