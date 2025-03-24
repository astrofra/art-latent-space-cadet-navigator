from PIL import Image
import os
import json

def generate_meta_json(filename):
    # Define the JSON structure
    data = {
        "profiles": {
            "default": {
                "compression": "BC7",
                "wrap-U": "Clamp",
                "wrap-V": "Clamp"
            }
        }
    }
    
    # Create the .meta filename by appending ".meta" to the original filename
    meta_filename = f"{filename}.meta"
    
    # Write the JSON structure to the .meta file
    with open(meta_filename, "w") as f:
        json.dump(data, f, indent=4)

    print(f"Meta file created: {meta_filename}")


# Increase the maximum allowable pixel count for large images
Image.MAX_IMAGE_PIXELS = None

def split_image(image_path, output_folder="output", tile_size=1024):
    # Load the image
    image = Image.open(image_path)
    width, height = image.size

    # Ensure output directory exists
    os.makedirs(output_folder, exist_ok=True)

    # Iterate over each tile position
    for y in range(0, height, tile_size):
        for x in range(0, width, tile_size):
            # Define the box for the current tile
            box = (x, y, min(x + tile_size, width), min(y + tile_size, height))
            tile = image.crop(box)

            # Create the filename based on position
            tile_filename = f"{os.path.splitext(os.path.basename(image_path))[0]}_{x//tile_size}_{y//tile_size}.png"
            tile_path = os.path.join(output_folder, tile_filename)

            # Save the tile
            tile.save(tile_path)
            generate_meta_json(tile_path)

    print("Image split completed. Tiles saved in:", output_folder)

# Run the function with the specified image file
split_image("midjourney-process.png")
