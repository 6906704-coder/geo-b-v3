-- src/aim.lua
-- aim application + prediction

local Modules = getgenv().GeoBModules or {}
local Services = Modules.services
local Config = Modules.config
local Target = Modules.target

local Camera = Services.GetCamera()
local UIS = Services.UIS
local RunService = Services.RS
local LocalPlayer = Services.LocalPlayer

local Aim = {}
Aim.Connection = nil
Aim.LastVelocity = {}
Aim.SmoothedVelocity = {}

local function getProjectileSpeed()
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            local speed = tool:GetAttribute("ProjectileSpeed")
                or tool:FindFirstChild("ProjectileSpeed")
                or tool:FindFirstChild("Speed")
            if speed then
                if typeof(speed) == "number" then return speed end
                if speed:IsA("NumberValue") or speed:IsA("IntValue") then
                    return speed.Value
                end
            end
        end
    end
    return Config.ProjectileSpeed or 1500
end

local function getSmoothedVelocity(player, bone)
    local raw = bone.AssemblyLinearVelocity
    local last = Aim.LastVelocity[player]
    local smooth = Aim.SmoothedVelocity[player] or raw

    if last then
        local alpha = Config.VelocitySmoothing or 0.35
        smooth = smooth:Lerp(raw, 1 - alpha)
    end

    Aim.LastVelocity[player] = raw
    Aim.SmoothedVelocity[player] = smooth
    return smooth
end

local function predictPosition(bone, player)
    if not Config.Prediction then
        return bone.Position
    end

    local speed = getProjectileSpeed()
    local camPos = Camera.CFrame.Position
    local pos = bone.Position
    local vel = getSmoothedVelocity(player, bone)

    local dist = (pos - camPos).Magnitude
    local t = dist / math.max(speed, 1)

    local predicted = pos + (vel * t * (Config.PredictionStrength or 1))

    if Config.UseGravity then
        local g = workspace.Gravity * (Config.GravityStrength or 1)
        predicted = predicted + Vector3.new(0, 0.5 * -g * t * t, 0)
    end

    return predicted
end

local function getAimCFrame(targetPos)
    local cam = Camera
    local origin = cam.CFrame.Position
    local direction = (targetPos - origin).Unit
    return CFrame.lookAt(origin, origin + direction)
end

local function applyCamera(targetPos, dt)
    local goal = getAimCFrame(targetPos)
    local smooth = math.clamp(Config.Smoothness or 0.18, 0.001, 1)

    local current = Camera.CFrame
    local look = current.LookVector
    local goalLook = goal.LookVector

    local alpha = 1 - math.exp(-dt / math.max(smooth, 0.001))
    local newLook = look:Lerp(goalLook, alpha)

    Camera.CFrame = CFrame.lookAt(current.Position, current.Position + newLook)
end

local function applyMouse(targetPos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
    if not onScreen then return end

    local viewport = Camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
    local targetScreen = Vector2.new(screenPos.X, screenPos.Y)

    local delta = targetScreen - center

    local smooth = math.clamp(Config.Smoothness or 0.18, 0.001, 1)
    local move = delta * (1 - smooth)

    if mousemoverel then
        mousemoverel(move.X, move.Y)
    elseif Input and Input.MouseMove then
        Input.MouseMove(move.X, move.Y)
    end
end

local function applySilent(targetPos)
    local goal = getAimCFrame(targetPos)
    Camera.CFrame = goal
end

function Aim.Step(dt)
    if not Config.Enabled then
        Target.Reset()
        return
    end

    local best = Target.GetBest()
    if not best then return end

    local predicted = predictPosition(best.Bone, best.Player)

    local mode = Config.AimMode or "Camera"

    if mode == "Camera" then
        applyCamera(predicted, dt)
    elseif mode == "Mouse" then
        applyMouse(predicted)
    elseif mode == "Silent" then
        applySilent(predicted)
    end
end

function Aim.Start()
    if Aim.Connection then return end
    Aim.Connection = RunService.RenderStepped:Connect(function(dt)
        Aim.Step(dt)
    end)
end

function Aim.Stop()
    if Aim.Connection then
        Aim.Connection:Disconnect()
        Aim.Connection = nil
    end
    Target.Reset()
    table.clear(Aim.LastVelocity)
    table.clear(Aim.SmoothedVelocity)
end

function Aim.Toggle(state)
    if state == nil then
        state = not Config.Enabled
    end
    Config.Enabled = state
    if state then
        Aim.Start()
    else
        Aim.Stop()
    end
end

return Aim
