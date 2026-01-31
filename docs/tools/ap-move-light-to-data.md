# ap-move-light-to-data

Move light frames from blink directory to data directory when calibration frames are available.

## Overview

This tool automates the workflow step between blinking/reviewing light frames and processing them. It only moves light frames to the data directory when matching calibration frames exist, ensuring you don't start processing data that can't be properly calibrated.

Calibration frames are searched for in the lights directory first, then in parent directories up to the source directory boundary. This supports flexible workflows where filter-specific flats are stored with lights while shared darks are in parent directories.

## Installation

```bash
pip install git+https://github.com/jewzaam/ap-move-lights-to-data.git
```

## Usage

```bash
python -m ap_move_lights_to_data <source_dir> <dest_dir> [options]
```

### Arguments

- `source_dir`: Source directory containing light frames (typically `10_Blink`)
- `dest_dir`: Destination directory for lights with calibration (typically `20_Data`)

### Options

- `-d, --debug`: Enable debug output
- `-n, --dry-run`: Show what would be done without actually moving files

### Examples

```bash
# Move lights from 10_Blink to 20_Data
python -m ap_move_lights_to_data \
    "/data/astrophotography/RedCat51@f4.9+ASI2600MM/10_Blink" \
    "/data/astrophotography/RedCat51@f4.9+ASI2600MM/20_Data"

# Dry run to see what would be moved
python -m ap_move_lights_to_data \
    "/data/astrophotography/RedCat51@f4.9+ASI2600MM/10_Blink" \
    "/data/astrophotography/RedCat51@f4.9+ASI2600MM/20_Data" \
    --dry-run
```

## Calibration Requirements

Lights are only moved when calibration frames are found (in the lights directory or parent directories) matching these criteria:

### Dark Matching
- Camera
- Set temperature
- Gain
- Offset
- Readout mode

### Flat Matching
- Camera
- Set temperature
- Gain
- Offset
- Readout mode
- Filter

### Bias Requirement

Bias frames are **only required** when the dark exposure time does not match the light exposure time. This is because darks with mismatched exposure times need bias subtraction for proper scaling.

- If dark exposure matches light exposure: **No bias required**
- If dark exposure differs from light exposure: **Bias required**

## Frame Type Support

The tool recognizes both regular and MASTER frame types:
- `dark`, `DARK`, `master dark`, `MASTER DARK`
- `flat`, `FLAT`, `master flat`, `MASTER FLAT`
- `bias`, `BIAS`, `master bias`, `MASTER BIAS`

## Repository

[github.com/jewzaam/ap-move-lights-to-data](https://github.com/jewzaam/ap-move-lights-to-data)
