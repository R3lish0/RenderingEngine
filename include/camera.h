#ifndef CAMERA_H
#define CAMERA_H


#include "hittable.h"
#include "material.h"
#include "ray.h"
#include "color.h"
#include "vec3.h"
#include "threadpool.h"
#include "pdf.h"


#include <iostream>
#include <fstream>
#include <thread>
#include <vector>


class camera {
    public:
        //ratio of image width over height
        double aspect_ratio = 1.0;
        //rendered image width in pixel count
        int image_width = 100;
        //count of random samples for each pixel
        int samples_per_pixel = 10;
        //maximum number of ray bounces into scene
        int max_depth = 10;
        // Scene background color
        color  background;


        double  vfov     = 90;
        point3  lookfrom = point3(0,0,0);
        point3  lookat   = point3(0,0,-1);
        vec3    vup      = vec3(0,1,0);

        double defocus_angle = 0;
        double focus_dist = 10;


        /* Public Camera Parameters Here */
        void render(const hittable& world, int num_threads, const hittable& lights) {
            initialize();

            std::ofstream file("image.ppm");

            std::string** output = new std::string*[image_height];  // Allocate rows
                for (int i = 0; i < image_height; ++i) {
                output[i] = new std::string[image_width];  // Allocate columns for each row
            }

            std::vector<std::thread> threads;


            ThreadPool pool(num_threads);

            file << "P3\n" << image_width << ' ' << image_height << "\n255\n";

            for (int j = 0; j < image_height; j++) {
                int assigned_line = j;
                pool.enqueue(([this, &world, output, assigned_line, &lights]()
                        { render_line(world, output, assigned_line, lights); }));
            }

            pool.waitUntilDone();

            for (int i = 0; i < image_height; i++)
            {
                for(int j = 0; j < image_width; j++)
                {
                    file << output[i][j];
                }
            }


            std::clog << "\nDone!\n";
            file.close();
        }


        void render_line(const hittable& world, std::string **output, int j, const hittable& lights)
        {
            // Pre-calculate these values outside all loops
            const int samples = sqrt_spp * sqrt_spp;
            const double inv_samples = 1.0 / samples;
            color* color_arr = new color[samples];
            
            for (int i = 0; i < image_width; i++) {
                color pixel_color(0,0,0);
                std::fill_n(color_arr, samples, color(0,0,0));
                
                for (int s_i = 0; s_i < sqrt_spp; s_i++) {
                    for (int s_j = 0; s_j < sqrt_spp; s_j++) {
                        sample_color(world, i, j, s_i, s_j, color_arr, lights);
                    }
                }


                //this will be reading from an output GPU buffer
                //so we are actually pretty close to what we already need here
                for (int sample = 0; sample < samples; sample++) {
                    pixel_color += color_arr[sample];
                }

                // Use pre-calculated inverse instead of multiplication
                pixel_color *= inv_samples;
                
                
                //this is actually really close to what we need
                output[j][i] = write_color(pixel_color);
            }
            
            delete[] color_arr;
        }

        void sample_color(const hittable& world, int i, int j, int s_i, int s_j,
                color color_arr[], const hittable& lights)
        {
            // Calculate the index in the color array based on the grid position
            int sample = s_i * sqrt_spp + s_j;
            ray r = get_ray(i, j, s_i, s_j);
            color_arr[sample] = ray_color(r, max_depth, world, lights);
        }




    private:
        /* Private Camera Variables Here */

        int    image_height;        // Rendered image height
        double pixel_samples_scale; //Color scale factor for a sum of pixel samples
        int    sqrt_spp;             // Square root of number of samples per pixel
        double recip_sqrt_spp;       // 1 / sqrt_spp
        point3 center;              // Camera center
        point3 pixel00_loc;         // Location of pixel 0, 0
        vec3   pixel_delta_u;       // Offset to pixel to the right
        vec3   pixel_delta_v;       // Offset to pixel below
        vec3   u, v, w;
        vec3   defocus_disk_u;
        vec3   defocus_disk_v;

