#!/usr/bin/env python3

import argparse
import logging
import os
import platform
import shutil
import sys
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Optional


def get_current_os() -> str:
    """Detect current operating system."""
    system = platform.system().lower()
    if system == "darwin":
        return "mac"
    elif system == "windows":
        return "win"
    else:
        return "linux"


def get_packages_config_filename(os_name: str) -> str:
    """Get the packages config filename for the OS."""
    return f".packages.{os_name}.config"


def get_deploy_config_filename(os_name: str) -> str:
    """Get the deploy config filename for the OS."""
    return f".deploy.{os_name}.config"


def expand_path(path_str: str) -> Path:
    """Expand ~, $HOME, %USERPROFILE%, and %APPDATA% in path string."""
    path_str = path_str.replace("~", str(Path.home()))
    path_str = path_str.replace("$HOME", str(Path.home()))
    path_str = path_str.replace(
        "%USERPROFILE%", os.environ.get("USERPROFILE", str(Path.home())))
    path_str = path_str.replace("%APPDATA%", os.environ.get(
        "APPDATA", str(Path.home() / "AppData" / "Roaming")))
    if (get_current_os() == "win") and "$PROFILE" in path_str:
        profile_path = subprocess.run(
            ["powershell", "-NoProfile", "-Command", "$PROFILE"],
            capture_output=True,
            text=True
        ).stdout.strip()
        path_str = path_str.replace("$PROFILE", profile_path)

    return Path(path_str)


def backup_existing(path: Path, dry_run: bool) -> None:
    """Backup existing directory if it exists (files are removed, not backed up)."""
    if not path.exists() and not path.is_symlink():
        return

    if not path.is_dir():
        logging.debug("Removing existing file: %s", path)
        if not dry_run:
            path.unlink()
        return

    if dry_run:
        logging.info("[DRY-RUN] Would backup directory: %s", path)
        return

    backup_path = path.with_name(path.name + ".backup")

    try:
        if backup_path.exists() or backup_path.is_symlink():
            if backup_path.is_dir() and not backup_path.is_symlink():
                shutil.rmtree(backup_path)
            else:
                backup_path.unlink()

        path.rename(backup_path)
        logging.info("Backed up: %s -> %s", path, backup_path)
    except OSError as e:
        logging.error("Failed to backup %s: %s", path, e)
        raise


def create_symlink(source: Path, destination: Path, dry_run: bool) -> None:
    """Create a symlink from destination to source."""
    if dry_run:
        logging.info("[DRY-RUN] Would link: %s -> %s", destination, source)
        return

    if not source.exists():
        raise FileNotFoundError(f"Source does not exist: {source}")

    destination.parent.mkdir(parents=True, exist_ok=True)

    if destination.exists() or destination.is_symlink():
        backup_existing(destination, dry_run)

    system = platform.system().lower()

    if system == "windows":
        # is_dir = source.is_dir()
        cmd = [
            "powershell",
            "-Command",
            "New-Item -ItemType SymbolicLink -Path "
            + f"\"{destination}\" -Target \"{source}\" -Force | Out-Null"
        ]

        try:
            subprocess.run(cmd, check=True, capture_output=True, text=True)
            logging.info(
                "Windows symlink created via PowerShell: %s -> %s", destination, source)
        except subprocess.CalledProcessError as e:
            error_msg = f"PowerShell New-Item failed for {destination} -> {source}: {e.stderr}"
            logging.error(error_msg)
            raise OSError(error_msg)
    else:
        os.symlink(source, destination, target_is_directory=source.is_dir())
        logging.info("Symlink created: %s -> %s", destination, source)


def construct_file(
    source_dir: Path, output_filename: str, repo_root: Path, dry_run: bool
) -> tuple[Optional[str], list[str]]:
    """Construct a file by joining all files in source_dir.

    Args:
        source_dir: Path to directory containing files to join (relative to repo root)
        output_filename: Name of the output file to create
        repo_root: Root of the dotfiles repository
        dry_run: If True, don't actually write the file

    Returns:
        Tuple of (error_message, list of source filenames used)
        error_message is None on success, error string on failure
    """
    source_path = (repo_root / source_dir).resolve()

    if not source_path.exists():
        return (f"Source directory does not exist: {source_path}", [])

    if not source_path.is_dir():
        return (f"Source is not a directory: {source_path}", [])

    files = sorted(source_path.iterdir())
    source_files = [f.name for f in files if f.is_file()]

    if not source_files:
        return (f"No files found in directory: {source_path}", [])

    output_path = repo_root / output_filename

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    header = f"# Constructed on {timestamp} from: {', '.join(source_files)}\n"

    if dry_run:
        logging.info(
            "[DRY-RUN] Would construct: %s from %d files in %s",
            output_path,
            len(source_files),
            source_path,
        )
        return (None, source_files)

    try:
        with output_path.open("w", encoding="utf-8") as out:
            out.write(header)
            out.write("\n")
            for i, filename in enumerate(source_files):
                file_path = source_path / filename
                content = file_path.read_text(encoding="utf-8")
                out.write(content)
                if i < len(source_files) - 1:
                    out.write("\n")
        logging.info("Constructed: %s from %d files",
                     output_path, len(source_files))
    except OSError as e:
        return (f"Failed to write {output_path}: {e}", source_files)

    return (None, source_files)


