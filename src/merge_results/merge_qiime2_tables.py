import os
import sys
import subprocess

def find_table_qza_files(input_folder):
    """Pronalazi sve fajlove sa nazivom 'table.qza' u svim podfolderima."""
    table_files = []
    for root, _, files in os.walk(input_folder):
        if "table.qza" in files:
            table_files.append(os.path.join(root, "table.qza"))
    return table_files

def merge_tables(table_files, output_folder):
    """Poziva 'qiime feature-table merge' sa pronađenim table.qza fajlovima."""
    if not table_files:
        print("❌ No 'table.qza' files found.")
        return None

    command = ["qiime", "feature-table", "merge"]
    for table in table_files:
        command.extend(["--i-tables", table])

    merged_table_path = os.path.join(output_folder, "merged-table.qza")
    command.extend(["--o-merged-table", merged_table_path])

    try:
        subprocess.run(command, check=True)
        print(f"✅ Successfully created file: {merged_table_path}")
        return merged_table_path
    except subprocess.CalledProcessError as e:
        print(f"❌ Error occurred while merging tables: {e}")
        return None

def export_table(merged_table, output_folder):
    """Eksportuje merged-table.qza pomoću 'qiime tools export'."""
    export_path = os.path.join(output_folder, "export/table")
    os.makedirs(export_path, exist_ok=True)

    command = ["qiime", "tools", "export", "--input-path", merged_table, "--output-path", export_path]

    try:
        subprocess.run(command, check=True)
        print(f"✅ Table exported to: {export_path}")
        return export_path
    except subprocess.CalledProcessError as e:
        print(f"❌ Error while exporting table: {e}")
        return None

def convert_biom_to_tsv(export_path, output_folder):
    """Konvertuje feature-table.biom u table.tsv koristeći 'biom convert'."""
    biom_file = os.path.join(export_path, "feature-table.biom")
    tsv_output = os.path.join(output_folder, "merged-tables.tsv")

    if not os.path.exists(biom_file):
        print(f"❌ File {biom_file} does not exist")
        return

    command = ["biom", "convert", "-i", biom_file, "-o", tsv_output, "--to-tsv"]

    try:
        subprocess.run(command, check=True)
        print(f"✅ .tsv file created:{tsv_output}")
    except subprocess.CalledProcessError as e:
        print(f"❌ Error while creating .tsv: {e}")

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

    table_files = find_table_qza_files(input_folder)
    merged_table = merge_tables(table_files, output_folder)

    if merged_table:
        export_path = export_table(merged_table, output_folder)
        if export_path:
            convert_biom_to_tsv(export_path, output_folder)
