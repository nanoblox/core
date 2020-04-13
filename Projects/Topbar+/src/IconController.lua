-- LOCAL
local IconController = {}
local Icon = require(script.Parent.Icon)
local topbarIcons = {}



-- FUNCTIONS
function IconController:createIcon(name, imageId, order)
	
	-- Verify data
	local iconDetails = topbarIcons[name]
	if iconDetails then
		warn(("Topbar+ | Failed to create Icon '%s': an icon already exists under the name '%s'."):format(name, name))
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
			warn(("Topbar+ | Failed to update Icon '%s': icon not found."):format(name))
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
		for i, details in pairs(orderedIconDetails) do
			local button = details.icon.objects.button
			local iconX = 104 + (i-1)*44
			button.Position = UDim2.new(0, iconX, 0, 4)
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

function IconController:getIcon(name)
	local iconDetails = topbarIcons[name]
	if not iconDetails then
		warn(("Topbar+ | Failed to get Icon '%s': icon not found."):format(name))
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
		warn(("Topbar+ | Failed to remove Icon '%s': icon not found."):format(name))
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