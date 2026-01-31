# ap-move-raw-light-to-blink

Move and organize light frames from raw capture to organized directory structure.

## Overview

`ap-move-raw-light-to-blink` reads FITS headers to extract metadata and organizes light frames into a multi-stage workflow directory structure.

## Installation

```bash
pip install git+https://github.com/jewzaam/ap-move-raw-light-to-blink.git
```

## Usage

```bash
python -m ap_move_lights <source_dir> <dest_dir> [options]
```

### Options

| Option | Description |
|--------|-------------|
| `source_dir` | Source directory containing raw files |
| `dest_dir` | Destination directory for organized files |
| `--debug` | Enable debug output |
| `--dryrun` | Preview changes without moving files |
| `--blink-dir DIR` | Stage directory name (default: "10_Blink") |
| `--accept-dir DIR` | Accept subdirectory name (default: "accept") |
| `--no-accept` | Do not create accept subdirectories |

## Output Structure

```
{dest_dir}/
└── {optic}@f{focal_ratio}+{camera}/
    └── 10_Blink/
        └── {target}/
            └── DATE_{YYYY-MM-DD}/
                └── FILTER_{filter}_EXP_{exposure}/
                    ├── image_001.fits
                    └── accept/
```

## Workflow Stages

The tool creates the initial stage (10_Blink). Subsequent stages are managed manually:

| Stage | Purpose |
|-------|---------|
| 10_Blink | Initial quality review |
| 20_Data | Collecting more data |
| 30_Master | Creating master lights |
| 40_Process | Active PixInsight processing |
| 50_Bake | Review before publishing |
| 60_Done | Published and archived |

## Example

```bash
# Preview what would be moved
python -m ap_move_lights /capture/2026-01-29 /data/astrophotography --dryrun

# Move files
python -m ap_move_lights /capture/2026-01-29 /data/astrophotography

# Custom stage directory
python -m ap_move_lights /capture /data --blink-dir "00_Review"
```

## Repository

[github.com/jewzaam/ap-move-raw-light-to-blink](https://github.com/jewzaam/ap-move-raw-light-to-blink)
