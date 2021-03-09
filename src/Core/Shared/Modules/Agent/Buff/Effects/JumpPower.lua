local function getHumanoid(player)
    local char = player and player.Character
    local humanoid = char and char:FindFirstChild("Humanoid")
end

return function(player)
    local humanoid = getHumanoid(player)
    local props = {}
    if humanoid then
        props = {humanoid.JumpPower}
    end
    return props
end