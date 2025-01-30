local M = {}

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

    -- Add fewer, but brighter floating crystals in visible area
    local floating_crystals = {
        -- Crystals in direct view
        {x = 0, y = 4, z = 15, size = 3.0, base = "blue_crystal", glow = "blue_glow"},      -- Center
        {x = -4, y = 5, z = 12, size = 2.5, base = "purple_crystal", glow = "purple_glow"},  -- Left
        {x = 4, y = 3, z = 12, size = 2.5, base = "cyan_crystal", glow = "cyan_glow"},       -- Right
        -- Crystals lighting the cave
        {x = -2, y = 6, z = 8, size = 2.5, base = "amber_crystal", glow = "amber_glow"},
        {x = 2, y = 2, z = 8, size = 2.5, base = "blue_crystal", glow = "blue_glow"}
    }

    -- Create main cave chamber with denser, overlapping spheres
    local chamber_segments = 40
    local base_radius = 10       -- Slightly wider cave
    local wall_height = 12
    local sphere_spacing = 1.5
    
    -- Create complete cave structure with overlapping spheres
    for i = 1, chamber_segments do
        local angle = (i - 1) * (2 * math.pi / chamber_segments)
        local radius_variation = math.sin(i * 0.7) * 1.0
        local chamber_radius = base_radius + radius_variation
        
        -- Only create walls that are potentially visible (in front of camera)
        local z = math.sin(angle) * chamber_radius
        if z < 20 then  -- Extended visible range
            local x = math.cos(angle) * chamber_radius
            
            for y = -2, wall_height, sphere_spacing do
                -- Create 3 layers for walls
                for layer = 0, 2 do
                    local layer_radius = chamber_radius - layer * 0.5
                    local wall_x = math.cos(angle) * layer_radius
                    local wall_z = math.sin(angle) * layer_radius
                    
                    table.insert(Objects, {"sphere",
                        {wall_x, y, wall_z},
                        2.2,
                        "cave_wall"
                    })
                end
            end
        end
    end

    -- Create ceiling only for visible area
    for r = 0, base_radius + 2, 2.0 do  -- Increased spacing
        for angle = 0, 2 * math.pi, math.pi / 8 do  -- Reduced angle divisions
            local x = math.cos(angle) * r
            local z = math.sin(angle) * r
            if z < 15 then  -- Only create ceiling in front of camera
                local height_var = math.sin(x * 0.8) * 2.0 + math.cos(z * 0.8) * 2.0
                local y = wall_height - 2 + height_var
                
                table.insert(Objects, {"sphere",
                    {x, y, z},
                    2.2,
                    "cave_wall"
                })
            end
        end
    end

    -- Create shorter entrance tunnel
    local entrance_length = 10  -- Shortened tunnel
    local entrance_segments = 8  -- Reduced segments
    
    for i = 1, entrance_segments do
        local t = i / entrance_segments
        local z = 10 + t * entrance_length
        if z < 15 then  -- Only create tunnel parts in front of camera
            local radius = base_radius * (1 + t * 0.2)
            
            for j = 0, 10 do  -- Reduced number of segments
                local angle = j * math.pi / 5
                if angle <= math.pi then
                    local x = math.cos(angle) * radius
                    local y = math.sin(angle) * radius
                    
                    table.insert(Objects, {"sphere",
                        {x, y, z},
                        2.2,
                        "cave_wall"
                    })
                end
            end
        end
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

    -- Create the floating crystals (without companions to reduce complexity)
    for _, crystal in ipairs(floating_crystals) do
        create_crystal_cluster(crystal.x, crystal.y, crystal.z, 
            crystal.size, crystal.base, crystal.glow)
    end

    -- Add fewer embedded crystals, only in visible areas
    for i = 1, chamber_segments do
        local angle = (i - 1) * (2 * math.pi / chamber_segments)
        local z = math.sin(angle) * base_radius
        
        if z < 15 then  -- Only add crystals to visible walls
            local x = math.cos(angle) * base_radius
            local normal_x = math.cos(angle)
            local normal_z = math.sin(angle)
            
            -- Add just 3 crystals per wall segment
            for j = 1, 3 do
                local height = 2 + j * 3  -- Evenly spaced heights
                local crystal_types = {
                    {size = 2.0, base = "blue_crystal", glow = "blue_glow"},
                    {size = 2.0, base = "purple_crystal", glow = "purple_glow"},
                    {size = 2.0, base = "cyan_crystal", glow = "cyan_glow"}
                }
                local crystal = crystal_types[j]
                
                create_embedded_crystal(x, height, z, normal_x, normal_z, 
                    crystal.size, crystal.base, crystal.glow)
            end
        end
    end

    -- Single water pool in view
    table.insert(Objects, {"quad",
        {-2, 0.1, 2},
        {4, 0, 0},
        {0, 0, 4},
        "water"
    })
end

return M 