-- src/config.lua
-- single source of truth for every tunable
-- Rayfield reads/writes these values directly

local Config = {
    -- Aim
    Enabled = false,
    AimMode = "Camera",          -- Camera | Mouse | Silent
    FOV = 120,
    Smoothness = 0.18,           -- 0 = instant, 1 = very slow
    SmoothnessX = 0.18,
    SmoothnessY = 0.18,
    Prediction = true,
    PredictionStrength = 1.0,
    ProjectileSpeed = 1500,      -- studs/sec, used when auto-detect fails
    UseGravity = false,
    GravityStrength = 1.0,
    VelocitySmoothing = 0.35,

    -- Target filters
    TeamCheck = true,
    FriendCheck = false,
    WallCheck = true,
    VisibleCheck = true,
    MinHealth = 1,
    MaxDistance = 1200,
    MinDistance = 0,
    IgnoreKnocked = true,

    -- Priority
    Priority = "Crosshair",      -- Crosshair | Distance | Health
    Bone = "Head",               -- Head | Torso | Closest

    -- Lock behaviour
    SoftLock = true,
    SwitchDelay = 0.12,
    StickyFOV = 1.15,            -- multiplier once locked

    -- Triggerbot
    Triggerbot = false,
    TriggerDelay = 0.05,
    TriggerFOV = 35,

    -- Visuals
    ShowFOV = true,
    ShowSnaplines = false,
    ShowHighlight = true,
    ShowTargetInfo = true,
    FOVColor = Color3.fromRGB(140, 180, 255),
    SnaplineColor = Color3.fromRGB(255, 255, 255),
    HighlightColor = Color3.fromRGB(255, 80, 80),
    FOVThickness = 1.5,

    -- Keybinds (string form for Rayfield)
    ToggleAimKey = "E",
    ToggleUIKey = "RightShift",
    ForceTargetKey = "MouseButton3",

    -- Profiles
    ActiveProfile = "Legit",

    -- Internal (do not show in UI)
    _Target = nil,
    _Locked = false,
    _LastSwitch = 0,
}

return Config