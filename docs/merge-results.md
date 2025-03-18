# QIIME Merging Automation

This file contains instructions to merge QIIME2 tables, representative sequences, and taxonomy files automatically.

## Installation

Before running the scripts, make sure QIIME2 is installed.
Follow the official installation guide: [QIIME2 Installation Guide](https://docs.qiime2.org/2024.10/install/native/)


## How to Use

### 1. Prepare the script
First, give execution permission to the shell script:

```bash
chmod +x run_all_qiime2.sh
```
### 2. Run the script with the required parameters

```bash
./run_all_qiime2.sh /path/to/input_folder /path/to/output_folder
```

Where:

* /path/to/input_folder → Folder containing all files from different runs using the ampliseq pipeline
* /path/to/output_folder → Folder where the merged results will be saved

## Expected Output
After running the script, you should see the following output files in the output folder:

* merged-table.qza
* merged-rep-seqs.qza
* merged-taxonomy.qza
* merged-table.tsv (converted from .biom)
