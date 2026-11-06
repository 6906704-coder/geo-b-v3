-- src/visuals.lua
-- FOV circle, snaplines, target highlight, info text

local Modules = getgenv().GeoBModules or {}
local Services = Modules.services
local Config = Modules.config
local Target = Modules.target

local Camera = Services.GetCamera()
local RunService = Services.RS
local Players = Services.Players
local LocalPlayer = Services.LocalPlayer

local Visuals = {}
Visuals.Connection = nil
Visuals.Drawings = {
    FOV = nil,
    Snapline = nil,
    Info = nil,
}
Visuals.Highlight = nil

local function createDrawing(class, props)
    local obj = Drawing.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    return obj
end

local function ensureDrawings()
    if not Visuals.Drawings.FOV then
        Visuals.Drawings.FOV = createDrawing("Circle", {
            Thickness = Config.FOVThickness or 1.5,
            NumSides = 64,
            Radius = Config.FOV or 120,
            Filled = false,
            Visible = false,
            Color = Config.FOVColor or Color3.fromRGB(140, 180, 255),
            Transparency = 1,
        })
    end

    if not Visuals.Drawings.Snapline then
        Visuals.Drawings.Snapline = createDrawing("Line", {
            Thickness = 1.2,
            Visible = false,
            Color = Config.SnaplineColor or Color3.fromRGB(255, 255, 255),
            Transparency = 1,
        })
    end

    if not Visuals.Drawings.Info then
        Visuals.Drawings.Info = createDrawing("Text", {
            Size = 16,
            Center = true,
            Outline = true,
            Visible = false,
            Color = Color3.fromRGB(255, 255, 255),
            Transparency = 1,
            Font = 2,
        })
    end
end

local function updateFOV()
    local fov = Visuals.Drawings.FOV
    if not fov then return end

    local viewport = Camera.ViewportSize
    fov.Position = Vector2.new(viewport.X / 2, viewport.Y / 2)
    fov.Radius = Config.FOV or 120
    fov.Color = Config.FOVColor or Color3.fromRGB(140, 180, 255)
    fov.Thickness = Config.FOVThickness or 1.5
    fov.Visible = Config.ShowFOV and Config.Enabled
end

local function updateSnapline(best)
    local line = Visuals.Drawings.Snapline
    if not line then return end

    if not (Config.ShowSnaplines and best and Config.Enabled) then
        line.Visible = false
        return
    end

    local viewport = Camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
    local screenPos = best.ScreenPos

    line.From = center
    line.To = screenPos
    line.Color = Config.SnaplineColor or Color3.fromRGB(255, 255, 255)
    line.Visible = true
end

local function updateHighlight(best)
    if Visuals.Highlight then
        Visuals.Highlight:Destroy()
        Visuals.Highlight = nil
    end

    if not (Config.ShowHighlight and best and Config.Enabled) then
        return
    end

    local char = best.Character
    if not char then return end

    local highlight = Instance.new("Highlight")
    highlight.Adornee = char
    highlight.FillColor = Config.HighlightColor or Color3.fromRGB(255, 80, 80)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.55
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char

    Visuals.Highlight = highlight
end

local function updateInfo(best)
    local text = Visuals.Drawings.Info
    if not text then return end

    if not (Config.ShowTargetInfo and best and Config.Enabled) then
        text.Visible = false
        return
    end

    local name = best.Player.DisplayName or best.Player.Name
    local dist = math.floor(best.WorldDist)
    local hp = math.floor(best.Humanoid.Health)

    text.Text = string.format("%s  |  %dm  |  %dhp", name, dist, hp)
    text.Position = best.ScreenPos + Vector2.new(0, -28)
    text.Visible = true
end

function Visuals.Step()
    ensureDrawings()
    updateFOV()

    local best = nil
    if Config.Enabled then
        if Target.Current then
            local char = Target.Current.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                local bone = char:FindFirstChild(Config.Bone or "Head")
                    or char:FindFirstChild("HumanoidRootPart")
                if humanoid and bone and humanoid.Health > 0 then
                    local screenPos = Camera:WorldToViewportPoint(bone.Position)
                    best = {
                        Player = Target.Current,
                        Character = char,
                        Humanoid = humanoid,
                        Bone = bone,
                        ScreenPos = Vector2.new(screenPos.X, screenPos.Y),
                        WorldDist = (bone.Position - Camera.CFrame.Position).Magnitude,
                    }
                end
            end
        end
    end

    updateSnapline(best)
    updateHighlight(best)
    updateInfo(best)
end

function Visuals.Start()
    if Visuals.Connection then return end
    ensureDrawings()
    Visuals.Connection = RunService.RenderStepped:Connect(Visuals.Step)
end

function Visuals.Stop()
    if Visuals.Connection then
        Visuals.Connection:Disconnect()
        Visuals.Connection = nil
    end

    for _, d in pairs(Visuals.Drawings) do
        if d then
            d.Visible = false
            d:Remove()
        end
    end
    table.clear(Visuals.Drawings)

    if Visuals.Highlight then
        Visuals.Highlight:Destroy()
        Visuals.Highlight = nil
    end
end

function Visuals.Toggle(state)
    if state then
        Visuals.Start()
    else
        Visuals.Stop()
    end
end

return Visuals
