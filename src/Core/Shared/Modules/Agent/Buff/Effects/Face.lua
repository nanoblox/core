return function(player)
    local head = player.Character and player.Character:FindFirstChild("Head")
    local face = head and (head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal"))
    local instancesAndProps = {}
    if face then
        instancesAndProps = {{face, "Texture"}}
    end
    return instancesAndProps
end