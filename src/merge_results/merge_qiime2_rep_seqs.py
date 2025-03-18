import os
import sys
import subprocess

def find_rep_seqs_qza_files(input_folder):
    rep_seqs_files = []
    for root, _, files in os.walk(input_folder):
        if "rep-seqs.qza" in files:
            rep_seqs_files.append(os.path.join(root, "rep-seqs.qza"))
    return rep_seqs_files

def merge_rep_seqs(rep_seqs_files, output_folder):
    if not rep_seqs_files:
        print("❌ No 'rep-seqs.qza' files found")
        return

    command = ["qiime", "feature-table", "merge-seqs"]

    for rep_seq in rep_seqs_files:
        command.extend(["--i-data", rep_seq])

    output_file = os.path.join(output_folder, "merged-rep-seqs.qza")
    command.extend(["--o-merged-data", output_file])

    try:
        subprocess.run(command, check=True)
        print(f"✅ Successfully created file: {output_file}")
        return output_file
    except subprocess.CalledProcessError as e:
        print(f"❌ Error occurred while merging tables: {e}")
        return None


def export_rep_seqs(merged_rep_seqs, output_folder):
    """Eksportuje merged-table.qza pomoću 'qiime tools export'."""
    export_path = os.path.join(output_folder, "export/rep-seqs.fasta")
    os.makedirs(export_path, exist_ok=True)

    command = ["qiime", "tools", "export", "--input-path", merged_rep_seqs, "--output-path", export_path]

    try:
        subprocess.run(command, check=True)
        print(f"✅ Table exported to: {export_path}")
        return export_path
    except subprocess.CalledProcessError as e:
        print(f"❌ Error while exporting table: {e}")
        return None

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("❌ Usage: python python merge_qiime2_rep_seqs.py <input_folder> <output_folder>")
        sys.exit(1)

    input_folder = sys.argv[1]
    output_folder = sys.argv[2]

    if not os.path.isdir(input_folder):
        print(f"❌ Input folder does not exist: {input_folder}")
        sys.exit(1)

    if not os.path.isdir(output_folder):
        os.makedirs(output_folder)

    rep_seqs_files = find_rep_seqs_qza_files(input_folder)
    merged_rep_seqs = merge_rep_seqs(rep_seqs_files, output_folder)

    if merged_rep_seqs:
        export_path = export_rep_seqs(merged_rep_seqs, output_folder)
