#include "../include/rtweekend.h"

#include "../include/hittable_list.h"
#include "../include/quad.h"
#include "../include/sphere.h"
#include "../include/camera.h"
#include "../include/constant_medium.h"
#include "../include/material.h"
#include "../include/bvh.h"
#include "../include/texture.h"
#include "../include/mesh.h"
#include "../include/triangle.h"

#include <lua.hpp>
#include <string>
#include <stdexcept>
#include <map>
#include <chrono>
#include <iostream>
#include <thread>

// Helper functions for Lua table parsing
shared_ptr<material> create_material_from_lua(lua_State* L, int material_idx) {
    lua_rawgeti(L, -1, 2); // Get material type
    const char* type_str = lua_tostring(L, -1);
    if (!type_str) {
        throw std::runtime_error("Material type is null");
    }
    string mat_type(type_str);
    lua_pop(L, 1);

    if (mat_type == "dielectric") {
        lua_rawgeti(L, -1, 3); // Get refractive index
        double ref_idx = lua_tonumber(L, -1);
        lua_pop(L, 1);
        return make_shared<dielectric>(ref_idx);
    }
    else if (mat_type == "metal") {
        lua_rawgeti(L, -1, 3); // Get albedo table
        color albedo;
        for (int i = 1; i <= 3; i++) {
            lua_rawgeti(L, -1, i);
            albedo[i-1] = lua_tonumber(L, -1);
            lua_pop(L, 1);
        }
        lua_pop(L, 1);
        
        lua_rawgeti(L, -1, 4); // Get fuzz
        double fuzz = lua_tonumber(L, -1);
        lua_pop(L, 1);
        
        return make_shared<metal>(albedo, fuzz);
    }
    else if (mat_type == "diffuse_light") {
        lua_rawgeti(L, -1, 3); // Get color table
        color emit;
        for (int i = 1; i <= 3; i++) {
            lua_rawgeti(L, -1, i);
            emit[i-1] = lua_tonumber(L, -1);
            lua_pop(L, 1);
        }
        lua_pop(L, 1);
        return make_shared<diffuse_light>(emit);
    }
    else if (mat_type == "lambertian") {
        lua_rawgeti(L, -1, 3); // Get color table
        color albedo;
        for (int i = 1; i <= 3; i++) {
            lua_rawgeti(L, -1, i);
            albedo[i-1] = lua_tonumber(L, -1);
            lua_pop(L, 1);
        }
        lua_pop(L, 1);
        return make_shared<lambertian>(albedo);
    }
    
    // Default to grey lambertian if type not recognized
    return make_shared<lambertian>(color(0.5, 0.5, 0.5));
}

point3 get_point3_from_lua(lua_State* L, int table_idx) {
    point3 p;
    for (int i = 1; i <= 3; i++) {
        lua_rawgeti(L, table_idx, i);
        p[i-1] = lua_tonumber(L, -1);
        lua_pop(L, 1);
    }
    return p;
}

vec3 get_vec3_from_lua(lua_State* L, int table_idx) {
    return get_point3_from_lua(L, table_idx);
}

