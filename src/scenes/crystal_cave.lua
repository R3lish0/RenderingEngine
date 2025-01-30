local M = {}

-- Cave parameters
local wall_height = 12
local sphere_spacing = 1.5

function M.setup()
    -- Scene Settings
    SceneSettings = {
        aspect_ratio = 3456/2234,
        image_width = 600,
        samples_per_pixel = 10,
        max_depth = 25,
        vfov = 80,
        lookfrom = {0, 3, 25},    -- Moved back and up more
        lookat = {0, 0, 0},       -- Looking at center of cave
        vup = {0, 1, 0},
        defocus_angle = 0.0,
        focus_dist = 25.0,
        background = {0.0, 0.0, 0.0}
    }

    -- Materials
    -- Cave wall and ground materials
    local cave_wall = {"lambertian", {0.15, 0.15, 0.17}}
    local wet_stone = {"metal", {0.2, 0.2, 0.22}, 0.9}
    local cave_floor = {"lambertian", {0.1, 0.1, 0.12}}

    -- Much brighter crystal materials
    local blue_crystal = {"dielectric", 1.5}
    local blue_glow = {"diffuse_light", {10.0, 50.0, 100.0}, 1.0}  -- Doubled blue brightness
    
    local purple_crystal = {"dielectric", 1.5}
    local purple_glow = {"diffuse_light", {40.0, 0.0, 80.0}, 1.0}  -- Doubled purple brightness
    
    local cyan_crystal = {"dielectric", 1.52}
    local cyan_glow = {"diffuse_light", {0.0, 60.0, 80.0}, 1.0}  -- Doubled cyan brightness
    
    local amber_crystal = {"dielectric", 1.48}
    local amber_glow = {"diffuse_light", {80.0, 40.0, 0.0}, 1.0}  -- Doubled amber brightness
    
    -- Water material
    local water = {"metal", {0.2, 0.2, 0.25}, 0.05}  -- Very smooth water surface

    -- Add materials to global table
    table.insert(Materials, {"cave_wall", table.unpack(cave_wall)})
    table.insert(Materials, {"wet_stone", table.unpack(wet_stone)})
    table.insert(Materials, {"cave_floor", table.unpack(cave_floor)})
    table.insert(Materials, {"blue_crystal", table.unpack(blue_crystal)})
    table.insert(Materials, {"blue_glow", table.unpack(blue_glow)})
    table.insert(Materials, {"purple_crystal", table.unpack(purple_crystal)})
    table.insert(Materials, {"purple_glow", table.unpack(purple_glow)})
    table.insert(Materials, {"cyan_crystal", table.unpack(cyan_crystal)})
    table.insert(Materials, {"cyan_glow", table.unpack(cyan_glow)})
    table.insert(Materials, {"amber_crystal", table.unpack(amber_crystal)})
    table.insert(Materials, {"amber_glow", table.unpack(amber_glow)})
    table.insert(Materials, {"water", table.unpack(water)})

    -- Function to create crystal cluster
    local function create_crystal_cluster(x, y, z, size, material_base, material_glow)
        -- Central crystal
        table.insert(Objects, {"box",
            {x - size * 0.15, y, z - size * 0.15},
            {x + size * 0.15, y + size, z + size * 0.15},
            material_base
        })
        
        -- Glowing core
        table.insert(Objects, {"box",
            {x - size * 0.05, y + size * 0.2, z - size * 0.05},
            {x + size * 0.05, y + size * 0.8, z + size * 0.05},
            material_glow
        })
        table.insert(Lights, {"box",
            {x - size * 0.05, y + size * 0.2, z - size * 0.05},
            {x + size * 0.05, y + size * 0.8, z + size * 0.05}
        })
        
        -- Surrounding smaller crystals
        local num_small = 5
        for i = 1, num_small do
            local angle = i * (2 * math.pi / num_small)
            local offset_x = math.cos(angle) * (size * 0.3)
            local offset_z = math.sin(angle) * (size * 0.3)
            local small_size = size * 0.4
            
            table.insert(Objects, {"box",
                {x + offset_x - small_size * 0.1, y, z + offset_z - small_size * 0.1},
                {x + offset_x + small_size * 0.1, y + small_size, z + offset_z + small_size * 0.1},
                material_base
            })
        end
    end

    -- Create main chamber and branching paths
    local function create_chamber(center_x, center_z, radius, angle_offset)
        local chamber_segments = 40
        for i = 1, chamber_segments do
            local angle = (i - 1) * (2 * math.pi / chamber_segments) + angle_offset
            local radius_variation = math.sin(i * 0.7) * 1.0
            local chamber_radius = radius + radius_variation
            
            local z = center_z + math.sin(angle) * chamber_radius
            local x = center_x + math.cos(angle) * chamber_radius
            
            if z < 20 then  -- Only create visible parts
                for y = -2, wall_height, sphere_spacing do
                    for layer = 0, 2 do
                        local layer_radius = chamber_radius - layer * 0.5
                        local wall_x = center_x + math.cos(angle) * layer_radius
                        local wall_z = center_z + math.sin(angle) * layer_radius
                        
                        table.insert(Objects, {"sphere",
                            {wall_x, y, wall_z},
                            2.2,
                            "cave_wall"
                        })
                    end
                end
            end
        end
    end

    -- Create connecting tunnel
    local function create_tunnel(start_x, start_z, end_x, end_z, radius)
        local tunnel_segments = 10
        for i = 1, tunnel_segments do
            local t = (i - 1) / (tunnel_segments - 1)
            local x = start_x + (end_x - start_x) * t
            local z = start_z + (end_z - start_z) * t
            
            if z < 20 then  -- Only create visible parts
                for angle = 0, math.pi, math.pi / 8 do
                    local wall_x = x + math.cos(angle) * radius
                    local wall_y = math.sin(angle) * radius
                    
                    for y = -2, wall_height, sphere_spacing do
                        table.insert(Objects, {"sphere",
                            {wall_x, y + wall_y, z},
                            2.2,
                            "cave_wall"
                        })
                    end
                end
            end
        end
    end

    -- Create main chamber
    create_chamber(0, 10, 10, 0)  -- Main chamber where we are

    -- Create left branch
    create_chamber(-8, 0, 7, math.pi/4)  -- Smaller chamber to the left
    create_tunnel(0, 5, -8, 0, 4)  -- Connecting tunnel

    -- Create right branch
    create_chamber(8, -2, 7, -math.pi/4)  -- Smaller chamber to the right
    create_tunnel(0, 5, 8, -2, 4)  -- Connecting tunnel

    -- Add crystals to light the paths
    local path_crystals = {
        -- Main chamber crystals (existing)
        {x = 0, y = 4, z = 15, size = 3.0, base = "blue_crystal", glow = "blue_glow"},
        {x = -4, y = 5, z = 12, size = 2.5, base = "purple_crystal", glow = "purple_glow"},
        {x = 4, y = 3, z = 12, size = 2.5, base = "cyan_crystal", glow = "cyan_glow"},
        
        -- Left path crystals
        {x = -6, y = 4, z = 4, size = 2.5, base = "amber_crystal", glow = "amber_glow"},
        {x = -8, y = 5, z = 0, size = 2.5, base = "blue_crystal", glow = "blue_glow"},
        
        -- Right path crystals
        {x = 6, y = 3, z = 2, size = 2.5, base = "purple_crystal", glow = "purple_glow"},
        {x = 8, y = 4, z = -2, size = 2.5, base = "cyan_crystal", glow = "cyan_glow"}
    }

    -- Create the floating crystals
    for _, crystal in ipairs(path_crystals) do
        create_crystal_cluster(crystal.x, crystal.y, crystal.z, 
            crystal.size, crystal.base, crystal.glow)
    end

    -- Function to create embedded wall crystal
    local function create_embedded_crystal(x, y, z, normal_x, normal_z, size, material_base, material_glow)
        -- Calculate the embedded position (moved into wall)
        local embed_depth = size * 0.7  -- 70% embedded
        local embed_x = x - normal_x * embed_depth
        local embed_z = z - normal_z * embed_depth
        
        
        -- Main crystal (embedded part)
        table.insert(Objects, {"box",
            {embed_x - size * 0.3, y - size * 0.2, embed_z - size * 0.3},
            {x + normal_x * size * 0.3, y + size * 0.8, z + normal_z * size * 0.3},
            material_base
        })
        
        -- Glowing tip (peeking out)
        local glow_size = size * 0.4
        table.insert(Objects, {"box",
            {x - normal_x * glow_size * 0.5, y + size * 0.3, z - normal_z * glow_size * 0.5},
            {x + normal_x * glow_size, y + size * 0.6, z + normal_z * glow_size},
            material_glow
        })
        table.insert(Lights, {"box",
            {x - normal_x * glow_size * 0.5, y + size * 0.3, z - normal_z * glow_size * 0.5},
            {x + normal_x * glow_size, y + size * 0.6, z + normal_z * glow_size}
        })
    end

    -- Add many embedded crystals in the walls
    -- Main chamber embedded crystals
    for i = 1, 60 do  -- More crystals
        local angle = math.random() * 2 * math.pi
        local height = math.random() * wall_height
        local chamber_choice = math.random()
        
        if chamber_choice < 0.4 then
            -- Main chamber
            local radius = 10 + math.random() * 0.5
            local x = math.cos(angle) * radius
            local z = 10 + math.sin(angle) * radius
            if z < 20 then
                local crystal_types = {
                    {size = 1.0 + math.random() * 0.5, base = "blue_crystal", glow = "blue_glow"},
                    {size = 1.0 + math.random() * 0.5, base = "purple_crystal", glow = "purple_glow"},
                    {size = 1.0 + math.random() * 0.5, base = "cyan_crystal", glow = "cyan_glow"},
                    {size = 1.0 + math.random() * 0.5, base = "amber_crystal", glow = "amber_glow"}
                }
                local crystal = crystal_types[math.floor(math.random() * 4) + 1]
                create_embedded_crystal(x, height, z, math.cos(angle), math.sin(angle),
                    crystal.size, crystal.base, crystal.glow)
            end
        elseif chamber_choice < 0.7 then
            -- Left branch
            local radius = 7 + math.random() * 0.5
            local base_x = -8
            local base_z = 0
            local x = base_x + math.cos(angle) * radius
            local z = base_z + math.sin(angle) * radius
            if z < 20 then
                local crystal = {size = 1.0 + math.random() * 0.5, base = "amber_crystal", glow = "amber_glow"}
                create_embedded_crystal(x, height, z, math.cos(angle), math.sin(angle),
                    crystal.size, crystal.base, crystal.glow)
            end
        else
            -- Right branch
            local radius = 7 + math.random() * 0.5
            local base_x = 8
            local base_z = -2
            local x = base_x + math.cos(angle) * radius
            local z = base_z + math.sin(angle) * radius
            if z < 20 then
                local crystal = {size = 1.0 + math.random() * 0.5, base = "cyan_crystal", glow = "cyan_glow"}
                create_embedded_crystal(x, height, z, math.cos(angle), math.sin(angle),
                    crystal.size, crystal.base, crystal.glow)
            end
        end
    end

    -- Add crystals in the connecting tunnels
    for i = 1, 20 do  -- Crystals per tunnel
        -- Left tunnel
        local t = math.random()
        local x = t * -8  -- Interpolate from 0 to -8
        local z = 5 + t * -5  -- Interpolate from 5 to 0
        local angle = math.random() * math.pi
        local offset = math.cos(angle) * 4  -- Tunnel radius is 4
        local height = math.random() * wall_height
        if z < 20 then
            create_embedded_crystal(x + math.cos(angle + math.pi/2) * offset, height, 
                z + math.sin(angle + math.pi/2) * offset,
                math.cos(angle), math.sin(angle),
                1.0 + math.random() * 0.5, "blue_crystal", "blue_glow")
        end
        
        -- Right tunnel
        x = t * 8  -- Interpolate from 0 to 8
        z = 5 + t * -7  -- Interpolate from 5 to -2
        if z < 20 then
            create_embedded_crystal(x + math.cos(angle + math.pi/2) * offset, height, 
                z + math.sin(angle + math.pi/2) * offset,
                math.cos(angle), math.sin(angle),
                1.0 + math.random() * 0.5, "purple_crystal", "purple_glow")
        end
    end
end

return M 