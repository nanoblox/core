local function getHumanoid(player)
    local char = player and player.Character
    local humanoid = char and char:FindFirstChild("Humanoid")
    return humanoid
end

return function(player)

end