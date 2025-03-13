import argparse

def hex2bin(file):
    with open(file, "r") as hex_file, open("output.bin", "wb") as bin_file:
        for line in hex_file:
            bin_file.write(bytes.fromhex(line.strip()))

if __name__ == "__main__":
    # argparse get the file name passed on the parameter command line
    parser = argparse.ArgumentParser(description="Convert hexadecimal file to binary. Default output is called output.bin")
    parser.add_argument("input_file", help="File path with hexadecimal data")
    args = parser.parse_args()
    
    hex2bin(args.input_file)