shared_ptr<hittable> create_object_from_lua(lua_State* L, int obj_idx, const std::map<string, shared_ptr<material>>& materials, bool is_light = false) {
    lua_rawgeti(L, -1, 1); // Get object type
    const char* type_str = lua_tostring(L, -1);
    if (!type_str) {
        std::cout << "Object type at index " << obj_idx << " is null" << std::endl;
        lua_pop(L, 1);
        return nullptr;
    }
    string obj_type(type_str);
    lua_pop(L, 1);

    if (obj_type == "sphere") {
        lua_rawgeti(L, -1, 2); // Get center
        point3 center = get_point3_from_lua(L, -1);
        lua_pop(L, 1);

        lua_rawgeti(L, -1, 3); // Get radius
        double radius = lua_tonumber(L, -1);
        lua_pop(L, 1);

        if (is_light) {
            // For lights, we don't need a material
            return make_shared<sphere>(center, radius, nullptr);
        } else {
            lua_rawgeti(L, -1, 4); // Get material id
            const char* id_str = lua_tostring(L, -1);
            if (!id_str) {
                std::cout << "Material ID for sphere at index " << obj_idx << " is null" << std::endl;
                lua_pop(L, 1);
                return nullptr;
            }
            string mat_id(id_str);
            lua_pop(L, 1);

            try {
                return make_shared<sphere>(center, radius, materials.at(mat_id));
            } catch (const std::out_of_range& e) {
                std::cout << "Material '" << mat_id << "' not found for sphere at index " << obj_idx << std::endl;
                return nullptr;
            }
        }
    }
    else if (obj_type == "box") {
        lua_rawgeti(L, -1, 2); // Get min point
        point3 min_point = get_point3_from_lua(L, -1);
        lua_pop(L, 1);

        lua_rawgeti(L, -1, 3); // Get max point
        point3 max_point = get_point3_from_lua(L, -1);
        lua_pop(L, 1);

        if (is_light) {
            return box(min_point, max_point, nullptr);
        } else {
            lua_rawgeti(L, -1, 4); // Get material id
            const char* id_str = lua_tostring(L, -1);
            if (!id_str) {
                std::cout << "Material ID for box at index " << obj_idx << " is null" << std::endl;
                lua_pop(L, 1);
                return nullptr;
            }
            string mat_id(id_str);
            lua_pop(L, 1);

            try {
                return box(min_point, max_point, materials.at(mat_id));
            } catch (const std::out_of_range& e) {
                std::cout << "Material '" << mat_id << "' not found for box at index " << obj_idx << std::endl;
                return nullptr;
            }
        }
    }
    else if (obj_type == "quad") {
        lua_rawgeti(L, -1, 2); // Get point
        point3 Q = get_point3_from_lua(L, -1);
        lua_pop(L, 1);

        lua_rawgeti(L, -1, 3); // Get u vector
        vec3 u = get_vec3_from_lua(L, -1);
        lua_pop(L, 1);

        lua_rawgeti(L, -1, 4); // Get v vector
        vec3 v = get_vec3_from_lua(L, -1);
        lua_pop(L, 1);

        if (is_light) {
            return make_shared<quad>(Q, u, v, nullptr);
        } else {
            lua_rawgeti(L, -1, 5); // Get material id
            const char* id_str = lua_tostring(L, -1);
            if (!id_str) {
                std::cout << "Material ID for quad at index " << obj_idx << " is null" << std::endl;
                lua_pop(L, 1);
                return nullptr;
            }
            string mat_id(id_str);
            lua_pop(L, 1);

            try {
                return make_shared<quad>(Q, u, v, materials.at(mat_id));
            } catch (const std::out_of_range& e) {
                std::cout << "Material '" << mat_id << "' not found for quad at index " << obj_idx << std::endl;
                return nullptr;
            }
        }
    }
    
    return nullptr;
}

