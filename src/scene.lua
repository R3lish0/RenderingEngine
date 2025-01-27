-- Initialize global tables
SceneSettings = {}
Materials = {}
Objects = {}
Lights = {}


-- Check for scene name argument
if not arg[1] then
    error("\nPlease specify a scene name as an argument.\nUsage: ./make/output <scene_name>\n\n")
end

local scene_name = arg[1]


-- Load the selected scene module
package.path = package.path .. ";src/?.lua"
local success, scene = pcall(require, "scenes." .. scene_name)
if not success then
    error("Failed to load scene '" .. scene_name .. "': " .. scene)
end

-- Run the scene setup
scene.setup()