# ap-empty-directory

Remove files from a directory and clean up empty subdirectories.

## Overview

A tool for clearing out directories by removing all files and optionally cleaning up empty subdirectories. Useful in astrophotography pipelines for resetting working directories between processing runs.

Key features:
- Delete files in a directory (non-recursive by default)
- Optionally recurse into subdirectories with `--recursive`
- Automatically remove empty directories after file deletion
- Dry-run mode to preview changes

## Common Use Cases

This tool is used to clean up intermediate calibration files that are not moved or deleted by other tools:
- **Calibration output directory**: After moving masters to library with ap-move-master-to-library
- **Raw calibration frames**: After integrating into masters (only after BOTH integration AND library move)

## Installation

```bash
pip install git+https://github.com/jewzaam/ap-empty-directory.git
```

## Usage

```bash
# Remove files in top-level directory only
python -m ap_empty_directory /path/to/blink

# Remove all files recursively and clean up empty directories
python -m ap_empty_directory /path/to/blink --recursive

# Preview what would be deleted
python -m ap_empty_directory /path/to/blink --recursive --dryrun

# Exclude .keep files from deletion (preserves empty directories)
python -m ap_empty_directory /path/to/blink --recursive --exclude-regex '\.keep'
```

## Options

| Option | Short | Description |
|--------|-------|-------------|
| `--recursive` | `-r` | Recursively delete files in subdirectories |
| `--exclude-regex` | `-e` | Exclude files matching the pattern from deletion |
| `--dryrun` | `-n` | Show what would be deleted without deleting |
| `--debug` | `-d` | Enable debug output |

## Repository

[github.com/jewzaam/ap-empty-directory](https://github.com/jewzaam/ap-empty-directory)