void create_scene_from_lua(lua_State* L, hittable_list& world, hittable_list& lights, camera& cam) {
    // Parse SceneSettings
    lua_getglobal(L, "SceneSettings");
    if (!lua_istable(L, -1)) {
        throw std::runtime_error("SceneSettings is not a table");
    }
    std::cout << "Found SceneSettings table" << std::endl;

    lua_getfield(L, -1, "aspect_ratio");
    cam.aspect_ratio = lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_getfield(L, -1, "image_width");
    cam.image_width = lua_tointeger(L, -1);
    lua_pop(L, 1);

    lua_getfield(L, -1, "samples_per_pixel");
    cam.samples_per_pixel = lua_tointeger(L, -1);
    lua_pop(L, 1);

    lua_getfield(L, -1, "max_depth");
    cam.max_depth = lua_tointeger(L, -1);
    lua_pop(L, 1);

    lua_getfield(L, -1, "vfov");
    cam.vfov = lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_getfield(L, -1, "lookfrom");
    cam.lookfrom = get_point3_from_lua(L, -1);
    lua_pop(L, 1);

    lua_getfield(L, -1, "lookat");
    cam.lookat = get_point3_from_lua(L, -1);
    lua_pop(L, 1);

    lua_getfield(L, -1, "vup");
    cam.vup = get_vec3_from_lua(L, -1);
    lua_pop(L, 1);

    lua_getfield(L, -1, "defocus_angle");
    cam.defocus_angle = lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_getfield(L, -1, "focus_dist");
    cam.focus_dist = lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_getfield(L, -1, "background");
    cam.background = get_vec3_from_lua(L, -1);
    lua_pop(L, 1);

    // Create materials map
    lua_getglobal(L, "Materials");
    if (!lua_istable(L, -1)) {
        throw std::runtime_error("Materials is not a table");
    }
    int materials_len = lua_rawlen(L, -1);
    std::cout << "Found Materials table with " << materials_len << " materials" << std::endl;

    std::map<string, shared_ptr<material>> materials;
    for (int i = 1; i <= materials_len; i++) {
        lua_rawgeti(L, -1, i);
        
        lua_rawgeti(L, -1, 1); // Get material id
        const char* id_str = lua_tostring(L, -1);
        if (!id_str) {
            std::cout << "Material ID at index " << i << " is null" << std::endl;
            lua_pop(L, 2);
            continue;
        }
        string mat_id(id_str);
        lua_pop(L, 1);
        
        try {
            materials[mat_id] = create_material_from_lua(L, i);
        } catch (const std::exception& e) {
            std::cout << "Error creating material at index " << i << ": " << e.what() << std::endl;
        }
        lua_pop(L, 1);
    }
    lua_pop(L, 1);

    // Create objects
    lua_getglobal(L, "Objects");
    if (!lua_istable(L, -1)) {
        throw std::runtime_error("Objects is not a table");
    }
    int objects_len = lua_rawlen(L, -1);
    std::cout << "Found Objects table with " << objects_len << " objects" << std::endl;

    for (int i = 1; i <= objects_len; i++) {
        lua_rawgeti(L, -1, i);
        auto obj = create_object_from_lua(L, i, materials, false);
        if (obj) world.add(obj);
        lua_pop(L, 1);
    }
    lua_pop(L, 1);

    // Create lights
    lua_getglobal(L, "Lights");
    if (!lua_istable(L, -1)) {
        throw std::runtime_error("Lights is not a table");
    }
    int lights_len = lua_rawlen(L, -1);
    std::cout << "Found Lights table with " << lights_len << " lights" << std::endl;

    for (int i = 1; i <= lights_len; i++) {
        lua_rawgeti(L, -1, i);
        auto light = create_object_from_lua(L, i, materials, true);
        if (light) lights.add(light);
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
}

void initialize_lua(const char* scene_name) {
    // Get starting timepoint
    auto start = std::chrono::high_resolution_clock::now();
    
    lua_State* L = luaL_newstate();
    luaL_openlibs(L);
    
    // Create arg table and set scene name
    lua_createtable(L, 1, 0);  // Create arg table with 1 element
    lua_pushstring(L, scene_name);  // Push the scene name
    lua_rawseti(L, -2, 1);  // Set it as arg[1]
    lua_setglobal(L, "arg");  // Set the table as global 'arg'
    
    // Check if we can load and run a Lua file
    if (luaL_dofile(L, "src/scene.lua") != LUA_OK) {
        std::string error = lua_tostring(L, -1);
        lua_close(L);
        throw std::runtime_error("Failed to load Lua scene file: " + error);
    }

    // Create scene from Lua configuration
    hittable_list world;
    hittable_list lights;
    camera cam;

    create_scene_from_lua(L, world, lights, cam);
    
    // Render the scene
    cam.render(world, std::thread::hardware_concurrency(), lights);
    
    lua_close(L);

    // Get ending timepoint
    auto stop = std::chrono::high_resolution_clock::now();

    // Get duration
    auto duration = std::chrono::duration_cast<std::chrono::minutes>(stop - start);

    std::cout << "Time taken by function: "
         << duration.count() << " minutes" << std::endl;
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <scene_name>" << std::endl;
        return 1;
    }

    try {
        initialize_lua(argv[1]);
    } catch (const std::exception& e) {
        std::cerr << "Lua initialization error: " << e.what() << std::endl;
        return 1;
    }

    return 0;
}
