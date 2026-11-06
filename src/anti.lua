-- src/anti.lua
-- light hygiene, namespace guard, full unload

local Modules = getgenv().GeoBModules or {}
local Services = Modules.services
local Config = Modules.config

local Anti = {}

local ENV = getgenv()
if ENV.GeoBV3 then
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
    local Aim = Modules.aim
    local Visuals = Modules.visuals
    local Target = Modules.target

    if Aim and Aim.Stop then Aim.Stop() end
    if Visuals and Visuals.Stop then Visuals.Stop() end
    if Target and Target.Reset then Target.Reset() end

    Anti.Cleanup()

    Config.Enabled = false
    ENV.GeoBV3 = nil

    if ENV.GeoBV3_Window and ENV.GeoBV3_Window.Unload then
        pcall(function()
            ENV.GeoBV3_Window:Unload()
        end)
        ENV.GeoBV3_Window = nil
    end
end

Services.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    local Target = Modules.target
    if Target and Target.Reset then
        Target.Reset()
    end
end)

return Anti
