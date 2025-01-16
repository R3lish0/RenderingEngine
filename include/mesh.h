#ifndef MESH_H
#define MESH_H

#include "hittable.h"
#include "triangle.h"
#include <fstream>
#include <sstream>
#include <vector>

class mesh : public hittable {
public:
    mesh(const std::string& filename, shared_ptr<material> mat) {
        std::vector<point3> vertices;
        std::ifstream file(filename);
        
        if (!file.is_open()) {
            std::cerr << "ERROR: Could not open file: " << filename << std::endl;
            return;
        }

        std::string line;
        while (std::getline(file, line)) {
            std::istringstream iss(line);
            std::string type;
            iss >> type;

            if (type == "v") {  // Vertex
                double x, y, z;
                iss >> x >> y >> z;
                vertices.push_back(point3(x, y, z));
            }
            else if (type == "f") {  // Face
                std::string v1, v2, v3;
                iss >> v1 >> v2 >> v3;
                
                // Extract vertex indices (handling both 'v' and 'v/vt/vn' formats)
                int idx1 = std::stoi(v1.substr(0, v1.find("/"))) - 1;
                int idx2 = std::stoi(v2.substr(0, v2.find("/"))) - 1;
                int idx3 = std::stoi(v3.substr(0, v3.find("/"))) - 1;

                if (idx1 >= 0 && idx2 >= 0 && idx3 >= 0 &&
                    idx1 < vertices.size() && idx2 < vertices.size() && idx3 < vertices.size()) {
                    triangles.push_back(make_shared<triangle>(
                        vertices[idx1],
                        vertices[idx2],
                        vertices[idx3],
                        mat
                    ));
                }
            }
        }

        set_bounding_box();
    }

    bool hit(const ray& r, interval ray_t, hit_record& rec) const override {
        hit_record temp_rec;
        bool hit_anything = false;
        auto closest_so_far = ray_t.max;

        for (const auto& tri : triangles) {
            if (tri->hit(r, interval(ray_t.min, closest_so_far), temp_rec)) {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec = temp_rec;
            }
        }

        return hit_anything;
    }

    aabb bounding_box() const override { return bbox; }

private:
    std::vector<shared_ptr<triangle>> triangles;
    aabb bbox;

    void set_bounding_box() {
        if (triangles.empty()) return;

        bbox = triangles[0]->bounding_box();
        for (const auto& tri : triangles) {
            bbox = aabb(bbox, tri->bounding_box());
        }
    }
};

#endif