import os
import io
import csv
import json
import logging

from dotenv import load_dotenv
from ftplib import FTP

logger = logging.getLogger(__name__)

load_dotenv()


def collect_samples():
    ftp_host = os.getenv("FTP_HOST")
    ftp_user = os.getenv("FTP_USER")
    ftp_password = os.getenv("FTP_PASS")

    ftp = FTP(ftp_host)
    ftp.login(ftp_user, ftp_password)

    ftp.cwd("results")

    file_list = []
    ftp.retrlines("LIST", file_list.append)

    # determine folders
    directories = []
    for entry in file_list:
        if entry.startswith("d"):
            directories.append(entry.split()[-1])

    # print("Directories:", directories)

    all_samples = {}

    # Process each directory
    for directory in directories:
        ftp.cwd(f"{directory}/input")

        # List files in the input directory
        input_files = []
        ftp.retrlines("LIST", input_files.append)

        # Find the CSV file (assuming there's only one)
        csv_file = None
        for entry in input_files:
            parts = entry.split()
            if parts[-1].endswith(".csv"):
                csv_file = parts[-1]
                break

        if csv_file:
            logger.info(f"Found CSV file: {csv_file} in {directory}/input")

            # Read the CSV file content
            with io.BytesIO() as csv_buffer:
                ftp.retrbinary(f"RETR {csv_file}", csv_buffer.write)
                csv_buffer.seek(0)

                # decode the content
                csv_buffer = io.TextIOWrapper(csv_buffer, encoding="utf-8")

                reader = csv.reader(csv_buffer)

                # ignore the header
                next(reader)

                content = list(reader)

            # add content to the dictionary
            all_samples[directory] = content

        # Go back to the results directory
        ftp.cwd("../../")

    ftp.quit()

    return all_samples


def collect_params():
    ftp_host = os.getenv("FTP_HOST")
    ftp_user = os.getenv("FTP_USER")
    ftp_password = os.getenv("FTP_PASS")

    ftp = FTP(ftp_host)
    ftp.login(ftp_user, ftp_password)
    logger.info("Connected to FTP server")

    ftp.cwd("results")

    file_list = []
    ftp.retrlines("LIST", file_list.append)
    logger.debug(f"Listed files in results directory: {file_list}")

    # determine folders
    directories = []
    for entry in file_list:
        logger.debug(f"Directory: {entry}")
        if entry.startswith("d"):
            directories.append(entry.split()[-1])

    logger.info(f"Found directories: {directories}")

    all_params = {}

    # Process each directory
    for directory in directories:
        ftp.cwd(f"{directory}/pipeline_info")

        # List files in the pipeline_info directory
        files = []
        ftp.retrlines("LIST", files.append)

        # Find the .json file
        params_files = []
        for entry in files:
            logger.debug(f"Entry: {entry}")
            parts = entry.split()

            if parts[-1].endswith(".json"):
                params_files.append(parts[-1])

        # ...existing code...

        if params_files:
            # Ordina e prendi il file più recente
            most_recent_params = sorted(params_files)[-1]
            logger.info(
                f"Found most recent params file: {most_recent_params} in {directory}/pipeline_info"
            )

        # Read the params file content
        with io.BytesIO() as params_buffer:
            ftp.retrbinary(f"RETR {most_recent_params}", params_buffer.write)
            params_buffer.seek(0)

            # decode the content and parse JSON
            params_content = params_buffer.read().decode("utf-8")
            params_data = json.loads(params_content)

        # add parsed JSON data to the dictionary
        all_params[directory] = params_data

        # Go back to the results directory
        ftp.cwd("../../")

    ftp.quit()

    return all_params


if __name__ == "__main__":
    collect_samples()
