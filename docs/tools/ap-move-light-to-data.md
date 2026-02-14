# ap-move-light-to-data

Move light frames from blink directory to data directory when calibration frames are available.

## Overview

This tool automates the workflow step between blinking/reviewing light frames and processing them. It only moves light frames to the data directory when matching calibration frames exist, ensuring you don't start processing data that can't be properly calibrated.

Calibration frames are searched for in the lights directory first, then in parent directories up to the source directory boundary. This supports flexible workflows where filter-specific flats are stored with lights while shared darks are in parent directories.

## Installation

```bash
python -m pip install git+https://github.com/jewzaam/ap-move-light-to-data.git
```

## Usage

```bash
python -m ap_move_light_to_data <source_dir> <dest_dir> [options]
```

### Arguments

- `source_dir`: Source directory containing light frames (typically `10_Blink`)
- `dest_dir`: Destination directory for lights with calibration (typically `20_Data`)

### Options

| Option | Description |
|--------|-------------|
| `-d`, `--debug` | Enable debug output |
| `-n`, `--dryrun` | Show what would be done without moving files |
| `-q`, `--quiet` | Suppress progress output |
| `--scale-dark` | Scale dark frames using bias compensation (allows shorter exposures). Default: exact exposure match only |
| `--path-pattern REGEX` | Filter light directories by regex pattern (e.g., `"M31"`, `"FILTER_Ha"`) |

### Examples

```bash
# Move lights from 10_Blink to 20_Data
python -m ap_move_light_to_data \
    "/data/astrophotography/RedCat51@f4.9+ASI2600MM/10_Blink" \
    "/data/astrophotography/RedCat51@f4.9+ASI2600MM/20_Data"

# Dry run to see what would be moved
python -m ap_move_light_to_data \
    "/data/astrophotography/RedCat51@f4.9+ASI2600MM/10_Blink" \
    "/data/astrophotography/RedCat51@f4.9+ASI2600MM/20_Data" \
    --dryrun

# Quiet mode (minimal output)
python -m ap_move_light_to_data \
    "/data/astrophotography/RedCat51@f4.9+ASI2600MM/10_Blink" \
    "/data/astrophotography/RedCat51@f4.9+ASI2600MM/20_Data" \
    --quiet

# Process only specific target (M31)
python -m ap_move_light_to_data \
    "/data/astrophotography/RedCat51@f4.9+ASI2600MM/10_Blink" \
    "/data/astrophotography/RedCat51@f4.9+ASI2600MM/20_Data" \
    --path-pattern "M31"

# Process only Ha filter
python -m ap_move_light_to_data \
    "/data/astrophotography/RedCat51@f4.9+ASI2600MM/10_Blink" \
    "/data/astrophotography/RedCat51@f4.9+ASI2600MM/20_Data" \
    --path-pattern "FILTER_Ha"
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

Bias frames are **only required** when the dark exposure time does not match the light exposure time and `--scale-dark` is specified. This is because darks with mismatched exposure times need bias subtraction for proper scaling.

- **Default behavior**: Without `--scale-dark`, only exact exposure match darks are used
- **With `--scale-dark`**:
  - If dark exposure matches light exposure: **No bias required**
  - If dark exposure differs from light exposure: **Bias required**

## Path Pattern Filtering

Use `--path-pattern` to process only specific targets or filters:

```bash
# Process only M31 target
python -m ap_move_light_to_data 10_Blink 20_Data --path-pattern "M31"

# Process only Ha filter
python -m ap_move_light_to_data 10_Blink 20_Data --path-pattern "FILTER_Ha"

# Process multiple patterns (regex OR)
python -m ap_move_light_to_data 10_Blink 20_Data --path-pattern "M31|M42"
```

The pattern is matched against the full directory path, allowing flexible filtering by target name, filter, date, or any other path component.

## Frame Type Support

The tool recognizes both regular and MASTER frame types:
- `dark`, `DARK`, `master dark`, `MASTER DARK`
- `flat`, `FLAT`, `master flat`, `MASTER FLAT`
- `bias`, `BIAS`, `master bias`, `MASTER BIAS`

## Repository

[github.com/jewzaam/ap-move-light-to-data](https://github.com/jewzaam/ap-move-light-to-data)
