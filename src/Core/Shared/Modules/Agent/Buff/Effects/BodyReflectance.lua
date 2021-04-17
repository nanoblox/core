local BodyUtil = require(script.Parent.Parent.BodyUtil)

return function(player, additional)
    local instancesAndProps = {}
    local parts = BodyUtil.getPartsByBodyGroup(player, additional)
    local fakeParts = BodyUtil.getOrSetupFakeBodyParts(player, parts, script.Name, additional)
    for _, fakePart  in pairs(fakeParts) do
        table.insert(instancesAndProps, {fakePart, "Reflectance"})
    end
    return instancesAndProps
end