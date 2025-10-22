# import_data.py

import csv
import argparse
import logging
import sqlalchemy.exc

from .database import get_session, Dataset, init_db, Sample, Param
from .ftp import collect_samples, collect_params

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# define the relationship between the results folder name and the
# row in the dataset table. You need to specify enough information to
# uniquely identify the dataset, for example project_id and tissue or internal_id
# the key in SAMPLES_DICT is the folder name in the FTP server
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
    "PRJNA635258": {"project_id": "PRJNA635258", "specie_substrate": "mouse"},
    "K74V8": {
        "project_id": "PRJNA1003434",
        "description": "8 goats: 16s",
        # "tissue": "feces",
        "tissue": "rumen",
    },
}

# define sample ranges as a list of sample IDs for each folder name key
SAMPLES_RANGES = {
    # "K74V8": [f"sample_{i + 1}" for i in range(0, 30)],  # feces
    "K74V8": [f"sample_{i + 1}" for i in range(30, 59)],  # rumen
}


# beware: not tested
def import_dataset(row):
    session = get_session()
    new_dataset = Dataset(**row)
    session.add(new_dataset)
    session.commit()
    session.close()
    logger.info(f"Dataset {new_dataset} imported successfully.")


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

        # need to ignore the header
        next(reader)

        inserted_count = 0
        updated_count = 0

        for row in reader:
            logger.debug(f"Processing row: {row}")

            # search for dataset relying on unique key
            existing_dataset = (
                session.query(Dataset)
                .filter_by(
                    description=row["description"],
                    specie_substrate=row["specie_substrate"],
                    tissue=row["tissue"],
                )
                .first()
            )

            if existing_dataset:
                # update the dataset
                for key, value in row.items():
                    setattr(existing_dataset, key, value)
                updated_count += 1
            else:
                # create a new dataset
                dataset = Dataset(**row)
                session.add(dataset)
                inserted_count += 1

        # then commit
        session.commit()

    logger.info(f"Imported datasets from {file_path}.")
    logger.info(f"Inserted {inserted_count} new records.")
    logger.info(f"Updated {updated_count} existing records.")

    session.close()


def import_samples():
    samples = collect_samples()
    session = get_session()

    for key, rows in samples.items():
        query = session.query(Dataset)

        # build the query filters based on the SAMPLES_DICT
        # add a column filter for each key-value pair
        for column, value in SAMPLES_DICT[key].items():
            query = query.filter(getattr(Dataset, column) == value)

        try:
            dataset = query.one()

            for row in rows:
                if key in SAMPLES_RANGES:
                    if row[0] not in SAMPLES_RANGES[key]:
                        logger.warning(
                            f"Sample {row[0]} not in defined range for {key}, skipping."
                        )
                        continue

                logger.debug(f"Importing sample {row} for dataset {dataset}")

                existing_sample = (
                    session.query(Sample)
                    .filter_by(dataset_id=dataset.id, sample_id=row[0])
                    .first()
                )

                if existing_sample:
                    logger.debug(
                        f"Sample with dataset_id={dataset.id} and sample_id={row[0]} already exists. Skipping."
                    )
                    continue

                else:
                    logger.debug(f"Creating new sample for dataset {dataset}")

                    sample = Sample(
                        dataset_id=dataset.id,
                        sample_id=row[0],
                        folder_name=key,
                        forward_reads=row[1],
                        reverse_reads=row[2],
                    )
                    session.add(sample)
                    logger.debug(f"Sample added: {sample}")

            session.commit()

            logger.info(f"Samples for {dataset} imported successfully.")

        except sqlalchemy.exc.NoResultFound as exc:
            logger.error(f"No dataset found for key {key}, skipping samples import.")
            raise exc

        except sqlalchemy.exc.MultipleResultsFound as exc:
            logger.error(
                f"Multiple datasets found for key {key}, skipping samples import."
            )
            raise exc


def import_params():
    """Import parameters from FTP server into the database"""
    params_dict = collect_params()
    session = get_session()

    for directory, params_data in params_dict.items():
        logger.info(f"Processing params for directory: {directory}")

        # collect the proper dataset: the directory I got from collect_params()
        # is the key in SAMPLES_DICT
        if directory not in SAMPLES_DICT:
            logger.warning(f"No mapping found for directory: {directory}")
            continue

        query = session.query(Dataset)
        for column, value in SAMPLES_DICT[directory].items():
            query = query.filter(getattr(Dataset, column) == value)

        dataset = query.one_or_none()

        if dataset:
            existing_param = (
                session.query(Param).filter_by(dataset_id=dataset.id).first()
            )

            if existing_param:
                logger.debug(
                    f"Parameters for dataset {dataset} already exist. Skipping"
                )
                continue
            else:
                logger.info(f"Adding new parameters for dataset {dataset}.")
                # save parameters as json
                params = Param(dataset_id=dataset.id, params=params_data)
                session.add(params)

            logger.info(f"Updated params for dataset: {dataset}")
        else:
            logger.warning(f"No dataset found for directory: {directory}")

    session.commit()
    session.close()


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

    # store parameters in database
    import_params()
