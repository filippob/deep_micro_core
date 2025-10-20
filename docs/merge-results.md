# QIIME Merging Automation

This file contains instructions to merge QIIME2 tables, representative sequences, and taxonomy files automatically.

## Installation

Before running the scripts, make sure QIIME2 is installed.
Follow the official installation guide: [QIIME2 Installation Guide](https://docs.qiime2.org/2024.10/install/native/)

### Using nf-core/ampliseq singularity images

An alternative way to use QIIME2 is through the singularity image provided by the
`nf-core/ampliseq` pipeline. All the commands in the [How to Use](#how-to-use)
section of this document can be run inside the singularity container using
singularity shell or exec, for example:

```bash
singularity shell $NXF_SINGULARITY_CACHEDIR/qiime2-core-2023.7.img
```

or

```bash
singularity exec $NXF_SINGULARITY_CACHEDIR/qiime2-core-2023.7.img <command>
```
Where `$NXF_SINGULARITY_CACHEDIR` is the directory where Nextflow stores singularity
images. Remember to exit the container if you used `singularity shell` approach.

> NOTE: this singularity image is provided from the
> [nf-core/ampliseq -r 2.11.0](https://nf-co.re/ampliseq/2.11.0) pipeline
> used within this project.

## How to Use

### 1. Move to the script directory:

All the command below should be run inside the `src/merge_results` directory:

```bash
cd src/merge_results
```

### 2. Run the script with the required parameters

```bash
./run_all_qiime2.sh /path/to/input_folder /path/to/output_folder
```

Where:

* /path/to/input_folder → Folder containing all files from different runs using the ampliseq pipeline
* /path/to/output_folder → Folder where the merged results will be saved

for example:

```bash
./run_all_qiime2.sh ../../results/ ../../merged_results/
```

if you have mirrored the `results` folder from FTP in this project root directory.

## Expected Output

After running the script, you should see the following output files in the output folder:

* merged-table.qza
* merged-rep-seqs.qza
* merged-taxonomy.qza
* Exported files in /path/to/output_folder/export and merged-table.tsv (converted from .biom)
