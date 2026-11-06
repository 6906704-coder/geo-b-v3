-- src/anti.lua
-- light hygiene, namespace guard, full unload

local Services = require(script.Parent.services)
local Config = require(script.Parent.config)

local Anti = {}

-- prevent double-load
local ENV = getgenv()
if ENV.GeoBV3 then
    warn("[geo-b-v3] already loaded, unloading old instance")
    if ENV.GeoBV3.Unload then
        ENV.GeoBV3.Unload()
    end
end

ENV.GeoBV3 = Anti

local connections = {}
local drawings = {}
local highlights = {}

function Anti.TrackConnection(conn)
    table.insert(connections, conn)
    return conn
end

function Anti.TrackDrawing(obj)
    table.insert(drawings, obj)
    return obj
end

function Anti.TrackHighlight(obj)
    table.insert(highlights, obj)
    return obj
end

function Anti.Cleanup()
    for _, conn in ipairs(connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(connections)

    for _, d in ipairs(drawings) do
        if d then
            pcall(function()
                d.Visible = false
                d:Remove()
            end)
        end
    end
    table.clear(drawings)

    for _, h in ipairs(highlights) do
        if h then
            pcall(function()
                h:Destroy()
            end)
        end
    end
    table.clear(highlights)
end

function Anti.Unload()
    -- stop systems if they expose Stop
    local okAim, Aim = pcall(require, script.Parent.aim)
    if okAim and Aim.Stop then Aim.Stop() end

    local okVis, Visuals = pcall(require, script.Parent.visuals)
    if okVis and Visuals.Stop then Visuals.Stop() end

    local okTarget, Target = pcall(require, script.Parent.target)
    if okTarget and Target.Reset then Target.Reset() end

    Anti.Cleanup()

    Config.Enabled = false
    ENV.GeoBV3 = nil

    -- if Rayfield window exists, kill it
    if ENV.GeoBV3_Window and ENV.GeoBV3_Window.Unload then
        pcall(function()
            ENV.GeoBV3_Window:Unload()
        end)
        ENV.GeoBV3_Window = nil
    end
end

-- basic character cleanup on respawn
Services.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    local okTarget, Target = pcall(require, script.Parent.target)
    if okTarget and Target.Reset then
        Target.Reset()
    end
end)

return Anti
