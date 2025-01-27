local M = {}

function M.setup()
    -- Scene Settings
    SceneSettings = {
        aspect_ratio = 2,
        image_width = 600,
        samples_per_pixel = 1000,
        max_depth = 40,
        vfov = 45,
        lookfrom = {25, 20, 25},
        lookat = {0, 10, 0},
        vup = {0 , 1, 0},
        defocus_angle = 0.4,
        focus_dist = 30.0,
        background = { 0.02, 0.02, 0.04 }
    }

    -- Materials
    local glass = {"dielectric", 1.5}
    local tinted_glass = {"dielectric", 1.7}
    local chrome = {"metal", {0.9, 0.9, 1.0}, 0.1}
    local glow_blue = {"diffuse_light", {0.2, 0.4, 15.0}}
    local floor_metal = {"metal", {0.7, 0.7, 0.8}, 0.1}
    local glow_white = {"diffuse_light", {10, 10, 10}}

    -- Add materials to global table
    table.insert(Materials, {"glass", table.unpack(glass)})
    table.insert(Materials, {"tinted_glass", table.unpack(tinted_glass)})
    table.insert(Materials, {"chrome", table.unpack(chrome)})
    table.insert(Materials, {"glow_blue", table.unpack(glow_blue)})
    table.insert(Materials, {"floor_metal", table.unpack(floor_metal)})
    table.insert(Materials, {"glow_white", table.unpack(glow_white)})

    -- Glass enclosure
    local enclosure_size = 7.0
    local glass_thickness = 0.2

    -- Add glass panels
    -- Top glass panel
    table.insert(Objects, {"box", {-enclosure_size, enclosure_size + 5, -enclosure_size},
                            {enclosure_size, enclosure_size + 5 + glass_thickness, enclosure_size}, "glass"})
    
    -- Bottom glass panel
    table.insert(Objects, {"box", {-enclosure_size, 5 - enclosure_size, -enclosure_size},
                            {enclosure_size, 5 - enclosure_size + glass_thickness, enclosure_size}, "glass"})
    
    -- Front glass panel
    table.insert(Objects, {"box", {-enclosure_size, 5 - enclosure_size, enclosure_size},
                            {enclosure_size, 5 + enclosure_size, enclosure_size + glass_thickness}, "glass"})
    
    -- Back glass panel
    table.insert(Objects, {"box", {-enclosure_size, 5 - enclosure_size, -enclosure_size - glass_thickness},
                            {enclosure_size, 5 + enclosure_size, -enclosure_size}, "glass"})
    
    -- Left glass panel
    table.insert(Objects, {"box", {-enclosure_size - glass_thickness, 5 - enclosure_size, -enclosure_size},
                            {-enclosure_size, 5 + enclosure_size, enclosure_size}, "glass"})
    
    -- Right glass panel
    table.insert(Objects, {"box", {enclosure_size, 5 - enclosure_size, -enclosure_size},
                            {enclosure_size + glass_thickness, 5 + enclosure_size, enclosure_size}, "glass"})

    -- Central quantum containment
    table.insert(Objects, {"sphere", {0, 5, 0}, 5.0, "glass"})
    table.insert(Objects, {"sphere", {0, 5, 0}, 4.5, "tinted_glass"})
    table.insert(Objects, {"sphere", {0, 5, 0}, 3.5, "glass"})
    table.insert(Objects, {"sphere", {0, 5, 0}, 2.0, "glow_blue"})
    table.insert(Lights, {"sphere", {0, 5, 0}, 2.0})

    -- Orbiting metal spheres with glowing rings
    for i = 1, 8 do
        local radius, height, angle
        if i == 1 then radius, height, angle = 15.0, 8.0, math.pi/6      -- Front right
        elseif i == 2 then radius, height, angle = 18.0, 12.0, 4*math.pi/3  -- Back left
        elseif i == 3 then radius, height, angle = 12.0, 15.0, 3*math.pi/4  -- Mid left
        elseif i == 4 then radius, height, angle = 20.0, 6.0, 7*math.pi/4   -- Back right
        elseif i == 5 then radius, height, angle = 16.0, 10.0, 3*math.pi/2  -- Back center
        elseif i == 6 then radius, height, angle = 14.0, 5.0, math.pi/2     -- Front center
        elseif i == 7 then radius, height, angle = 17.0, 7.0, math.pi       -- Left side
        else radius, height, angle = 19.0, 9.0, 5*math.pi/4                 -- Back left corner
        end

        local center_x = radius * math.cos(angle)
        local center_z = radius * math.sin(angle)
        
        -- Add chrome sphere
        table.insert(Objects, {"sphere", {center_x, height, center_z}, 1.5, "chrome"})

        -- Add glowing ring segments
        local ring_radius = 2.4
        local ring_segments = 20
        
        for j = 1, ring_segments do
            local ring_angle = j * (2 * math.pi / ring_segments)
            local ring_x = center_x + math.cos(ring_angle) * ring_radius
            local ring_z = center_z + math.sin(ring_angle) * ring_radius
            
            table.insert(Objects, {"sphere", {ring_x, height, ring_z}, 0.2, "glow_white"})
            table.insert(Lights, {"sphere", {ring_x, height, ring_z}, 0.2})
        end
    end

    -- Add metal pylons with glowing bases at corners
    for i = 1, 4 do
        local angle = (i - 1) * (2 * math.pi / 4)
        local radius = 10.0
        local base_x = radius * math.cos(angle)
        local base_z = radius * math.sin(angle)
        
        -- Main pylon (as a box)
        local pylon = {"box", {base_x - 0.5, 0, base_z - 0.5}, 
                                {base_x + 0.5, 8, base_z + 0.5}, "chrome"}
        table.insert(Objects, pylon)

        -- Glowing base
        local base_light = {"box", {base_x - 1, 0, base_z - 1},
                                    {base_x + 1, 0.1, base_z + 1}, "glow_white"}
        table.insert(Objects, base_light)
        table.insert(Lights, {"quad", {base_x - 1, 0, base_z - 1}, {2, 0, 0}, {0, 0, 2}})
    end

    -- Add reflective platform
    table.insert(Objects, {"quad", {-15, -0.1, -15}, {30, 0, 0}, {0, 0, 30}, "floor_metal"})

    -- Add concentric rings in the floor
    for ring = 1, 3 do
        local ring_radius = ring * 4.0
        local segments = 16 * ring
        
        for i = 1, segments do
            local angle1 = (i - 1) * (2 * math.pi / segments)
            local angle2 = i * (2 * math.pi / segments)
            
            local x1 = ring_radius * math.cos(angle1)
            local z1 = ring_radius * math.sin(angle1)
            local x2 = ring_radius * math.cos(angle2)
            local z2 = ring_radius * math.sin(angle2)
            
            table.insert(Objects, {"quad", {x1, 0.01, z1}, 
                                    {x2 - x1, 0, z2 - z1}, 
                                    {0, 0, 0.2}, "chrome"})
        end
    end

    -- Add radial lines
    for i = 1, 8 do
        local angle = (i - 1) * (math.pi / 4)
        local end_x = 12 * math.cos(angle)
        local end_z = 12 * math.sin(angle)
        
        table.insert(Objects, {"quad", {0, 0.02, 0}, 
                                {end_x, 0, end_z}, 
                                {0, 0, 0.1}, "chrome"})
    end
end

return M 