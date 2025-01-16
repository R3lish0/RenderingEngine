def scale_obj_file(input_path, output_path, scale_factor=0.1):
    with open(input_path, 'r') as infile, open(output_path, 'w') as outfile:
        for line in infile:
            # If it's a vertex line (starts with 'v ')
            if line.startswith('v '):
                parts = line.split()
                # Scale the x, y, z coordinates
                scaled_coords = [float(parts[1]) * scale_factor,
                               float(parts[2]) * scale_factor,
                               float(parts[3]) * scale_factor]
                # Write the scaled vertex line
                outfile.write(f'v {scaled_coords[0]:.6f} {scaled_coords[1]:.6f} {scaled_coords[2]:.6f}\n')
            else:
                # Write all other lines unchanged
                outfile.write(line)

# Use the script
input_file = "meshes/cup.obj"
output_file = "meshes/cup_small.obj"
scale_obj_file(input_file, output_file, 0.4)  # Scale to 40% of original size
