import sys
import os
import glob

def convert_line_endings(filename):
    with open(filename, 'rb') as f:
        content = f.read()

    content = content.replace(b'\r\n', b'\n')

    with open(filename, 'wb') as f:
        f.write(content)

def main():
    if len(sys.argv) < 2:
        print("Usage: python script.py file_pattern")
        return

    file_pattern = sys.argv[1]

    input_files = glob.glob(file_pattern)
    if not input_files:
        print("No files found matching the pattern.")
        return

    for input_path in input_files:
        if os.path.isfile(input_path):
            convert_line_endings(input_path)
            print(f"Converted {input_path}.")

if __name__ == "__main__":
    main()