local BodyUtil = require(script.Parent.Parent.BodyUtil)

return function(player, additional, bossBuffValue)
    local instancesAndProps = {}
    local parts = BodyUtil.getPartsByBodyGroup(player, additional)
    local fakeParts = BodyUtil.getOrSetupFakeBodyParts(player, parts, script.Name, additional)
    --if bossBuffValue == Enum.Material.ForceField then
        for _, part  in pairs(parts) do
            table.insert(instancesAndProps, {part, "Material"})
        end
    --else
        for _, fakePart  in pairs(fakeParts) do
            table.insert(instancesAndProps, {fakePart, "Material"})
        end
    --end
    return instancesAndProps
end