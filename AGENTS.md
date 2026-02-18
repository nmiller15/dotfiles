# AGENTS.md

This file contains build commands, code style guidelines, and project conventions for agentic coding agents working in this dotfiles repository.

## Build/Test/Lint Commands

This repository has minimal formal build tooling. Testing is done via manual execution.

### Python
```bash
# Run individual Python scripts
python3 bin/python/cpx.py --help
python3 deploy.py --help

# Deploy dotfiles (detects OS automatically)
python3 deploy.py --dry-run
python3 deploy.py

# Basic syntax checking
python3 -m py_compile <script_name>.py

# Type checking (if mypy is available)
mypy bin/python/*.py

# Linting (if ruff/flake8 is available)
ruff check bin/python/ --fix
```

### Shell Scripts
```bash
# Syntax check shell scripts
bash -n <script>.sh
zsh -n <script>.zsh

# Source configuration files safely
source zsh/path.sh
source zsh/aliases.sh
```

### Configuration Files
```bash
# Lua formatting (if stylua is available)
stylua --config-path=~/.config/stylua/stylua.toml nvim/

# Test symlinks with install script
python3 install_packages.py <config_file>
```

## Code Style Guidelines

### Python
- **Shebang**: Always use `#!/usr/bin/env python3` at the top of executable scripts
- **Style**: Follow PEP 8 conventions with 79-character line limit where practical
- **Type Hints**: Use type hints for function signatures and variables (`path: str`, `-> bool`)
- **Data Structures**: Prefer `dataclasses` for structured data, `Enum` for constants
- **Error Handling**: Use proper exit codes from `bin/python/sysexits.py`
- **CLI Tools**: Use `argparse` for command-line interfaces
- **Imports**: Group imports in order: stdlib, third-party, local imports
- **Path Handling**: Use `pathlib.Path` instead of string manipulation for file paths

Example:
```python
#!/usr/bin/env python3

import argparse
import sys
from pathlib import Path
from dataclasses import dataclass
from typing import Optional

@dataclass(frozen=True)
class Config:
    source: Path
    destination: Path

def main() -> None:
    parser = argparse.ArgumentParser(description="Example tool")
    parser.add_argument("input", type=Path, help="Input path")
    args = parser.parse_args()
    
    config = Config(source=args.input, destination=Path.home())
    # Implementation here
    sys.exit(0)

if __name__ == "__main__":
    main()
```

### Shell Scripts (Bash/Zsh)
- **Shebang**: Use `#!/bin/bash` for bash scripts, no shebang for sourced files
- **Quoting**: Always quote variables: `"$VAR"` not `$VAR`
- **Error Handling**: Use `set -euo pipefail` at the top of executable scripts
- **Functions**: Define functions with `function_name()` syntax, include local variables
- **Modern Practices**: Use `[[ ]]` for tests, `$(command)` for command substitution
- **Portability**: Avoid bash-specific features in files that might be sourced by other shells

Example:
```bash
#!/bin/bash

set -euo pipefail

install_if_missing() {
    local cmd="$1"
    local install_cmd="$2"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Installing $cmd..."
        eval "$install_cmd"
    else
        echo "$cmd is already installed."
    fi
}
```

## Project Structure and Conventions

### Directory Layout
```
/
├── bin/python/           # Python CLI utilities
├── bin/bash/            # Bash scripts and tools
├── zsh/                 # Zsh configuration and functions
├── tmux/                # Tmux configuration files
├── nvim.backup/         # Neovim configuration backup
├── yabai-skhd/          # Window manager configuration
├── eza/                 # Eza (ls replacement) config
├── install_packages.py  # Main symlink management script
└── test.py             # Simple test script
```

### Configuration Management
- **Symlink Files**: `.ln.config` for Unix symlinks, `.mklink.config` for Windows
- **Format**: `source_path=destination_path` with `$HOME` or `~` expansion
- **Constructed Files**: Lines starting with `#constructed` generate config files dynamically

Example `.ln.config`:
```
.zshrc=$HOME/.zshrc
.zprofile=$HOME/.zprofile
```

### Python Utilities Pattern
- All CLI tools follow similar structure: argument parsing, validation, processing, output
- Use meaningful exit codes from the sysexits constants
- Functions are small and focused
- Error messages go to `stderr`, normal output to `stdout`

### Shell Script Patterns
- Modular design with separate files for different concerns (aliases, functions, paths)
- Sourced files should not have executable permissions or shebangs
- Executable scripts should have proper error handling and be self-contained

## Important Patterns and Best Practices

### Python CLI Tools
- Use `sys.exit(code)` instead of `return` from main()
- Provide helpful usage messages via `argparse`
- Handle file operations with `pathlib.Path` for cross-platform compatibility
- Log appropriately using the `logging` module for complex tools
- Use f-strings for string formatting

### Shell Configuration
- Separate concerns: aliases in `aliases.sh`, functions in `functions.sh`, etc.
- Use conditional loading: `if command -v fzf >/dev/null 2>&1; then`
- Export environment variables properly: `export VAR=value`
- Use local variables in functions to avoid namespace pollution

### Cross-Platform Considerations
- The `install_packages.py` script detects OS from config file names
- Use appropriate link commands: `ln -s` on Unix, `mklink` on Windows
- Handle paths with `Path.expanduser()` for home directory expansion
- Test symlink creation before assuming it works

### Configuration File Conventions
- Tool-specific conventions should be followed (e.g., stylua for Lua files)
- Comments in config files should explain non-obvious settings
- Backup existing configurations before creating symlinks
- Use relative paths where possible for portability

## Testing Approach

- Manual testing by running scripts directly
- For Python tools: test with `--help` flag and various argument combinations
- For shell scripts: test with `bash -n` for syntax checking
- Configuration testing: use `install_packages.py` with test configs
- Simple functionality test exists in `test.py`

## Development Workflow

1. Create new utility in appropriate `bin/` subdirectory
2. Follow the established patterns for that language
3. Test manually with various inputs
4. Add to relevant configuration if it's a tool that needs to be available system-wide
5. Update any symlink configurations if the tool has config files
6. Document usage in the script's help text