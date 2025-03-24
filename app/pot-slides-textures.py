import os
import glob
from PIL import Image
import numpy as np

def nearest_power_of_two(n):
    return 2**int(np.floor(np.log2(n)))

def optimize_images():
    image_dir = os.path.join("assets", "slides")
    pattern = os.path.join(image_dir, "*photo*.png")
    
    optimized_images = []
    
    for file_path in glob.glob(pattern):
        img = Image.open(file_path)
        width, height = img.size
        
        new_width = nearest_power_of_two(width)
        new_height = nearest_power_of_two(height)
        
        if (new_width, new_height) != (width, height):
            img = img.resize((new_width, new_height), Image.LANCZOS)
            img.save(file_path)
            optimized_images.append((file_path, width, height, new_width, new_height))
    
    print("Summary:")
    for file_path, old_w, old_h, new_w, new_h in optimized_images:
        print(f"{file_path}: {old_w}x{old_h} -> {new_w}x{new_h}")

if __name__ == "__main__":
    optimize_images()
