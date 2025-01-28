local M = {}

function M.setup()
    -- Scene Settings
    SceneSettings = {
        aspect_ratio = 3440/1440, -- Ultrawide 21:9
        image_width = 360,
        samples_per_pixel = 500,
        max_depth = 25,
        vfov = 40,
        lookfrom = {-4, 2, 25},  -- Moved closer, 2 steps left
        lookat = {2, 2, 0},      -- Looking ~20 degrees right
        vup = {0, 1, 0},
        defocus_angle = 0.3,
        focus_dist = 25.0,       -- Adjusted focus for closer camera
        background = {0.235, 0.175, 0.131} -- Darker sunset color
    }
    
    -- Everforest Materials
    local forest_ground = {"lambertian", {0.475, 0.518, 0.357}} -- Much more vibrant grass
    local bark = {"lambertian", {0.435, 0.365, 0.325}}  -- Slightly warmer bark
    local leaves = {"lambertian", {0.557, 0.631, 0.431}}  -- Even more vibrant green
    local water = {"dielectric", 1.33} -- Pure water
    local river_bottom = {"lambertian", {0.357, 0.631, 0.702}} -- Blue river bottom
    local glass = {"dielectric", 1.5}
    local glow = {"diffuse_light", {0.918, 0.682, 0.341}, 0.4} -- Brighter fireflies
    local ambient_light = {"diffuse_light", {0.557, 0.631, 0.631}, 0.1}
    local sunlight = {"diffuse_light", {1.0, 0.95, 0.9}, 3.0}  -- Much brighter sun
    local backlight = {"diffuse_light", {15, 15, 15}, 150}  -- Much brighter backlight

    -- Add materials to global table
    table.insert(Materials, {"forest_ground", table.unpack(forest_ground)})
    table.insert(Materials, {"bark", table.unpack(bark)})
    table.insert(Materials, {"leaves", table.unpack(leaves)})
    table.insert(Materials, {"water", table.unpack(water)})
    table.insert(Materials, {"river_bottom", table.unpack(river_bottom)})
    table.insert(Materials, {"glass", table.unpack(glass)})
    table.insert(Materials, {"glow", table.unpack(glow)})
    table.insert(Materials, {"ambient_light", table.unpack(ambient_light)})
    table.insert(Materials, {"sunlight", table.unpack(sunlight)})
    table.insert(Materials, {"backlight", table.unpack(backlight)})

    -- Ground plane
    table.insert(Objects, {"quad", {-50, 0, -50}, {100, 0, 0}, {0, 0, 100}, "forest_ground"})

    -- Function to create a tree
    local function create_tree(x, z, height, trunk_radius, variation)
        -- Trunk
        table.insert(Objects, {"box", 
            {x - trunk_radius, 0, z - trunk_radius},
            {x + trunk_radius, height, z + trunk_radius},
            "bark"})
        
        -- Foliage (multiple layers of leaves)
        local leaf_layers = 3
        for i = 1, leaf_layers do
            local y = height - (i * 0.5)
            local radius = 2.0 + (leaf_layers - i) * 1.2 + math.sin(variation) * 0.5
            
            -- Create leaf clusters
            local clusters = 6
            for j = 1, clusters do
                local angle = j * (2 * math.pi / clusters) + variation
                local offset_x = math.cos(angle) * radius
                local offset_z = math.sin(angle) * radius
                
                table.insert(Objects, {"sphere",
                    {x + offset_x, y + math.sin(j + variation) * 0.5, z + offset_z},
                    1.2 + math.sin(j * 1.5) * 0.3,
                    "leaves"})
            end
        end
    end

    -- Create a forest of trees
    local num_trees = 25
    for i = 1, num_trees do
        local angle = i * (2 * math.pi / num_trees) * 1.5
        local radius = 15.0 + math.sin(i * 2.7) * 8.0
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        local height = 6.0 + math.sin(i * 1.5) * 2.0
        
        create_tree(x, z, height, 0.4, i * 0.5)
    end

    -- Create river (as a box with depth)
    local river_segments = 40
    local river_width = 6.0
    local river_depth = 0.5  -- Depth of the river

    -- Create a hole in the ground for the river
    for i = 1, river_segments do
        local z = -50 + (i-1) * (100/river_segments)
        local x_offset = math.sin(z * 0.1) * 8.0
        
        -- Create blue river bottom
        table.insert(Objects, {"quad",
            {x_offset - river_width, -river_depth, z},
            {river_width * 2, 0, 0},
            {0, 0, 100/river_segments + 0.1},
            "river_bottom"})
        
        -- Create box for water
        table.insert(Objects, {"box",
            {x_offset - river_width, -river_depth, z},  -- Bottom corner
            {x_offset + river_width, 0.1, z + 100/river_segments + 0.1},  -- Top corner, slightly above ground
            "water"})
    end

    -- Split ground into two parts to make space for river
    table.insert(Objects, {"quad", 
        {-50, 0, -50}, 
        {100, 0, 0}, 
        {0, 0, 100}, 
        "forest_ground"})

    -- Add fireflies (more numerous, random distribution)
    local num_fireflies = 80  -- Reduced from 200
    for i = 1, num_fireflies do
        -- Random position within the forest area
        local angle = math.random() * math.pi * 2
        local radius = math.random() * 20.0  -- Random distance from center
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        local y = 0.5 + math.random() * 3.0  -- Random height between 0.5 and 3.5
        
        -- Add some clustering effect
        x = x + math.sin(i * 0.7) * 2.0
        z = z + math.cos(i * 0.7) * 2.0
        
        -- Smaller fireflies with subtle glow
        local size = 0.15 + math.random() * 0.1  -- Random size variation
        table.insert(Objects, {"sphere", {x, y, z}, size, "glass"})
        table.insert(Objects, {"sphere", {x, y, z}, size * 0.5, "glow"})
        table.insert(Lights, {"sphere", {x, y, z}, size * 0.5})
    end

    -- Add main sun light
    table.insert(Objects, {"quad",
        {-15, 15, -15},  -- Position for sunset-like angle
        {30, 0, 0},      -- Width
        {0, 0, 30},      -- Depth
        "sunlight"
    })
    table.insert(Lights, {"quad",
        {-15, 15, -15},
        {30, 0, 0},
        {0, 0, 30}
    })

    -- Add subtle ambient lights at corners of scene
    local corners = {
        {-20, 1, -20},
        {-20, 1, 20},
        {20, 1, -20},
        {20, 1, 20}
    }
    
    for _, pos in ipairs(corners) do
        table.insert(Objects, {"sphere", pos, 0.5, "ambient_light"})
        table.insert(Lights, {"sphere", pos, 0.5})
    end

    -- Add bright backlight directly behind camera
    local camera_pos = {-4, 2, 25}  -- Match camera position
    table.insert(Objects, {"sphere",
        {camera_pos[1], camera_pos[2], camera_pos[3] + 8},  -- Moved further behind camera
        2.0,  -- Smaller radius
        "backlight"
    })
    table.insert(Lights, {"sphere",
        {camera_pos[1], camera_pos[2], camera_pos[3] + 8},
        2.0
    })
end

return M
