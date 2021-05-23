return function(player, property)
    local instancesAndProps = {}
    if tostring(property) ~= "nil" then
        instancesAndProps = {{player, property}}
    end
    return instancesAndProps
end