# deep_micro_core
Code repository for the DeepMicroCore project: Harnessing the power of artificial intelligence to identify the core microbiome [2024-2025]

- WP1-DATA: data collection and integration
- WP2-REPRESENTATION: data preprocessing and representation
- WP3-MODEL: model building and evaluation
- WP4-INTERPRET: feature extraction and model interpretation


## First experiment

Fastq files to be downloaded using the Nextflow pipeline ([see here](docs/fetchngs-example.md)) from
[ENA](https://www.ebi.ac.uk/ena) or [NCBI](https://www.ncbi.nlm.nih.gov/sra/), with the following project IDs:

- cow milk:  **PRJEB72623** and **PRJNA1103402**
- cow rumen: **PRJEB77087**
- cow rectum/hindgut/feces: **PRJEB77094**

## download merged results

Connect to the FTP server and download the merged_results using lftp:

```bash
$ lftp -u <user>:<password> <ftp_host>
lftp> mirror merged_results
```

## Merge results

Follow the instructions in the [merge-results.md](docs/merge-results.md) to
merge the results from multiple datasets.

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
poetry run python scripts/import_data.py <list datasets.csv>
# Or
poetry shell
python scripts/import_data.py <list datasets.csv>
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
poetry run import_data data/list_datasets.csv
```

Or within the virtual environment:

```bash
import_data data/list_dataset.csv
```

## Create metadata CSV file

You can create the metadata CSV file for the samples collected in the database:

```bash
poetry run create_metadata --output-dir merged_results
```

## Some example queries from the database

### Fetch samples from a particular project

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

### Collect dataset and parameters used

```python
import csv
import sys

from src.database import get_session, Dataset, Param

session = get_session()

header = [
    "dataset_id", "project", "FW_primer", "RV_primer",
    "trunclenf", "trunclenr", "trunc_qmin", "max_ee"
]

writer = csv.writer(sys.stdout, delimiter=",")
writer.writerow(header)

# collect datasets that have samples
for dataset in session.query(Dataset).filter(Dataset.samples.any()):
    writer.writerow([
        dataset.id, dataset.project, dataset.param.params.get("FW_primer"),
        dataset.param.params.get("RV_primer"), dataset.param.params.get("trunclenf"),
        dataset.param.params.get("trunclenr"), dataset.param.params.get("trunc_qmin"),
        dataset.param.params.get("max_ee")
    ])
```

## Lasso-penalised regression

1. [filter_normalize.r](src/lasso/filter_normalize.r)
2. [train_lasso_model.r](src/lasso/train_lasso_model.r)