def process_package(package_name: str, os_name: str, repo_root: Path, dry_run: bool) -> list[tuple[str, str]]:
    """Process a single package and create its symlinks."""
    failures = []
    package_path = repo_root / package_name
    deploy_config = package_path / get_deploy_config_filename(os_name)

    if not deploy_config.exists():
        logging.warning("Deploy config not found: %s", deploy_config)
        return failures

    with deploy_config.open("r", encoding="utf-8") as f:
        all_lines = [line.strip() for line in f if line.strip()]

    constructed_outputs: dict[str, str] = {}

    for line in all_lines:
        if line.startswith("#constructed"):
            recipe = line[len("#constructed"):].strip()
            if "->" not in recipe:
                logging.warning(
                    "Invalid #constructed line (missing '->'): %s", line)
                failures.append((line, "Invalid format - missing '->'"))
                continue

            source_dir, output_filename = recipe.split("->", 1)
            source_dir = source_dir.strip()
            output_filename = output_filename.strip()

            logging.debug("Constructing %s from directory %s",
                          output_filename, source_dir)

            error, source_files = construct_file(
                Path(source_dir), output_filename, repo_root, dry_run
            )
            if error:
                failures.append((line, error))
                logging.error("Failed to construct %s: %s",
                              output_filename, error)
            else:
                constructed_outputs[output_filename] = source_dir

    symlink_lines = [line for line in all_lines if not line.startswith("#")]

    for line in symlink_lines:
        if "=" not in line:
            logging.warning("Invalid line (missing '='): %s", line)
            failures.append((line, "Invalid format - missing '='"))
            continue

        source_rel, dest_str = line.split("=", 1)
        source_rel = source_rel.strip()
        dest_str = dest_str.strip()

        if source_rel in constructed_outputs:
            logging.debug("Using constructed file for: %s", source_rel)
            source_path = (repo_root / source_rel).resolve()
        else:
            source_path = (repo_root / source_rel).resolve()

        dest_path = expand_path(dest_str)

        logging.debug("Processing: %s -> %s", source_path, dest_path)

        try:
            create_symlink(source_path, dest_path, dry_run)
        except Exception as e:
            failures.append((f"{source_rel}={dest_str}", str(e)))
            logging.error("Failed to link %s -> %s: %s",
                          source_path, dest_path, e)

    return failures


def create_dotfiles_env(repo_root: Path, current_os: str, dry_run: bool) -> None:
    """Create .dotfiles.env with the DOTFILES path."""
    env_file = repo_root / ".dotfiles.env"
    if current_os == "win":
        env_content = f'set DOTFILES="{repo_root}"\n'
    else:
        env_content = f'export DOTFILES="{repo_root}"\n'

    if dry_run:
        logging.info("[DRY-RUN] Would create: %s", env_file)
        return

    env_file.write_text(env_content, encoding="utf-8")
    logging.info("Created: %s", env_file)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Deploy dotfiles by creating symlinks from this repository to target locations"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without making changes",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable verbose logging",
    )
    parser.add_argument(
        "--skip-env",
        action="store_true",
        help="Skip creating .dotfiles.env",
    )
    args = parser.parse_args()

    log_level = logging.DEBUG if args.verbose else logging.INFO
    logging.basicConfig(
        level=log_level,
        format="%(levelname)s: %(message)s",
    )

    repo_root = Path(__file__).resolve().parent
    current_os = get_current_os()
    packages_config = repo_root / get_packages_config_filename(current_os)

    logging.info("Repository: %s", repo_root)
    logging.info("Operating system: %s", current_os)
    logging.info("Packages config: %s", packages_config)
    logging.info("Dry run: %s", args.dry_run)

    if not args.skip_env:
        create_dotfiles_env(repo_root, current_os, args.dry_run)

    if not packages_config.exists():
        logging.error("Packages config not found: %s", packages_config)
        print(
            f"Error: Packages config not found: {packages_config}",
            file=sys.stderr)
        sys.exit(1)

    with packages_config.open("r", encoding="utf-8") as f:
        packages = [line.strip() for line in f if line.strip()
                    and not line.startswith("#")]

    logging.info("Packages to deploy: %s", ", ".join(packages))

    all_failures = []

    for package in packages:
        package_path = repo_root / package
        if not package_path.exists():
            logging.warning(
                "Package directory not found: %s (skipping)", package_path)
            continue

        logging.info("Processing package: %s", package)
        failures = process_package(
            package, current_os, repo_root, args.dry_run)
        if failures:
            all_failures.extend([(package, src, err) for src, err in failures])
            logging.error("Package '%s' had %d failure(s)",
                          package, len(failures))
        else:
            logging.info("Package '%s' deployed successfully", package)

    print()
    if all_failures:
        print(f"FAILED: {len(all_failures)} link(s)")
        for pkg, src, err in all_failures:
            print(f"  {pkg}: {src} - {err}")
        if not args.dry_run:
            sys.exit(1)
    else:
        print(f"Success: {len(packages)} package(s) deployed")

    if args.dry_run:
        print("(dry run - no changes made)")


if __name__ == "__main__":
    main()
