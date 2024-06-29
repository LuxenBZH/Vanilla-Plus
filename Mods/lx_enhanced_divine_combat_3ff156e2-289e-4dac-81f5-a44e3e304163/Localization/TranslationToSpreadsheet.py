import os
import argparse
import csv
import xml.etree.ElementTree as ET


def read_xml(folder_path):
    data = {}

    for root, dirs, files in os.walk(folder_path):
        if any(file.endswith(".xml") for file in files):
            for file in files:
                if file.endswith(".xml"):
                    file_path = os.path.join(root, file)
                    tree = ET.parse(file_path)
                    root = tree.getroot()
                    contents = root.findall("content")
                    for content in contents:
                        contentuid = content.attrib["contentuid"]
                        text = content.text
                        if contentuid not in data:
                            data[contentuid] = {}
                        data[contentuid][file] = text

    return data


def create_csv(data, output_filename):
    with open(output_filename, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = ['ContentUID'] + sorted(next(iter(data.values())).keys())
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

        writer.writeheader()
        for contentuid, contents in data.items():
            row = {'ContentUID': contentuid}
            for file_name, content in contents.items():
                row[file_name] = content
            writer.writerow(row)

        print(f"CSV file '{output_filename}' created successfully.")


def read_csv(input_filename):
    data = {}

    with open(input_filename, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)

        for row in reader:
            contentuid = row['ContentUID']
            for key, value in row.items():
                if key != 'ContentUID':
                    if contentuid not in data:
                        data[contentuid] = {}
                    data[contentuid][key] = value

    return data


def create_xml_files(data, output_folder):
    for contentuid, contents in data.items():
        root = ET.Element("contentList")
        for file_name, content in contents.items():
            content_elem = ET.SubElement(root, "content")
            content_elem.attrib["contentuid"] = contentuid
            content_elem.text = content

        tree = ET.ElementTree(root)
        output_path = os.path.join(output_folder, f"{contentuid}.xml")
        tree.write(output_path)
        print(f"XML file '{output_path}' created successfully.")


def main():
    parser = argparse.ArgumentParser(description="Process XML files and create CSV file")
    parser.add_argument("input_directory", help="Path to the directory containing folders with XML files")
    parser.add_argument("output_filename", help="Output CSV filename")
    parser.add_argument("-toxml", dest="toxml", action="store_true", help="Convert CSV file to XML files")
    parser.add_argument("-output_folder", dest="output_folder",
                        help="Output folder for XML files (required with -toxml option)")
    args = parser.parse_args()

    if args.toxml:
        if not args.output_folder:
            parser.error("-toxml requires -output_folder")
        data = read_csv(args.output_filename)
        create_xml_files(data, args.output_folder)
    else:
        data = read_xml(args.input_directory)
        create_csv(data, args.output_filename)


if __name__ == "__main__":
    main()
