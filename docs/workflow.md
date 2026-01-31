# Astrophotography Workflow Guide

This document describes the complete workflow for processing astrophotography data using the ap-* tools.

## Workflow Overview

```mermaid
flowchart TB
    subgraph Stage1["Stage 1: Capture"]
        NINA[NINA Capture] --> RAW_Light[Raw Lights]
        NINA --> RAW_Calibration[Raw Bias/Dark/Flat]
    end

    subgraph Stage2["Stage 2: Ingest & Quality Control"]
        RAW_Light --> MOVE[ap-move-raw-light-to-blink]
        MOVE --> BLINK[10_Blink Directory]
        BLINK --> CULL[ap-cull-light]
        CULL --> REJECT[Reject Directory]
        CULL --> QUALITY[Quality Frames]
    end

    subgraph Stage3["Stage 3: Metadata & Review"]
        QUALITY --> HEADERS[ap-preserve-header]
        HEADERS --> MANUAL[Manual Blink Review]
        MANUAL --> ACCEPT[Accept Directory]
    end

    subgraph Stage4["Stage 4: Calibration"]
        RAW_Calibration --> MASTER[ap-create-master]
        MASTER --> MASTERS[Master Frames]
        MASTERS --> ORGANIZE[ap-move-master-to-library]
        ORGANIZE --> LIBRARY[Calibration Library]
    end

    subgraph Stage5["Stage 5: Archive"]
        ACCEPT --> DATA[20_Data Directory]
        DATA --> PROCESS[Processing Stages]
        PROCESS --> ARCHIVE[60_Done Archive]
    end

    LIBRARY -.->|"Used for"| ACCEPT
```

## Stage Details

### Stage 1: Image Capture

Images are captured using NINA (Nighttime Imaging 'N' Astronomy) and saved to a raw directory. NINA writes FITS headers with metadata about the capture settings.

**Output**: Raw FITS/XISF files in capture directory

### Stage 2: Ingest and Quality Control

#### 2a. Move Light Frames

```bash
python -m ap_move_lights <raw_dir> <dest_dir> [options]
```

The `ap-move-raw-light-to-blink` tool:
1. Scans raw directory for FITS/XISF files
2. Reads headers to extract metadata (camera, optic, target, date, filter)
3. Moves LIGHT frames to organized directory structure
4. Creates `accept` subdirectories for reviewed frames

```mermaid
flowchart LR
    RAW[Raw Files] --> READ[Read Headers]
    READ --> EXTRACT[Extract Metadata]
    EXTRACT --> ORGANIZE[Organize by Metadata]
    ORGANIZE --> BLINK[10_Blink/target/DATE_YYYY-MM-DD/]
```

**Directory Structure Created**:
```
{dest_dir}/
└── {optic}@f{focal_ratio}+{camera}/
    └── 10_Blink/
        └── {target}/
            └── DATE_{YYYY-MM-DD}/
                └── FILTER_{filter}_EXP_{exposure}/
                    ├── image_001.fits
                    └── accept/   # For manually reviewed frames
```

#### 2b. Cull Poor Quality Frames

```bash
python -m ap_cull_lights <source_dir> <reject_dir> --max-hfr 2.5 --max-rms 2.0 [options]
```

The `ap-cull-light` tool:
1. Scans for LIGHT frames
2. Reads HFR (Half Flux Radius) and RMS (guiding error) from headers
3. Groups files by directory for batch processing
4. Moves rejected frames to reject directory

```mermaid
flowchart TB
    FILES[Light Frames] --> READ[Read HFR/RMS]
    READ --> CHECK{Exceeds Threshold?}
    CHECK -->|Yes| REJECT[Move to Reject]
    CHECK -->|No| KEEP[Keep in Place]
    CHECK -->|Auto-accept %| AUTO[Auto-accept Batch]
```

**Threshold Logic**:
- Reject if HFR > max_hfr
- Reject if RMS > max_rms
- Auto-accept batch if rejection % below threshold

### Stage 3: Metadata Preservation and Manual Review

#### 3a. Preserve Path Metadata in Headers

```bash
python -m ap_fits_headers <root_dir> --include CAMERA OPTIC FILTER [options]
```

Some metadata is encoded in directory paths rather than FITS headers. This tool:
1. Scans for key-value pairs in directory names (e.g., `CAMERA_ASI294MC`)
2. Inserts specified keys into FITS headers
3. Only updates if value differs (idempotent)

```mermaid
flowchart LR
    PATH["/CAMERA_ASI294/OPTIC_C8E/image.fits"] --> PARSE[Parse Path]
    PARSE --> EXTRACT["CAMERA=ASI294, OPTIC=C8E"]
    EXTRACT --> CHECK{In Include List?}
    CHECK -->|Yes| WRITE[Write to FITS Header]
    CHECK -->|No| SKIP[Skip]
```

#### 3b. Manual Blink Review

