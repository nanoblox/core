-- LOCAL
local DEFAULT_RIG_TYPE = Enum.HumanoidRigType.R15
local main = require(game.Nanoblox)
local httpService = main.HttpService 
local Clone = {}
Clone.__index = Clone



-- CONSTRUCTOR
function Clone.new(characterOrUserId)
	local self = {}
	setmetatable(self, Clone)
	
    self.userId = nil
    self.character = nil
    self.clone = nil
    self.hidden = false
    self.tracks = {}
    self.originalParent = workspace
	
    self:become(characterOrUserId)

	return self
end



-- METHODS
function Clone:become(characterOrUserId)
	local isANumber = typeof(characterOrUserId) == "number"
	self.userId = isANumber and characterOrUserId
    self.character = not isANumber and characterOrUserId

    --[[
        if not clone present
            if character then copy character, make archivable, set parent
            elseif userid then copy rig template clone, apply appearance, set parent

        else
            if character then mimic clothes, pants, etc
            elseif userid apply appearance
    ]]
    
    if not self.clone then
        local clone
        if self.character then
            local hrp = self.character:FindFirstChild("HumanoidRootPart")
            clone = self.character:Clone()
            clone.Archivable = true
            clone.CFrame = (hrp and hrp.CFrame) or CFrame.new()
            clone.Parent = workspace

        elseif self.userId then


        end
        self.clone = clone






    local clone = self.clone
    if not isANumber then
        -- Copy a character present in the server
        local hrpCFrame
        if clone then
            local hrp = clone:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrpCFrame = hrp.CFrame
            end
            if clone.Parent then
                self.originalParent = clone.Parent
            end
            clone:Destroy()
        end
        if not hrpCFrame then
            local hrp = self.character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrpCFrame = hrp.CFrame
            else
                hrpCFrame = CFrame.new(0, 0, 0)
            end
        end

        clone = self.character:Clone()
        clone.Archivable = true
        clone.CFrame = hrpCFrame
        clone.Parent = workspace

    else
        -- Generate a clone based upon a character appearance of a userId
    end

    self:_updateVisiblity()
    for _, track in pairs(self.tracks) do
        
    end

    self.clone = clone
    
end

function Clone:_updateVisiblity()
    if self.clone then
        self.clone.Parent = (self.hidden and nil) or self.originalParent
    end
end

function Clone:show()
	self.hidden = false
    self:_updateVisiblity()
end

function Clone:hide()
	self.hidden = true
    self:_updateVisiblity()
end

function Clone:setCFrame(cframe)

end

function Clone:setCollision(bool)

end

function Clone:loadTrack(animationId, animationName)
	
end

function Clone:getTrack(animationName)
	
end

function Clone:getTracks()
	
end

function Clone:destroy()

end



return Clone