# import_data.py

import csv
import argparse

from .database import get_session, Dataset, init_db, Sample
from .ftp import collect_samples

# define the relationship between the results folder name and the
# row in the dataset table
SAMPLES_DICT = {
    "201102_M04028_0119_000000000-JBG8C_hindgut": {
        "internal_id": "201102_M04028_0119_000000000-JBG8C",
        "tissue": "hindgut",
    },
    "201102_M04028_0119_000000000-JBG8C_rumen": {
        "internal_id": "201102_M04028_0119_000000000-JBG8C",
        "tissue": "rumen",
    },
    "PRJEB72623": {"project_id": "PRJEB72623"},
    "PRJEB77087": {"project_id": "PRJEB77087"},
    "PRJEB77094_201026_M04028_0118_000000000-JBFT6": {
        "project_id": "PRJEB77094",
        "internal_id": "201026_M04028_0118_000000000-JBFT6",
    },
    "PRJNA1103402": {"project_id": "PRJNA1103402"},
}


# beware: not tested
def import_dataset(row):
    session = get_session()
    new_dataset = Dataset(**row)
    session.add(new_dataset)
    session.commit()
    session.close()
    print(f"Dataset {new_dataset} imported successfully.")


def import_datasets_from_csv(file_path):
    session = get_session()

    fields = [
        "description",
        "project",
        "year",
        "type_technology",
        "variable_region",
        "specie_substrate",
        "population",
        "tissue",
        "experiment",
        "n_samples",
        "link",
        "data_repository",
        "project_id",
        "status",
        "internal_id",
        "notes",
        "fwd_primer",
        "rev_primer",
        "adapter_fwd",
        "adapter_rev",
    ]

    with open(file_path, mode="r", encoding="utf-8") as csvfile:
        reader = csv.DictReader(csvfile, delimiter=",", fieldnames=fields)
        datasets = []

        # need to ignore the header
        next(reader)

        for row in reader:
            # create a instance for every dataset
            dataset = Dataset(**row)
            datasets.append(dataset)

        # add all instances then commit
        session.add_all(datasets)
        session.commit()

        print(f"Imported {len(datasets)} datasets from {file_path}.")

    session.close()


def import_samples():
    samples = collect_samples()
    session = get_session()

    for key, rows in samples.items():
        # print(f"Key: {key}, Value: {value}")

        query = session.query(Dataset)

        for column, value in SAMPLES_DICT[key].items():
            query = query.filter(getattr(Dataset, column) == value)

        dataset = query.one()

        for row in rows:
            sample = Sample(
                dataset_id=dataset.id,
                sample_id=row[0],
                forward_reads=row[1],
                reverse_reads=row[2],
            )
            session.add(sample)
        session.commit()

        print(f"Samples for {dataset} imported successfully.")


def import_data():
    parser = argparse.ArgumentParser(
        description="Import datasets and samples into a sqlite database"
    )

    parser.add_argument("csv_file", help="Path to the CSV file to import.")
    args = parser.parse_args()

    # create a database in a data folder relative to project directory
    init_db()

    # import datasets from the CSV file
    import_datasets_from_csv(args.csv_file)

    # import samples from the FTP server and create the relationships
    import_samples()
