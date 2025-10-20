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

## Fetch samples from a particular project

To collect samples from a particular project, you can do like this:

```python
import itertools
from src.database import get_session, Dataset, Sample

# connect to the database
session = get_session()

# This will collect all dataset with a relation to samples
# (datasets that have been analyzed) and will resolve the samples
datasets = session.query(Dataset).join(Sample).all()

for dataset in datasets:
    print(dataset)

    # take first 10 samples
    for sample in itertools.islice(dataset.samples, 10):
        print(sample)
```

## download merged results

Connect to the FTP server and download the merged_results using lftp:

```bash
$ lftp -u <user>:<password> <ftp_host>
lftp> mirror merged_results
```

### Lasso-penalised regression

1. [filter_normalize.r](src/lasso/filter_normalize.r)
2. [train_lasso_model.r](src/lasso/train_lasso_model.r)
