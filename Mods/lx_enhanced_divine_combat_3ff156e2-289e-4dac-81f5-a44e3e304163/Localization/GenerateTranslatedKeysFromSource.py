import argparse
import csv
from pathlib import Path
import glob


def parse_text_file(file_path):
    entries = {}
    with open(file_path, 'r') as file:
        current_entry = None
        for line in file:
            line = line.strip()
            if line.startswith('new entry'):
                current_entry = {}
                entry_name = line.split('"')[1]
                entries[entry_name] = current_entry
            elif line.startswith('data') and current_entry is not None:
                parts = line.split('"')
                key = parts[1]
                value = parts[3]
                current_entry[key] = value
    return entries


def read_tsv_file(tsv_file_path):
    data = []
    with open(tsv_file_path, mode='r', encoding = "ISO-8859-1") as file:
        tsv_reader = csv.reader(file, delimiter='\t', quoting=csv.QUOTE_MINIMAL)
        for row in tsv_reader:
            data.append(row)
    return data


def write_tsv_file(tsv_file_path, data):
    with open(tsv_file_path, mode='w', newline='', encoding = "ISO-8859-1") as file:
        tsv_writer = csv.writer(file, delimiter='\t', quoting=csv.QUOTE_MINIMAL)
        for row in data:
            tsv_writer.writerow(row)


def update_tsv_file_with_entries(tsv_file_path, entries):
    data = read_tsv_file(tsv_file_path)
    headers = data[0]
    data_dict = {row[0]: row for row in data[1:]}

    for entry in entries.values():
        display_name_key = entry.get("DisplayName")
        description_key = entry.get("Description")

        # Check and update DisplayNameRef
        if display_name_key:
            display_name_ref = entry.get("DisplayNameRef")
            if display_name_ref and not display_name_ref.startswith("|"):
                if display_name_key not in data_dict or data_dict[display_name_key][1] != display_name_ref:
                    print(
                        f"Updating DisplayNameRef for {display_name_key}: {data_dict.get(display_name_key, ['N/A', 'N/A'])[1]} -> {display_name_ref}")
                    if display_name_key in data_dict:
                        data_dict[display_name_key][1] = display_name_ref
                    else:
                        data_dict[display_name_key] = [display_name_key, display_name_ref, '']

        # Check and update DescriptionRef
        if description_key:
            description_ref = entry.get("DescriptionRef")
            if description_ref and not description_ref.startswith("|"):
                if description_key not in data_dict or data_dict[description_key][1] != description_ref:
                    print(
                        f"Updating DescriptionRef for {description_key}: {data_dict.get(description_key, ['N/A', 'N/A'])[1]} -> {description_ref}")
                    if description_key in data_dict:
                        data_dict[description_key][1] = description_ref
                    else:
                        data_dict[description_key] = [description_key, description_ref, '']

    # Combine headers and updated data_dict into a list
    updated_data = [headers] + list(data_dict.values())
    write_tsv_file(tsv_file_path, updated_data)


def main(text_file_pattern, tsv_file_path):
    text_files = glob.glob(text_file_pattern)

    for file_path in text_files:
        entries = parse_text_file(file_path)
        update_tsv_file_with_entries(tsv_file_path, entries)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Update TSV file with entries from text files.')
    parser.add_argument('text_file_pattern', type=str, help='Pattern to match text files (e.g., "*.txt")')
    parser.add_argument('tsv_file_path', type=Path, help='Path to the TSV file to update')

    args = parser.parse_args()

    main(args.text_file_pattern, args.tsv_file_path)
