# import_data.py

import csv
from .database import get_session, Dataset


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