Using PixInsight's Blink tool, visually inspect frames to identify:

- Cloud interference
- Focusing issues
- Other artifacts

Move approved frames to the `accept/` subdirectory.

### Stage 4: Calibration Frame Management

#### 4a. Generate Master Calibration Frames

```bash
python -m ap_master_calibration <input_dir> <output_dir> --pixinsight-binary "/path/to/PixInsight" [options]
```

The `ap-create-master` tool:
1. Discovers and groups calibration frames by FITS keywords
2. Generates master bias, dark, and flat frames using PixInsight
3. Calibrates flats with bias/dark masters

```mermaid
flowchart TB
    subgraph Input
        BIAS[Bias Frames]
        DARK[Dark Frames]
        FLAT[Flat Frames]
    end

    subgraph Grouping
        BIAS --> GROUP_B(Group by Camera/Temp/Gain/Offset)
        DARK --> GROUP_D(Group by Camera/Temp/Gain/Offset/Exposure)
        FLAT --> GROUP_F(Group by Camera/Temp/Gain/Offset/Date/Filter)
    end

    subgraph Integration
        GROUP_B --> MASTER_B["`**Master Bias**`"]
        GROUP_D --> MASTER_D["`**Master Dark**`"]
        MASTER_B --> CAL_F(Calibrate Flats)
        MASTER_D --> CAL_F
        GROUP_F --> CAL_F
        CAL_F --> MASTER_F["`**Master Flat**`"]
    end
```

**Grouping Keys**:

| Frame Type | Grouping Keys |
|------------|---------------|
| Bias | Camera, Temperature, Gain, Offset, Readout Mode |
| Dark | Above + Exposure Time |
| Flat | Above + Date, Filter |

#### 4b. Organize Calibration Library

```bash
python -m ap_move_calibration <source_dir> <library_dir> [options]
```

The `ap-move-master-to-library` tool organizes master frames into a library structure:

```
{library_dir}/
├── MASTER BIAS/
│   └── {camera}/
│       └── masterBias_GAIN_100_OFFSET_10_SETTEMP_-10_READOUTM_HighSpeed.xisf
├── MASTER DARK/
│   └── {camera}/
│       └── masterDark_EXPOSURE_300_GAIN_100_OFFSET_10_SETTEMP_-10_READOUTM_HighSpeed.xisf
└── MASTER FLAT/
    └── {camera}/
        └── {optic}/
            └── DATE_2026-01-29/
                └── masterFlat_FILTER_L_GAIN_100_OFFSET_10_SETTEMP_-10_FOCALLEN_2032_READOUTM_HighSpeed.xisf
```

### Stage 5: Processing and Archive

Light frames progress through workflow stages:

```mermaid
flowchart LR
    BLINK[10_Blink] --> DATA[20_Data]
    DATA --> MASTER[30_Master]
    MASTER --> PROCESS[40_Process]
    PROCESS --> BAKE[50_Bake]
    BAKE --> DONE[60_Done]
```

| Stage | Purpose |
|-------|---------|
| 10_Blink | Initial review (quality check) |
| 20_Data | Collecting more data, calibration needs |
| 30_Master | Creating master lights |
| 40_Process | Active processing in PixInsight |
| 50_Bake | Review before publishing |
| 60_Done | Published, ready for archive |

## Complete Workflow Script Example

```bash
#!/bin/bash
# Example nightly processing workflow

RAW_DIR="/capture/tonight"
DATA_DIR="/data/astrophotography"
REJECT_DIR="/data/reject"
CAL_INPUT="/calibration/raw"
CAL_OUTPUT="/calibration/output"
CAL_LIBRARY="/calibration/library"
PIXINSIGHT="/opt/PixInsight/bin/PixInsight"

# Step 1: Move light frames
python -m ap_move_lights "$RAW_DIR" "$DATA_DIR"

# Step 2: Cull poor quality frames
python -m ap_cull_lights "$DATA_DIR/*/10_Blink" "$REJECT_DIR" \
    --max-hfr 2.5 --max-rms 2.0 --auto-accept-percent 5.0

# Step 3: Preserve path metadata
python -m ap_fits_headers "$DATA_DIR" --include CAMERA OPTIC FILTER

# Step 4: Generate master calibration frames
python -m ap_master_calibration "$CAL_INPUT" "$CAL_OUTPUT" \
    --pixinsight-binary "$PIXINSIGHT"

# Step 5: Organize calibration library
python -m ap_move_calibration "$CAL_OUTPUT/master" "$CAL_LIBRARY"

echo "Processing complete!"
```

## Tips and Best Practices

1. **Always use `--dryrun` first** - Preview changes before executing
2. **Group files before culling** - Organize by target/session for proper batch processing
3. **Preserve headers early** - Run `ap-preserve-header` before generating masters
4. **Stage calibration generation** - Generate bias/darks first, then flats
5. **Use consistent naming** - Let the tools handle organization based on metadata
