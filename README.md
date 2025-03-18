# deep_micro_core
Code repository for the DeepMicroCore project: Harnessing the power of artificial intelligence to identify the core microbiome [2024-2025]

- WP1-DATA: data collection and integration
- WP2-REPRESENTATION: data preprocessing and representation
- WP3-MODEL: model building and evaluation
- WP4-INTERPRET: feature extraction and model interpretation


## First experiment

Fastq files to be downloaded using the Nextflow pipeline ([see here](https://github.com/filippob/deep_micro_core/blob/main/docs/fetchngs-example.md)) from 
[ENA](https://www.ebi.ac.uk/ena) or [NCBI](https://www.ncbi.nlm.nih.gov/sra/), with the following project IDs:

- cow milk:  **PRJEB72623** and **PRJNA1103402**
- cow rumen: **PRJEB77087**
- cow rectum/hindgut/feces: **PRJEB77094**

## Install stuff with poetry

You require [poetry](https://python-poetry.org/) to install the dependencies. In
the project root directory, run:

```bash
poetry install
```

To install *all the required dependencies*. Then you can run the scripts in the
`scripts` directory using the `poetry run` command or by activating the virtual
environment with `poetry shell`:

```bash
poetry run python scripts/import_data.py
# Or
poetry shell
python scripts/import_data.py
```

Type `exit` to exit the virtual environment.

## Define environment variables

Create a `.env` file in the project root directory and provide your 
credentials (not to be stored in the github repository):

```text
FTP_HOST=<your FTP repository host>
FTP_USER=<your FTP username>
FTP_PASS=<your FTP password>
```

## Collect metadata in a sqlite database

Download the **list_dataset** google sheet as a CSV file and save it in the
`data` directory. Then run the following script:

```bash
poetry run import_data data/list_dataset.csv
```

Or within the virtual environment:

```bash
import_data data/list_dataset.csv
```
