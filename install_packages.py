from pathlib import Path
import sys
import os
import logging

level = logging.DEBUG

if level == logging.DEBUG:
    logfile = 'install_packages.debug.log'
else:
    logfile = 'install_packages.log'

logging.basicConfig(level=level,
                    format='%(asctime)s - %(levelname)s - %(message)s',
                    filename=logfile)

_original_hook = sys.excepthook


def log_uncaught(exc_type, exc, tb):
    logging.critical("Uncaught exception", exc_info=(exc_type, exc, tb))
    _original_hook(exc_type, exc, tb)


sys.excepthook = log_uncaught


def set_conf_os(path_str: str):
    if 'win' in path_str:
        return 'win'
    elif 'mac' in path_str:
        return 'mac'
    elif 'ubu' in path_str:
        return 'ubuntu'
    else:
        raise ValueError('Invalid OS in file path')


def set_link_conf(path_str: str):
    if 'win' in path_str:
        return '.mklink.config'
    elif 'mac' in path_str:
        return '.ln.config'
    elif 'ubu' in path_str:
        return '.ln.config'
    else:
        raise ValueError('Invalid OS in file path')


def backup_file_if_exists(file_path: str):
    path = Path(file_path)
    if path.exists() or path.is_symlink():
        backup_path = path.with_name(path.name + ".backup")

        if backup_path.exists() or backup_path.is_symlink():
            backup_path.unlink()

        logging.debug("Backing up %s -> %s", path, backup_path)
        path.rename(backup_path)  # moves the file/symlink


def construct_file(cfg: Path):
    sources = [
        p for p in cfg.parent.iterdir()
        if p.is_file()
        and not p.name.startswith(".")
        and p.resolve() != cfg.resolve()
    ]

    with cfg.open("w", encoding="utf-8") as f:
        for p in sources:
            f.write(f"{p}\n")


def link_package(pkg: Path, link_conf: str):
    links = open(Path(pkg) / link_conf, "r", encoding='utf-8').readlines()

    for i, link in enumerate(links):
        if link.startswith('#constructed'):
            construct_file(Path(links[i + 1].split("=")[0]))
            continue

        src = Path(__file__).resolve().parent / Path(pkg) / link.split("=")[0]
        dest = link.split("=")[1].strip("\n")
        dest = dest.replace("~", str(Path.home())).replace(
            "$HOME", str(Path.home()))

        src_path = Path(src)
        dest_path = Path(dest)

        logging.debug('Attempting to link: %s -> %s', src_path, dest_path)

        backup_file_if_exists(dest_path)
        dest_path.parent.mkdir(parents=True, exist_ok=True)

        assert not dest_path.exists()
        assert not dest_path.is_symlink()
        os.symlink(src_path, dest_path, target_is_directory=src_path.is_dir())
        logging.info('Linked: %s <- %s', src_path, dest_path)


def main():
    logging.debug("Starting install_packages.py")
    if len(sys.argv) != 2:
        print("usage: python intall_packages.py <.config file>")
        logging.critical("sys.argv count == %s expected 2", len(sys.argv))
        exit(1)

    parent_dir = Path(__file__).resolve().parent
    path_str = sys.argv[1]

    logging.debug("Found config file: %s", path_str)
    logging.debug("Found parent_dir %s", parent_dir)

    conf_os = set_conf_os(path_str)
    link_conf = set_link_conf(path_str)
    logging.debug("Set conf_os: %s", conf_os)
    logging.debug("Set link_conf: %s", link_conf)

    conf_file_path = parent_dir / path_str
    logging.debug("Opening file: %s", conf_file_path)

    with conf_file_path.open("r", encoding="utf-8") as conf_file:
        for package in conf_file.readlines():
            logging.debug("Handling package: %s", package)
            link_package(package.strip("\n"),  link_conf)


if __name__ == "__main__":
    main()
