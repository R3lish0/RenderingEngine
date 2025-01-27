local M = {}

function M.setup()
    -- Scene Settings
    SceneSettings = {
        aspect_ratio = 3440/1440, -- Ultrawide 21:9
        image_width = 3440,
        samples_per_pixel = 200,
        max_depth = 50,
        vfov = 40,
        lookfrom = {0, 8, 35},
        lookat = {0, 3, 0},
        vup = {0, 1, 0},
        defocus_angle = 0.4,
        focus_dist = 35.0,
        background = {0.157, 0.176, 0.204} -- Everforest dark background
    }

    -- Everforest Materials
    local dark_ground = {"metal", {0.157, 0.176, 0.204}, 0.1} -- Dark ground
    local bark = {"metal", {0.435, 0.365, 0.325}, 0.8} -- Tree bark
    local leaves = {"metal", {0.475, 0.518, 0.357}, 0.3} -- Dark forest green
    local water = {"metal", {0.357, 0.431, 0.431}, 0.0} -- River surface
    local glass = {"dielectric", 1.5}
    local glow = {"diffuse_light", {0.878, 0.749, 0.427}, 0.4} -- Warm firefly glow
    local mist_light = {"diffuse_light", {0.557, 0.631, 0.631}, 0.1} -- Soft blue mist glow

    -- Add materials to global table
    table.insert(Materials, {"dark_ground", table.unpack(dark_ground)})
    table.insert(Materials, {"bark", table.unpack(bark)})
    table.insert(Materials, {"leaves", table.unpack(leaves)})
    table.insert(Materials, {"water", table.unpack(water)})
    table.insert(Materials, {"glass", table.unpack(glass)})
    table.insert(Materials, {"glow", table.unpack(glow)})
    table.insert(Materials, {"mist_light", table.unpack(mist_light)})

    -- Ground plane
    table.insert(Objects, {"quad", {-50, 0, -50}, {100, 0, 0}, {0, 0, 100}, "dark_ground"})

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

    -- Create river
    local river_segments = 20
    local river_width = 6.0
    for i = 1, river_segments do
        local z = -50 + (i-1) * (100/river_segments)
        local x_offset = math.sin(z * 0.1) * 8.0
        
        table.insert(Objects, {"quad",
            {x_offset - river_width, 0.1, z},
            {river_width * 2, 0, 0},
            {0, 0, 100/river_segments + 1},
            "water"})
    end

    -- Add floating glass orbs with firefly glow
    local num_orbs = 30
    for i = 1, num_orbs do
        local angle = i * (2 * math.pi / num_orbs) * 2.7
        local radius = 10.0 + math.sin(i * 3.14) * 5.0
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        local y = 3.0 + math.sin(i * 0.5) * 2.0
        
        -- Glass orb
        table.insert(Objects, {"sphere", {x, y, z}, 0.8, "glass"})
        -- Glowing core
        table.insert(Objects, {"sphere", {x, y, z}, 0.4, "glow"})
        table.insert(Lights, {"sphere", {x, y, z}, 0.4})
    end

    -- Add mist near the ground
    local mist_particles = 100
    for i = 1, mist_particles do
        local angle = i * (2 * math.pi / mist_particles) * 3.14
        local radius = math.random() * 25.0
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        local y = 0.2 + math.random() * 0.8
        
        table.insert(Objects, {"sphere", {x, y, z}, 0.3, "mist_light"})
        table.insert(Lights, {"sphere", {x, y, z}, 0.3})
    end
end

return M
