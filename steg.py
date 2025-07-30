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

def extract_file_from_image(image_path, output_file=None):
    # Reveal the hidden hex string
    data_str = lsb.reveal(image_path)
    if data_str is None:
        print("No hidden data found in the image.")
        return
    data = bytes.fromhex(data_str)
    if not output_file:
        output_file = "extracted_file.bin"
    else:
        output_file = output_file.strip() or "extracted_file.bin"
    with open(output_file, "wb") as f:
        f.write(data)
    print(f"Extracted file saved as: {output_file}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage:")
        print("  To embed:   python steg.py embed <cover_image.png> <file_to_hide> <output_image.png>")
        print("  To extract: python steg.py extract <stego_image.png> [output_file]")
        sys.exit(1)
    mode = sys.argv[1].lower()
    if mode == "embed":
        if len(sys.argv) != 5:
            print("Usage: python steg.py embed <cover_image.png> <file_to_hide> <output_image.png>")
            sys.exit(1)
        image_path = sys.argv[2]
        file_to_hide = sys.argv[3]
        output_image = sys.argv[4]
        embed_file_in_image(image_path, file_to_hide, output_image)
    elif mode == "extract":
        image_path = sys.argv[2]
        if len(sys.argv) >= 4:
            output_file = sys.argv[3]
        else:
            output_file = input("Enter the name for the extracted file [extracted_file.bin]: ").strip() or "extracted_file.bin"
        extract_file_from_image(image_path, output_file)
    else:
        print("Unknown mode. Use 'embed' or 'extract'.")
        sys.exit(1)
