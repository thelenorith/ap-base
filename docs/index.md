# Astrophotography Pipeline Documentation

A modular Python toolkit for processing and managing astrophotography data captured with NINA (Nighttime Imaging 'N' Astronomy).

## Overview

This pipeline provides a comprehensive workflow for processing astrophotography data from raw capture through organization, quality control, calibration frame management, and archiving. The tools are designed to work together while remaining independently useful.

```mermaid
flowchart TB
    subgraph Capture
        NINA[NINA Capture]
    end

    subgraph Processing["Processing Pipeline"]
        ML[ap-move-raw-light-to-blink]
        CL[ap-cull-light]
        FH[ap-preserve-header]
        MC[ap-create-master]
        MV[ap-move-master-to-library]
    end

    subgraph Libraries
        CAL[Calibration Library]
        DATA[Data Archive]
    end

    NINA --> ML
    ML --> CL
    CL --> FH
    FH --> MC
    MC --> MV
    MV --> CAL
    FH --> DATA
```

## Tools

| Tool | Purpose |
|------|---------|
| [ap-common](tools/ap-common.md) | Shared utilities for data handling |
| [ap-move-raw-light-to-blink](tools/ap-move-raw-light-to-blink.md) | Organize light frames by metadata |
| [ap-cull-light](tools/ap-cull-light.md) | Quality control filtering |
| [ap-preserve-header](tools/ap-preserve-header.md) | Preserve path metadata in FITS headers |
| [ap-create-master](tools/ap-create-master.md) | Generate master calibration frames |
| [ap-move-master-to-library](tools/ap-move-master-to-library.md) | Organize calibration library |

## Quick Start

### Installation

All tools can be installed from git:

```bash
pip install git+https://github.com/jewzaam/ap-move-raw-light-to-blink.git
pip install git+https://github.com/jewzaam/ap-cull-light.git
pip install git+https://github.com/jewzaam/ap-preserve-header.git
pip install git+https://github.com/jewzaam/ap-create-master.git
pip install git+https://github.com/jewzaam/ap-move-master-to-library.git
```

The `ap-common` package is installed automatically as a dependency.

### Basic Workflow

```bash
# 1. Move light frames from raw capture to organized structure
python -m ap_move_lights /raw/capture /data

# 2. Cull poor quality frames
python -m ap_cull_lights /data/10_Blink /reject --max-hfr 2.5 --max-rms 2.0

# 3. Preserve path metadata in FITS headers
python -m ap_fits_headers /data --include CAMERA OPTIC FILTER

# 4. Generate master calibration frames
python -m ap_master_calibration /raw/calibration /output --pixinsight-binary "/path/to/PixInsight"

# 5. Organize calibration library
python -m ap_move_calibration /output/master /calibration_library
```

## Documentation

- [Workflow Guide](workflow.md) - Detailed workflow documentation
- [Directory Structure](directory-structure.md) - How files are organized
- [Tool Reference](tools/) - Individual tool documentation

## Requirements

- Python 3.10+
- PixInsight (for master calibration generation)
- NINA (for image capture - not part of this toolkit)

## License

Apache-2.0
