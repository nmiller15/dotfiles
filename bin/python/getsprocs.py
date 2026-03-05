from pathlib import Path
import re
import sys
import os
import logging

logging.basicConfig(
    level=logging.DEBUG,  # DEBUG, INFO, WARNING, ERROR, CRITICAL
    format="%(asctime)s [%(levelname)s] %(message)s"
)


def get_repositories(dir: Path):
    repos = []
    logging.debug("get_repositories called with directory: %s", dir)
    for root, _, files in os.walk(dir):
        logging.debug(f"Scanning directory: {root}")
        for name in files:
            logging.debug(f"Scanning File: {name}")
            if "repository" in name.lower():
                logging.info(f"Repository found: {name}")
                path = os.path.join(root, name)
                repos.append(path)
    return repos


def get_procs(repo: Path):
    proc_names = []
    with open(repo, "r", encoding="utf-8") as f:
        lines = f.readlines()
        for line in lines:

            match = re.search(r'"(.*?)"', line)

            if "GetDataCallSettingsInstance" in line and match:
                logging.info(f"SQL3 Proc found: {match}")
                proc_names.append(f'SQL3.{match.group(1)}')
            elif "DataCallSettings" in line and match:
                logging.info(f"SQL3 Proc found: {match}")
                proc_names.append(f'SQL3.{match.group(1)}')
            elif "GetSql2DataCallSettingsInstance" in line and match:
                logging.info(f"SQL2 Proc found: {match}")
                proc_names.append(f'SQL2.{match.group(1)}')
            else:
                continue
    return proc_names


def main():
    dir = sys.argv[1:][0]
    root = os.getcwd()

    logging.debug("Checking directory: %s", (Path(root) / dir))

    repositories = get_repositories(Path(root) / dir)
    procs = []
    for repo in repositories:
        procs.extend(get_procs(repo))

    for proc in procs:
        print(f'+ {proc}')


if __name__ == "__main__":
    main()
