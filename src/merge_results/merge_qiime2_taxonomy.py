import os
import sys
import subprocess

def find_taxonomy_qza_files(input_folder):
    taxa_files = []
    for root, _, files in os.walk(input_folder):
        if "taxonomy.qza" in files:
            taxa_files.append(os.path.join(root, "taxonomy.qza"))
    return taxa_files

def merge_taxonomy(taxa_files, output_folder):
    if not taxa_files:
        print("❌ No 'taxonomy.qza' files found.")
        return

    command = ["qiime", "feature-table", "merge-taxa"]

    for taxa in taxa_files:
        command.extend(["--i-data", taxa])

    output_file = os.path.join(output_folder, "merged-taxonomy.qza")
    command.extend(["--o-merged-data", output_file])

    try:
        subprocess.run(command, check=True)
        print(f"✅ Successfully created file: {output_file}")
        return output_file
    except subprocess.CalledProcessError as e:
        print(f"❌ Error occurred while merging tables: {e}")
        return None


def export_taxonomy(merged_tax, output_folder):
    export_path = os.path.join(output_folder, "export/taxonomy")
    os.makedirs(export_path, exist_ok=True)

    command = ["qiime", "tools", "export", "--input-path", merged_tax, "--output-path", export_path]

    try:
        subprocess.run(command, check=True)
        print(f"✅ Table exported to: {export_path}")
        return export_path
    except subprocess.CalledProcessError as e:
        print(f"❌ Error while exporting table: {e}")
        return None


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("❌ Usage: python merge_qiime2_tables.py <input_folder> <output_folder>")
        sys.exit(1)

    input_folder = sys.argv[1]
    output_folder = sys.argv[2]

    if not os.path.isdir(input_folder):
        print(f"❌ Input folder does not exist: {input_folder}")
        sys.exit(1)

    if not os.path.isdir(output_folder):
        os.makedirs(output_folder)

    tax_files = find_taxonomy_qza_files(input_folder)
    merged_taxa = merge_taxonomy(tax_files, output_folder)

    if merged_taxa:
        export_path = export_taxonomy(merged_taxa, output_folder)

