from pathlib import Path

# determine the current file's path
current_file = Path(__file__)

# let's find the project directory by looking for the pyproject.toml file
project_directory = current_file.parent

while (project_directory / "pyproject.toml").exists() is False:
    project_directory = project_directory.parent
