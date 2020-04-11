-- LOCAL
local TopbarController = {}
local Icon = require(script.Icon)
local topbarIcons = {}



-- FUNCTIONS
function TopbarController:createIcon(name, imageId, order)
	
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
			local iconButton = details.icon.iconButton
			local iconX = 104 + (i-1)*44
			iconButton.Position = UDim2.new(0, iconX, 0, 4)
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
			if otherIcon ~= icon and otherIcon.deselectWhenOtherIconSelected and otherIcon.isSelected then
				otherIcon:deselect()
			end
		end
	end)
	
	
	return icon
end

function TopbarController:getIcon(name)
	local iconDetails = topbarIcons[name]
	if not iconDetails then
		warn(("Topbar+ | Failed to get Icon '%s': icon not found."):format(name))
		return false
	end
	return iconDetails.icon
end

function TopbarController:getAllIcons()
	local allIcons = {}
	for name, details in pairs(topbarIcons) do
		table.insert(allIcons, details.icon)
	end
	return allIcons
end

function TopbarController:removeIcon(name)
	local iconDetails = topbarIcons[name]
	if not iconDetails then
		warn(("Topbar+ | Failed to remove Icon '%s': icon not found."):format(name))
		return false
	end
	--
	local function destroyObject(object)
		local validTypes = {["table"]=true, ["Instance"]=true}
		local objectType = typeof(object)
		local isTable = objectType == "table"
		if not validTypes[objectType] then
			return
		end
		local isDestroyPresent = (isTable and rawget(object, "Destroy")) or object.Destroy
		local className = object.ClassName
		if isDestroyPresent and (className == nil or className ~= "Player") then
			pcall(function() object:Destroy() end)
		end
		local invalidNames = {["__index"]=true}
		if isTable then
			for a,b in pairs(object) do
				if not invalidNames[a] then
					destroyObject(a)
					destroyObject(b)
				end
			end
		end
	end
	local icon = iconDetails.icon
	icon:setEnabled(false)
	icon.updated:Fire()
	destroyObject(icon)
	--
	topbarIcons[name] = nil
	return true
end


-- hello ben i like pie (2) but pineapple is cool (4)
return TopbarController