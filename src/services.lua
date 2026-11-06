-- src/services.lua
-- cached services + tiny utilities used by every other module

local Services = {}

Services.Players = game:GetService("Players")
Services.RunService = game:GetService("RunService")
Services.UserInputService = game:GetService("UserInputService")
Services.TweenService = game:GetService("TweenService")
Services.HttpService = game:GetService("HttpService")
Services.ReplicatedStorage = game:GetService("ReplicatedStorage")
Services.Workspace = game:GetService("Workspace")
Services.Lighting = game:GetService("Lighting")
Services.CoreGui = game:GetService("CoreGui")
Services.GuiService = game:GetService("GuiService")

Services.LocalPlayer = Services.Players.LocalPlayer
Services.Camera = Services.Workspace.CurrentCamera

-- safe wait for camera (some games re-parent it)
function Services.GetCamera()
    local cam = Services.Workspace.CurrentCamera
    if cam then
        Services.Camera = cam
        return cam
    end
    return Services.Camera
end

-- short aliases that never change
Services.LP = Services.LocalPlayer
Services.RS = Services.RunService
Services.UIS = Services.UserInputService

return Services