local BodyUtil = require(script.Parent.Parent.BodyUtil)

return function(player, value, additional)
    local instancesAndProps = {}
    local parts = BodyUtil:getPartsByBodyGroup(player, additional)
    for _, part in pairs(parts) do
        table.insert(instancesAndProps, {part, "Transparency"})
    end
    return instancesAndProps
end