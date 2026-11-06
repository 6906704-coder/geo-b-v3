-- src/target.lua
-- universal target acquisition + weighted scoring

local Services = require(script.Parent.services)
local Config = require(script.Parent.config)

local Players = Services.Players
local LocalPlayer = Services.LocalPlayer
local Camera = Services.GetCamera()
local Workspace = Services.Workspace

local Target = {}
Target.Current = nil
Target.LastSwitch = 0

local BONE_PRIORITY = {
    Head = 1,
    UpperTorso = 2,
    HumanoidRootPart = 3,
    Torso = 3,          -- R6
    LowerTorso = 4,
}

local function isAlive(humanoid)
    return humanoid and humanoid.Health > (Config.MinHealth or 0) and humanoid.Health > 0
end

local function isKnocked(character)
    if not Config.IgnoreKnocked then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return true end
    -- common knockdown patterns
    if humanoid:GetState() == Enum.HumanoidStateType.Physics then return true end
    if character:FindFirstChild("Knocked") or character:GetAttribute("Knocked") then return true end
    return false
end

local function getCharacter(player)
    local char = player.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    if not humanoid or not root then return nil end
    return char, humanoid, root
end

local function teamCheck(player)
    if not Config.TeamCheck then return true end
    if not LocalPlayer.Team then return true end          -- FFA / no teams
    if player.Team == nil then return true end
    return player.Team ~= LocalPlayer.Team
end

local function friendCheck(player)
    if not Config.FriendCheck then return true end
    return not LocalPlayer:IsFriendsWith(player.UserId)
end

local function wallCheck(fromPos, toPos, character)
    if not Config.WallCheck then return true end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        LocalPlayer.Character,
        character,
        Camera,
    }
    params.IgnoreWater = true

    local direction = (toPos - fromPos)
    local result = Workspace:Raycast(fromPos, direction, params)

    if not result then return true end
    -- if we hit something that belongs to the target character, still count as visible
    return result.Instance:IsDescendantOf(character)
end

local function getBone(character)
    local preferred = Config.Bone or "Head"

    if preferred == "Closest" then
        local closest, closestDist = nil, math.huge
        local camPos = Camera.CFrame.Position
        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("BasePart") and BONE_PRIORITY[part.Name] then
                local dist = (part.Position - camPos).Magnitude
                if dist < closestDist then
                    closest = part
                    closestDist = dist
                end
            end
        end
        return closest or character:FindFirstChild("HumanoidRootPart")
    end

    local bone = character:FindFirstChild(preferred)
    if bone and bone:IsA("BasePart") then return bone end

    -- fallback chain
    return character:FindFirstChild("Head")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("HumanoidRootPart")
        or character.PrimaryPart
end

local function worldToScreen(worldPos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function getCrosshairDistance(screenPos)
    local viewport = Camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
    return (screenPos - center).Magnitude
end

local function scoreTarget(player, character, humanoid, bone)
    local camPos = Camera.CFrame.Position
    local bonePos = bone.Position
    local screenPos, onScreen, depth = worldToScreen(bonePos)

    if not onScreen or depth < 0 then
        return nil
    end

    local crosshairDist = getCrosshairDistance(screenPos)
    local worldDist = (bonePos - camPos).Magnitude

    if worldDist > (Config.MaxDistance or 1200) or worldDist < (Config.MinDistance or 0) then
        return nil
    end

    if Config.VisibleCheck and not wallCheck(camPos, bonePos, character) then
        return nil
    end

    -- FOV gate (soft)
    local fov = Config.FOV or 120
    if Target.Current == player then
        fov = fov * (Config.StickyFOV or 1.15)
    end
    if crosshairDist > fov then
        return nil
    end

    -- scoring
    local score = 0
    local priority = Config.Priority or "Crosshair"

    if priority == "Crosshair" then
        score = 10000 - crosshairDist
        score = score - (worldDist * 0.15)
        score = score + (humanoid.Health * 0.05)
    elseif priority == "Distance" then
        score = 10000 - worldDist
        score = score - (crosshairDist * 0.4)
    elseif priority == "Health" then
        score = 10000 - humanoid.Health
        score = score - (crosshairDist * 0.6)
        score = score - (worldDist * 0.1)
    end

    return {
        Player = player,
        Character = character,
        Humanoid = humanoid,
        Bone = bone,
        Score = score,
        ScreenPos = screenPos,
        WorldDist = worldDist,
        CrosshairDist = crosshairDist,
    }
end

function Target.GetCandidates()
    local list = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not teamCheck(player) then continue end
        if not friendCheck(player) then continue end

        local char, humanoid, root = getCharacter(player)
        if not char or not isAlive(humanoid) then continue end
        if isKnocked(char) then continue end

        local bone = getBone(char)
        if not bone then continue end

        local data = scoreTarget(player, char, humanoid, bone)
        if data then
            table.insert(list, data)
        end
    end

    table.sort(list, function(a, b)
        return a.Score > b.Score
    end)

    return list
end

function Target.GetBest()
    local candidates = Target.GetCandidates()
    if #candidates == 0 then
        Target.Current = nil
        return nil
    end

    local best = candidates[1]

    -- soft lock / switch delay
    if Config.SoftLock and Target.Current then
        local stillValid = false
        for _, c in ipairs(candidates) do
            if c.Player == Target.Current then
                stillValid = true
                -- if the old target is still decent, keep it
                if c.Score > best.Score * 0.82 then
                    best = c
                end
                break
            end
        end

        if stillValid and (os.clock() - Target.LastSwitch) < (Config.SwitchDelay or 0.12) then
            -- force keep during switch delay
            for _, c in ipairs(candidates) do
                if c.Player == Target.Current then
                    best = c
                    break
                end
            end
        end
    end

    if best.Player ~= Target.Current then
        Target.LastSwitch = os.clock()
    end

    Target.Current = best.Player
    return best
end

function Target.Reset()
    Target.Current = nil
    Target.LastSwitch = 0
end

return Target