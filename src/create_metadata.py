#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on: $(date)
Author: $(author)
Description: Brief description of what this module does
"""

__author__ = "Paolo Cozzi"
__version__ = "1.0.0"
__email__ = "paolo.cozzi@ibba.cnr.it"

import csv
import argparse

from sqlalchemy import func

from .database import get_session, Dataset, Sample, Param


def create_metadata():
    """Create metadata CSV files"""

    parser = argparse.ArgumentParser(
        description="Create metadata CSV files from the database"
    )

    parser.add_argument(
        "--output-dir",
        type=str,
        default=".",
        help="Directory to save the output CSV files",
    )

    args = parser.parse_args()
    session = get_session()

    # a query for all samples with related dataset info
    results = (
        session.query(
            Sample.sample_id,
            Dataset.project_id,
            Dataset.project,
            Dataset.tissue,
            Dataset.specie_substrate,
            Dataset.data_repository,
        )
        .join(Dataset)
        .all()
    )

    data = []
    for row in results:
        data.append(
            {
                "Sample ID": row.sample_id,
                "Project ID": row.project_id,
                "Project Name": row.project,
                "Tissue": row.tissue,
                "Species/Substrate": row.specie_substrate,
                "Data repository": row.data_repository,
            }
        )

    with open(
        f"{args.output_dir}/Metadata.csv", mode="w", encoding="utf-8", newline="\n"
    ) as csvfile:
        if data:
            writer = csv.DictWriter(
                csvfile,
                fieldnames=data[0].keys(),
                lineterminator="\n",
                quoting=csv.QUOTE_MINIMAL,
            )
            writer.writeheader()
            writer.writerows(data)

    # a query for all datasets with their parameters
    results = (
        session.query(
            Dataset.id,
            Dataset.project,
            Dataset.specie_substrate,
            Dataset.tissue,
            Dataset.internal_id,
            Sample.folder_name,
            Dataset.fwd_primer,
            Param.params,
            func.count().label("n_samples"),
        )
        .join(Sample)
        .join(Param)
        .group_by(Dataset.id)
        .all()
    )

    data = []
    for row in results:
        data.append(
            {
                "dataset_id": row.id,
                "project": row.project,
                "specie_substrate": row.specie_substrate,
                "tissue": row.tissue,
                "n_samples": row.n_samples,
                "internal_id": row.internal_id,
                "folder_name": row.folder_name,
                "fwd_primer": row.params.get("FW_primer"),
                "rev_primer": row.params.get("RV_primer"),
                "trunclenf": row.params.get("trunclenf"),
                "trunclenr": row.params.get("trunclenr"),
                "trunc_qmin": row.params.get("trunc_qmin"),
                "max_ee": row.params.get("max_ee"),
            }
        )

    with open(
        f"{args.output_dir}/Datasets.csv", mode="w", encoding="utf-8", newline="\n"
    ) as csvfile:
        if data:
            writer = csv.DictWriter(
                csvfile,
                fieldnames=data[0].keys(),
                lineterminator="\n",
                quoting=csv.QUOTE_MINIMAL,
            )
            writer.writeheader()
            writer.writerows(data)

    session.close()


if __name__ == "__main__":
    create_metadata()
