import sys
from stegano import lsb

def embed_file_in_image(image_path, file_to_hide, output_image):
    # Read the malicious file content
    with open(file_to_hide, "rb") as f:
        data = f.read()
    # Convert to hex string for embedding
    data_str = data.hex()
    # Hide the data in the image
    secret = lsb.hide(image_path, data_str)
    secret.save(output_image)
    print(f"Hidden file saved as: {output_image}")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python steg_embed.py <cover_image.png> <file_to_hide> <output_image.png>")
        sys.exit(1)
    image_path = sys.argv[1]
    file_to_hide = sys.argv[2]
    output_image = sys.argv[3]
    embed_file_in_image(image_path, file_to_hide, output_image)
