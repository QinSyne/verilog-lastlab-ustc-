from PIL import Image
import sys
import os

def generate_coe(image_path, output_path):
    if not os.path.exists(image_path):
        print(f"Error: File {image_path} not found.")
        return

    try:
        img = Image.open(image_path)
        # Resize to 200x150 as per tutorial
        img = img.resize((200, 150))
        img = img.convert("RGB")
        
        with open(output_path, "w") as f:
            f.write("memory_initialization_radix=16;\n")
            f.write("memory_initialization_vector=\n")
            
            pixels = list(img.getdata())
            total_pixels = len(pixels)
            for i, pixel in enumerate(pixels):
                r, g, b = pixel
                # Scale 8-bit to 4-bit
                r = r >> 4
                g = g >> 4
                b = b >> 4
                val = (r << 8) | (g << 4) | b
                
                if i == total_pixels - 1:
                    f.write(f"{val:03X};") # Last element ends with semicolon
                else:
                    f.write(f"{val:03X},") # Others end with comma
                    if (i + 1) % 16 == 0:
                        f.write("\n")      # Newline every 16 pixels for readability
        print(f"Generated {output_path} from {image_path}")
        
        # Also generate a .mem file for behavioral simulation
        mem_path = output_path.replace(".coe", ".mem")
        with open(mem_path, "w") as f:
            for pixel in pixels:
                r, g, b = pixel
                r = r >> 4
                g = g >> 4
                b = b >> 4
                val = (r << 8) | (g << 4) | b
                f.write(f"{val:03X}\n")
        print(f"Generated {mem_path} for simulation")

    except Exception as e:
        print(f"Error processing image: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        # If multiple images are provided, concatenate them
        if len(sys.argv) > 2:
            print("Generating multi-frame COE from multiple images...")
            all_pixels = []
            for img_path in sys.argv[1:]:
                if not os.path.exists(img_path):
                    print(f"Warning: {img_path} not found, skipping.")
                    continue
                try:
                    img = Image.open(img_path)
                    img = img.resize((200, 150))
                    img = img.convert("RGB")
                    pixels = list(img.getdata())
                    all_pixels.extend(pixels)
                except Exception as e:
                    print(f"Error processing {img_path}: {e}")
            
            output_path = "video.coe"
            with open(output_path, "w") as f:
                f.write("memory_initialization_radix=16;\n")
                f.write("memory_initialization_vector=\n")
                for i, pixel in enumerate(all_pixels):
                    r, g, b = pixel
                    r = r >> 4
                    g = g >> 4
                    b = b >> 4
                    val = (r << 8) | (g << 4) | b
                    
                    if i == len(all_pixels) - 1:
                        f.write(f"{val:03X};")
                    else:
                        f.write(f"{val:03X},")
                        if (i + 1) % 16 == 0:
                            f.write("\n")
            print(f"Generated {output_path} with {len(sys.argv)-1} frames.")
            
        else:
            generate_coe(sys.argv[1], "image.coe")
    else:
        print("Usage: python image_gen.py <image_file>")
        # Create a dummy image for testing if no argument
        print("Generating dummy test image...")
        img = Image.new('RGB', (200, 150), color = 'red')
        img.save('test_image.png')
        generate_coe('test_image.png', 'image.coe')
