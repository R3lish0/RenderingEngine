#ifndef TRIANGLE_H
#define TRIANGLE_H

#include "hittable.h"
#include "aabb.h"

class triangle : public hittable {
  public:
    triangle(const point3& v0, const point3& v1, const point3& v2, shared_ptr<material> mat)
      : v0(v0), v1(v1), v2(v2), mat(mat)
    {
        auto edge1 = v1 - v0;
        auto edge2 = v2 - v0;
        normal = unit_vector(cross(edge1, edge2));
        
        set_bounding_box();
    }

    virtual void set_bounding_box() {
        bbox = aabb(
            point3(
                fmin(fmin(v0.x(), v1.x()), v2.x()),
                fmin(fmin(v0.y(), v1.y()), v2.y()),
                fmin(fmin(v0.z(), v1.z()), v2.z())
            ),
            point3(
                fmax(fmax(v0.x(), v1.x()), v2.x()),
                fmax(fmax(v0.y(), v1.y()), v2.y()),
                fmax(fmax(v0.z(), v1.z()), v2.z())
            )
        );
    }

    aabb bounding_box() const override { return bbox; }

    bool hit(const ray& r, interval ray_t, hit_record& rec) const override {
        // Möller–Trumbore intersection algorithm
        auto edge1 = v1 - v0;
        auto edge2 = v2 - v0;
        auto h = cross(r.direction(), edge2);
        auto a = dot(edge1, h);

        if (a > -1e-8 && a < 1e-8)
            return false;

        auto f = 1.0/a;
        auto s = r.origin() - v0;
        auto u = f * dot(s, h);

        if (u < 0.0 || u > 1.0)
            return false;

        auto q = cross(s, edge1);
        auto v = f * dot(r.direction(), q);

        if (v < 0.0 || u + v > 1.0)
            return false;

        auto t = f * dot(edge2, q);

        if (!ray_t.contains(t))
            return false;

        rec.t = t;
        rec.p = r.at(t);
        rec.mat = mat;
        rec.set_face_normal(r, normal);
        rec.u = u;
        rec.v = v;

        return true;
    }

  private:
    point3 v0, v1, v2;  // Vertices
    vec3 normal;        // Triangle normal
    shared_ptr<material> mat;
    aabb bbox;
};

#endif 