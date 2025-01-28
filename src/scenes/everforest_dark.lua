local M = {}

function M.setup()
    -- Scene Settings
    SceneSettings = {
        aspect_ratio = 21/9, -- Ultrawide 21:9
        image_width = 500,
        samples_per_pixel = 1000,
        max_depth = 25,
        vfov = 40,
        lookfrom = {-4, 2, 25},  -- Moved closer, 2 steps left
        lookat = {2, 2, 0},      -- Looking ~20 degrees right
        vup = {0, 1, 0},
        defocus_angle = 0.3,
        focus_dist = 25.0,       -- Adjusted focus for closer camera
        background = {0.005, 0.01, 0.02} -- Darker blue background
    }
    
    -- Everforest Materials (using darker, earthier tones)
    local forest_ground = {"lambertian", {0.15, 0.2, 0.1}} -- Dark mossy green
    local bark = {"lambertian", {0.25, 0.15, 0.1}}  -- Deep brown bark
    local leaves = {"lambertian", {0.12, 0.22, 0.08}}  -- Dark forest green
    local water = {"metal", {0.2, 0.3, 0.35}, 0.1} -- Slightly blue, very smooth metal for water
    local river_bottom = {"lambertian", {0.08, 0.12, 0.18}} -- Very dark blue bottom
    local glass = {"dielectric", 1.5}
    local glow = {"diffuse_light", {8.0, 6.0, 2.0}, 0.4} -- Warmer, slightly brighter fireflies
    local sunset = {"diffuse_light", {2.0, 1.0, 0.4}, 0.6}  -- Dimmer, more distant sun

    -- Add materials to global table
    table.insert(Materials, {"forest_ground", table.unpack(forest_ground)})
    table.insert(Materials, {"bark", table.unpack(bark)})
    table.insert(Materials, {"leaves", table.unpack(leaves)})
    table.insert(Materials, {"water", table.unpack(water)})
    table.insert(Materials, {"river_bottom", table.unpack(river_bottom)})
    table.insert(Materials, {"glass", table.unpack(glass)})
    table.insert(Materials, {"glow", table.unpack(glow)})
    table.insert(Materials, {"sunset", table.unpack(sunset)})

    -- Ground plane
    table.insert(Objects, {"quad", {-50, 0, -50}, {100, 0, 0}, {0, 0, 100}, "forest_ground"})

    -- Function to create a tree
    local function create_tree(x, z, height, trunk_radius, variation)
        -- Trunk
        table.insert(Objects, {"box", 
            {x - trunk_radius, 0, z - trunk_radius},
            {x + trunk_radius, height, z + trunk_radius},
            "bark"})
        
        -- Foliage (multiple layers of lenaves)
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

    -- Add fireflies (more numerous with front bias and guaranteed close ones)
    local num_fireflies = 120  -- Increased total fireflies
    
    -- First add some guaranteed close to camera
    local num_close_fireflies = 20
    for i = 1, num_close_fireflies do
        -- Position close to camera but in view
        local angle = math.random() * math.pi * 0.8 - math.pi * 0.4  -- -40 to +40 degrees from camera
        local radius = 15.0 + math.random() * 5.0  -- Relatively close to camera
        local x = -4 + math.cos(angle) * radius  -- Offset by camera x position
        local z = 25 + math.sin(angle) * radius  -- Offset by camera z position
        local y = 1.0 + math.random() * 2.0  -- Slightly lower height range for close ones
        
        local size = 0.15 + math.random() * 0.1  -- Slightly smaller since they're closer
        table.insert(Objects, {"sphere", {x, y, z}, size, "glass"})
        table.insert(Objects, {"sphere", {x, y, z}, size * 0.4, "glow"})
        table.insert(Lights, {"sphere", {x, y, z}, size * 0.4})
    end
    
    -- Then add the rest with front bias
    for i = 1, num_fireflies - num_close_fireflies do
        -- Random position with front bias
        local angle = math.random() * math.pi * 1.3  -- Only spawn in 3/4 of the circle, avoiding sun
        -- Add bias towards front view by adjusting the radius
        local radius = math.random() * 20.0
        if math.random() < 0.6 then  -- 60% chance to be in the front half
            radius = radius * 0.7  -- Closer to center if in front
        end
        
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        local y = 0.5 + math.random() * 3.0
        
        -- Add some clustering effect
        x = x + math.sin(i * 0.7) * 2.0
        z = z + math.cos(i * 0.7) * 2.0
        
        local size = 0.18 + math.random() * 0.12
        table.insert(Objects, {"sphere", {x, y, z}, size, "glass"})
        table.insert(Objects, {"sphere", {x, y, z}, size * 0.4, "glow"})
        table.insert(Lights, {"sphere", {x, y, z}, size * 0.4})
    end

    -- Add warm sunset light far in front of camera
    local sun_distance = -45  -- Further away
    local sun_height = 6     -- Slightly higher
    table.insert(Objects, {"sphere",
        {2, sun_height, sun_distance},
        15.0,  -- Even larger size for softer light
        "sunset"
    })
    table.insert(Lights, {"sphere",
        {2, sun_height, sun_distance},
        15.0
    })
end

return M
