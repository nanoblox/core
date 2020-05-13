-- LOCAL
local starterGui = game:GetService("StarterGui")
local players = game:GetService("Players")
local IconController = {}
local Icon = require(script.Parent.Icon)
local topbarIcons = {}
local errorStart = "Topbar+ | "
local function deepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            v = deepCopy(v)
        end
        copy[k] = v
    end
    return copy
end



-- METHODS
function IconController:createIcon(name, imageId, order)
	
	-- Verify data
	local iconDetails = topbarIcons[name]
	if iconDetails then
		warn(("%sFailed to create Icon '%s': an icon already exists under that name."):format(errorStart, name))
		return false
	end
	
	-- Create and record icon
	local icon = Icon.new(name, imageId, order)
	iconDetails = {name = name, icon = icon, order = icon.order}
	topbarIcons[name] = iconDetails
	icon:setOrder(icon.order)
	
	-- Events
	local function updateIcon()
		local iconDetails = topbarIcons[name]
		if not iconDetails then
			warn(("%sFailed to update Icon '%s': icon not found."):format(errorStart, name))
			return false
		end
		iconDetails.order = icon.order or 1
		local orderedIconDetails = {}
		for name, details in pairs(topbarIcons) do
			if details.icon.enabled == true then
				table.insert(orderedIconDetails, details)
			end
		end
		if #orderedIconDetails > 1 then
			table.sort(orderedIconDetails, function(a,b) return a.order < b.order end)
		end
		local startPosition = 104
		local positionIncrement = 44
		if not starterGui:GetCoreGuiEnabled("Chat") then
			startPosition = startPosition - positionIncrement
		end
		for i, details in pairs(orderedIconDetails) do
			local container = details.icon.objects.container
			local iconX = startPosition + (i-1)*positionIncrement
			container.Position = UDim2.new(0, iconX, 0, 4)
		end
		return true
	end
	updateIcon()
	icon.updated:Connect(function()
		updateIcon()
	end)
	icon.selected:Connect(function()
		local allIcons = self:getAllIcons()
		for _, otherIcon in pairs(allIcons) do
			if otherIcon ~= icon and otherIcon.deselectWhenOtherIconSelected and otherIcon.toggleStatus == "selected" then
				otherIcon:deselect()
			end
		end
	end)
	
	
	return icon
end

function IconController:createFakeChat(theme)
	local chatMain = require(players.LocalPlayer.PlayerScripts:WaitForChild("ChatScript").ChatMain)
	local iconName = "_FakeChat"
	local icon = self:getIcon(iconName)
	if not icon then
		icon = self:createIcon(iconName, "rbxasset://textures/ui/TopBar/chatOff.png", -1)
	end
	theme = (theme and deepCopy(theme)) or {}
	theme.image = theme.image or {}
	theme.image.selected = theme.image.selected or {}
	theme.image.selected.Image = "rbxasset://textures/ui/TopBar/chatOn.png"
	icon:setTheme(theme)
	icon:setImageSize(20)
	icon:setToggleFunction(function()
		local isSelected = icon.toggleStatus == "selected"
		chatMain.CoreGuiEnabled:fire(isSelected)
		chatMain:SetVisible(isSelected)
	end)
	starterGui:SetCoreGuiEnabled("Chat", false)
	return icon
end

function IconController:getIcon(name)
	local iconDetails = topbarIcons[name]
	if not iconDetails then
		--warn(("%sFailed to get Icon '%s': icon not found."):format(errorStart, name))
		return false
	end
	return iconDetails.icon
end

function IconController:getAllIcons()
	local allIcons = {}
	for name, details in pairs(topbarIcons) do
		table.insert(allIcons, details.icon)
	end
	return allIcons
end

function IconController:removeIcon(name)
	local iconDetails = topbarIcons[name]
	if not iconDetails then
		warn(("%sFailed to remove Icon '%s': icon not found."):format(errorStart, name))
		return false
	end
	local icon = iconDetails.icon
	icon:setEnabled(false)
	icon:deselect()
	icon.updated:Fire()
	icon:destroy()
	topbarIcons[name] = nil
	return true
end



return IconController