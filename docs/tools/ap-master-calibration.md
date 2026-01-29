# ap-master-calibration

Automated generation of master calibration frames using PixInsight.

## Overview

`ap-master-calibration` discovers calibration frames, groups them by metadata, and generates master bias, dark, and flat frames using PixInsight's ImageIntegration.

## Installation

```bash
pip install git+https://github.com/jewzaam/ap-master-calibration.git
```

## Requirements

- Python 3.9+
- PixInsight installed
- Calibration frames with proper FITS keywords

## Usage

```bash
python -m ap_master_calibration <input_dir> <output_dir> [options]
```

### Options

| Option | Description |
|--------|-------------|
| `input_dir` | Directory containing calibration frames |
| `output_dir` | Output directory for masters |
| `--bias-master-dir DIR` | Bias library for flat calibration |
| `--dark-master-dir DIR` | Dark library for flat calibration |
| `--pixinsight-binary PATH` | Path to PixInsight executable |
| `--script-only` | Generate scripts without executing |
| `--instance-id ID` | PixInsight instance ID (default: 123) |
| `--no-force-exit` | Keep PixInsight open after execution |

## Frame Grouping

Frames are automatically grouped by FITS keywords:

```mermaid
flowchart TB
    subgraph Bias
        B_IN[Bias Frames] --> B_GROUP[Group by:<br>Camera, Temp, Gain,<br>Offset, Readout]
        B_GROUP --> B_OUT[Master Bias]
    end

    subgraph Dark
        D_IN[Dark Frames] --> D_GROUP[Group by:<br>Above + Exposure]
        D_GROUP --> D_OUT[Master Dark]
    end

    subgraph Flat
        F_IN[Flat Frames] --> F_GROUP[Group by:<br>Above + Date, Filter]
        F_GROUP --> F_CAL[Calibrate with<br>Bias/Dark]
        F_CAL --> F_OUT[Master Flat]
    end
```

### Required FITS Keywords

| Keyword | Frame Types | Description |
|---------|-------------|-------------|
| `IMAGETYP` | All | Frame type (bias, dark, flat) |
| `INSTRUME` | All | Camera model |
| `SET-TEMP` | All | Sensor temperature |
| `GAIN` | All | Gain setting |
| `OFFSET` | All | Offset setting |
| `READOUTM` | All | Readout mode |
| `EXPOSURE` | Dark, Flat | Exposure time |
| `DATE-OBS` | Flat | Observation date |
| `FILTER` | Flat | Filter name |

## Output Structure

```
output_dir/
├── master/
│   ├── masterBias_INSTRUME_ASI294MC_SET-TEMP_-10_GAIN_100_OFFSET_10.xisf
│   ├── masterDark_..._EXPOSURE_300.xisf
│   └── masterFlat_..._DATE-OBS_2026-01-29_FILTER_L.xisf
└── logs/
    ├── 20260129_123456_calibrate_masters.js
    └── 20260129_123456.log
```

## Staged Workflow

Masters created in a run are **not used** for flat calibration in that same run. For flats, use existing libraries or run in stages:

```bash
# Stage 1: Generate bias and dark masters
python -m ap_master_calibration ./bias_and_darks ./masters \
    --pixinsight-binary "/path/to/PixInsight"

# Stage 2: Generate flat masters using Stage 1 outputs
python -m ap_master_calibration ./flats ./output \
    --bias-master-dir ./masters/master \
    --dark-master-dir ./masters/master \
    --pixinsight-binary "/path/to/PixInsight"
```

## Master Matching

When matching library masters to flats:

- Match by: Camera, Temperature, Gain, Offset, Readout Mode
- Ignore: Date, Filter (these vary per flat group)
- Dark exposure: Prefer lower/equal, use higher if necessary

## Examples

### Basic Usage

```bash
python -m ap_master_calibration /calibration /output \
    --pixinsight-binary "C:\Program Files\PixInsight\bin\PixInsight.exe"
```

### With Existing Library

```bash
python -m ap_master_calibration /flats /output \
    --bias-master-dir /library/BIAS \
    --dark-master-dir /library/DARK \
    --pixinsight-binary "/opt/PixInsight/bin/PixInsight"
```

### Script Only (No Execution)

```bash
python -m ap_master_calibration /calibration /output --script-only
```

## Troubleshooting

**No frames found:**
- Check `IMAGETYP` is set correctly (bias, dark, flat)
- Verify file extensions (.fit, .fits, .xisf)

**No matching master for flat:**
- Masters must match: INSTRUME, SET-TEMP, GAIN, OFFSET, READOUTM
- Date and filter differences are expected

**PixInsight fails:**
- Check generated script in `logs/`
- Review execution log

## Repository

[github.com/jewzaam/ap-master-calibration](https://github.com/jewzaam/ap-master-calibration)
