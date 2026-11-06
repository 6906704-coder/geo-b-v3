-- main.lua
-- geo-b-v3 entry point

getgenv().RAYFIELD_SECURE = true

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

-- load modules from github
local BASE = "https://raw.githubusercontent.com/6906704-coder/geo-b-v3/main/src/"

local function load(name)
    local source = game:HttpGet(BASE .. name .. ".lua")
    return loadstring(source)()
end

local Services = load("services")
local Config   = load("config")
local Target   = load("target")
local Aim      = load("aim")
local Visuals  = load("visuals")
local Anti     = load("anti")

-- create window
local Window = Rayfield:CreateWindow({
    name = "geo-b-v3",
    subtitle = "universal aimbot",
    sidebarLayout = true,
    theme = "cobalt",
    configuration = {
        autoSave = true,
        autoLoad = true,
        fileName = "geo-b-v3",
    },
})

getgenv().GeoBV3_Window = Window

-- // Tabs
local AimTab     = Window:CreateTab({ name = "Aim",     icon = "crosshair" })
local VisualsTab = Window:CreateTab({ name = "Visuals", icon = "eye" })
local SettingsTab = Window:CreateTab({ name = "Settings", icon = "settings" })

-- // AIM TAB
AimTab:CreateSection({ name = "Core" })

AimTab:CreateToggle({
    name = "Enabled",
    value = Config.Enabled,
    flag = "Enabled",
    callback = function(v)
        Config.Enabled = v
        Aim.Toggle(v)
        Visuals.Toggle(v)
    end,
})

AimTab:CreateDropdown({
    name = "Aim Mode",
    options = { "Camera", "Mouse", "Silent" },
    value = Config.AimMode,
    flag = "AimMode",
    callback = function(v)
        Config.AimMode = v
    end,
})

AimTab:CreateSlider({
    name = "FOV",
    range = { 20, 400 },
    value = Config.FOV,
    flag = "FOV",
    callback = function(v)
        Config.FOV = v
    end,
})

AimTab:CreateSlider({
    name = "Smoothness",
    range = { 0.01, 1 },
    value = Config.Smoothness,
    flag = "Smoothness",
    callback = function(v)
        Config.Smoothness = v
        Config.SmoothnessX = v
        Config.SmoothnessY = v
    end,
})

AimTab:CreateSection({ name = "Prediction" })

AimTab:CreateToggle({
    name = "Prediction",
    value = Config.Prediction,
    flag = "Prediction",
    callback = function(v)
        Config.Prediction = v
    end,
})

AimTab:CreateSlider({
    name = "Prediction Strength",
    range = { 0, 2 },
    value = Config.PredictionStrength,
    flag = "PredictionStrength",
    callback = function(v)
        Config.PredictionStrength = v
    end,
})

AimTab:CreateSlider({
    name = "Projectile Speed",
    range = { 200, 4000 },
    value = Config.ProjectileSpeed,
    flag = "ProjectileSpeed",
    callback = function(v)
        Config.ProjectileSpeed = v
    end,
})

AimTab:CreateToggle({
    name = "Gravity Compensation",
    value = Config.UseGravity,
    flag = "UseGravity",
    callback = function(v)
        Config.UseGravity = v
    end,
})

AimTab:CreateSection({ name = "Filters" })

AimTab:CreateToggle({
    name = "Team Check",
    value = Config.TeamCheck,
    flag = "TeamCheck",
    callback = function(v) Config.TeamCheck = v end,
})

AimTab:CreateToggle({
    name = "Wall Check",
    value = Config.WallCheck,
    flag = "WallCheck",
    callback = function(v) Config.WallCheck = v end,
})

AimTab:CreateToggle({
    name = "Visible Check",
    value = Config.VisibleCheck,
    flag = "VisibleCheck",
    callback = function(v) Config.VisibleCheck = v end,
})

AimTab:CreateToggle({
    name = "Friend Check",
    value = Config.FriendCheck,
    flag = "FriendCheck",
    callback = function(v) Config.FriendCheck = v end,
})

AimTab:CreateToggle({
    name = "Ignore Knocked",
    value = Config.IgnoreKnocked,
    flag = "IgnoreKnocked",
    callback = function(v) Config.IgnoreKnocked = v end,
})

AimTab:CreateSlider({
    name = "Max Distance",
    range = { 50, 2500 },
    value = Config.MaxDistance,
    flag = "MaxDistance",
    callback = function(v) Config.MaxDistance = v end,
})

AimTab:CreateSection({ name = "Priority" })

AimTab:CreateDropdown({
    name = "Priority",
    options = { "Crosshair", "Distance", "Health" },
    value = Config.Priority,
    flag = "Priority",
    callback = function(v) Config.Priority = v end,
})

AimTab:CreateDropdown({
    name = "Bone",
    options = { "Head", "Torso", "Closest" },
    value = Config.Bone,
    flag = "Bone",
    callback = function(v) Config.Bone = v end,
})

-- // VISUALS TAB
VisualsTab:CreateSection({ name = "Drawing" })

VisualsTab:CreateToggle({
    name = "Show FOV",
    value = Config.ShowFOV,
    flag = "ShowFOV",
    callback = function(v) Config.ShowFOV = v end,
})

VisualsTab:CreateToggle({
    name = "Show Snaplines",
    value = Config.ShowSnaplines,
    flag = "ShowSnaplines",
    callback = function(v) Config.ShowSnaplines = v end,
})

VisualsTab:CreateToggle({
    name = "Show Highlight",
    value = Config.ShowHighlight,
    flag = "ShowHighlight",
    callback = function(v) Config.ShowHighlight = v end,
})

VisualsTab:CreateToggle({
    name = "Show Target Info",
    value = Config.ShowTargetInfo,
    flag = "ShowTargetInfo",
    callback = function(v) Config.ShowTargetInfo = v end,
})

VisualsTab:CreateColorPicker({
    name = "FOV Color",
    value = Config.FOVColor,
    flag = "FOVColor",
    callback = function(v) Config.FOVColor = v end,
})

VisualsTab:CreateColorPicker({
    name = "Highlight Color",
    value = Config.HighlightColor,
    flag = "HighlightColor",
    callback = function(v) Config.HighlightColor = v end,
})

-- // SETTINGS TAB
SettingsTab:CreateSection({ name = "Keybinds" })

SettingsTab:CreateKeybind({
    name = "Toggle Aim",
    key = Config.ToggleAimKey,
    flag = "ToggleAimKey",
    callback = function()
        Config.Enabled = not Config.Enabled
        Aim.Toggle(Config.Enabled)
        Visuals.Toggle(Config.Enabled)
    end,
})

SettingsTab:CreateSection({ name = "Danger Zone" })

SettingsTab:CreateButton({
    name = "Unload",
    callback = function()
        Anti.Unload()
        Window:Notify({ title = "geo-b-v3", content = "Unloaded cleanly." })
    end,
})

-- start systems
Aim.Start()
Visuals.Start()

Window:Notify({
    title = "geo-b-v3",
    content = "Loaded. Sidebar ready.",
    duration = 4,
})
