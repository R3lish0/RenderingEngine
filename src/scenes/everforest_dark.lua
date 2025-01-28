local M = {}

function M.setup()
    -- Scene Settings
    SceneSettings = {
        aspect_ratio = 21/9, -- Ultrawide 21:9
        image_width = 300,
        samples_per_pixel = 1000,
        max_depth = 25,
        vfov = 40,
        lookfrom = {-4, 2, 25},  -- Moved closer, 2 steps left
        lookat = {2, 2, 0},      -- Looking ~20 degrees right
        vup = {0, 1, 0},
        defocus_angle = 0.3,
        focus_dist = 25.0,       -- Adjusted focus for closer camera
        background = {0.01, 0.02, 0.04} -- Very dark blue instead of pure black
    }
    
    -- Everforest Materials
    local forest_ground = {"lambertian", {0.3, 0.6, 0.2}} -- Natural green
    local bark = {"lambertian", {0.6, 0.3, 0.2}}  -- Reddish-brown bark
    local leaves = {"lambertian", {0.2, 0.5, 0.1}}  -- Forest green
    local water = {"dielectric", 1.33} -- Keep water same
    local river_bottom = {"metal", {0.2, 0.3, 0.7}, 0.6} -- Smoother metallic blue
    local glass = {"dielectric", 1.5}
    local glow = {"diffuse_light", {20.0, 16.0, 10.0}, 0.8} -- Keep firefly brightness
    local sunset = {"diffuse_light", {15.0, 7.5, 4.0}, 2.0}  -- Reduced sunset intensity significantly

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
    end

    -- Add fireflies (increased number for more illumination)
    local num_fireflies = 150  -- Increased from 80 for more light coverage
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
        
        -- Made fireflies slightly larger for more illumination
        local size = 0.25 + math.random() * 0.15
        table.insert(Objects, {"sphere", {x, y, z}, size, "glass"})
        table.insert(Objects, {"sphere", {x, y, z}, size * 0.6, "glow"})
        table.insert(Lights, {"sphere", {x, y, z}, size * 0.6})
    end

    -- Add warm sunset light far in front of camera
    local sun_distance = -30
    local sun_height = 4
    table.insert(Objects, {"sphere",
        {2, sun_height, sun_distance},
        8.0,
        "sunset"
    })
    table.insert(Lights, {"sphere",
        {2, sun_height, sun_distance},
        8.0
    })
end

return M