        void initialize() {
            image_height = int(image_width / aspect_ratio);
            image_height = (image_height < 1) ? 1 : image_height;


            sqrt_spp = int(std::sqrt(samples_per_pixel));
            pixel_samples_scale = 1.0 / (sqrt_spp * sqrt_spp);
            recip_sqrt_spp = 1.0 / sqrt_spp;

            center = lookfrom;

            // Determine viewport dimensions.
            auto theta = degrees_to_radians(vfov);
            auto h = std::tan(theta/2);
            auto viewport_height = 2 * h * focus_dist;
            auto viewport_width = viewport_height * (double(image_width)/image_height);


            //calculate the u,v,w unit basis vectors for the camera coordinate frame
            w = unit_vector(lookfrom - lookat);
            u = unit_vector(cross(vup, w));
            v = cross(w,u);

            //calculate the vectors across the horizontal and down the vertical viewport edges
            vec3 viewport_u = viewport_width * u;
            vec3 viewport_v = viewport_height * -v;

            // Calculate the horizontal and vertical delta vectors from pixel to pixel.
            pixel_delta_u = viewport_u / image_width;
            pixel_delta_v = viewport_v / image_height;

            // Calculate the location of the upper left pixel.
            auto viewport_upper_left = center - (focus_dist * w) - viewport_u/2 - viewport_v/2;
            pixel00_loc = viewport_upper_left + 0.5 * (pixel_delta_u + pixel_delta_v);


            // Calculate the camera defocus disk basis vectors.
            auto defocus_radius = focus_dist * std::tan(degrees_to_radians(defocus_angle / 2));
            defocus_disk_u = u * defocus_radius;
            defocus_disk_v = v * defocus_radius;
        }

        ray get_ray(int i, int j, int s_i, int s_j) const {
        // Construct a camera ray originating from the defocus disk and directed at a randomly
        // sampled point around the pixel location i, j.
        auto offset = sample_square_stratified(s_i, s_j);
        auto pixel_sample = pixel00_loc
                          + ((i + offset.x()) * pixel_delta_u)
                          + ((j + offset.y()) * pixel_delta_v);

        auto ray_origin = (defocus_angle <= 0) ? center : defocus_disk_sample();
        auto ray_direction = pixel_sample - ray_origin;
        auto ray_time = random_double();

        return ray(ray_origin, ray_direction, ray_time);
        }


        vec3 sample_square_stratified(int s_i, int s_j) const {
            // Returns the vector to a random point in the square sub-pixel specified by grid
            // indices s_i and s_j, for an idealized unit square pixel [-.5,-.5] to [+.5,+.5].

            auto px = ((s_i + random_double()) * recip_sqrt_spp) - 0.5;
            auto py = ((s_j + random_double()) * recip_sqrt_spp) - 0.5;

            return vec3(px, py, 0);
        }

        vec3 sample_square() const {
            // Returns the vector to a random point in the [-.5,-.5]-[+.5,+.5] unit square.
            return vec3(random_double() - 0.5, random_double() - 0.5, 0);
        }




        point3 defocus_disk_sample() const {
            // Returns a random point in the camera defocus disk.
            auto p = random_in_unit_disk();
            return center + (p[0] * defocus_disk_u) + (p[1] * defocus_disk_v);
        }


        color ray_color(const ray& r, int depth, const hittable& world, const hittable& lights) const {
            ray current_ray = r;
            color final_color(0,0,0);
            color attenuation(1,1,1);
            
            for (int current_depth = depth; current_depth > 0; current_depth--) {
                hit_record rec;
                
                if (!world.hit(current_ray, interval(0.001, infinity), rec)) {
                    final_color += attenuation * background;
                    break;
                }

                scatter_record srec;
                color emission = rec.mat->emitted(current_ray, rec, rec.u, rec.v, rec.p);
                final_color += attenuation * emission;

                if (!rec.mat->scatter(current_ray, rec, srec)) {
                    break;
                }
                
                if (srec.skip_pdf) {
                    current_ray = srec.skip_pdf_ray;
                    attenuation = color(attenuation[0] * srec.attenuation[0],
                                     attenuation[1] * srec.attenuation[1],
                                     attenuation[2] * srec.attenuation[2]);
                    continue;
                }

                // Create light PDF with current hit point
                auto light_pdf = make_shared<hittable_pdf>(lights, rec.p);
                mixture_pdf p(light_pdf, srec.pdf_ptr);

                ray scattered = ray(rec.p, p.generate(), current_ray.time());
                auto pdf_value = p.value(scattered.direction());
                double scattering_pdf = rec.mat->scattering_pdf(current_ray, rec, scattered);

                if (pdf_value < 0.00001 || scattering_pdf < 0.00001) {
                    break;
                }

                color scale = (srec.attenuation * scattering_pdf) / pdf_value;
                attenuation = color(attenuation[0] * scale[0],
                                  attenuation[1] * scale[1],
                                  attenuation[2] * scale[2]);
                current_ray = scattered;
            }

            return final_color;
        }
};

#endif
