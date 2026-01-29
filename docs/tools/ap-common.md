# ap-common

Shared utilities package for astrophotography tools.

## Overview

`ap-common` provides common functionality used by all other ap-* tools:

- **FITS/XISF Header Reading**: Extract and parse headers from image files
- **Header Normalization**: Standardize header names and values across formats
- **Metadata Extraction**: Load and enrich metadata from files and paths
- **File Operations**: Move, copy, and manage files
- **Utility Functions**: Environment variable replacement, string conversion

## Installation

```bash
pip install git+https://github.com/jewzaam/ap-common.git
```

## Modules

### fits.py - Header Reading

```python
from ap_common.fits import get_fits_headers, get_xisf_headers, get_file_headers

# Read FITS headers
headers = get_fits_headers("image.fits", profileFromPath=True)

# Read XISF headers
headers = get_xisf_headers("image.xisf")

# Parse key-value pairs from filename/path
headers = get_file_headers("/CAMERA_ASI294/image.fits")
```

### normalization.py - Header Normalization

```python
from ap_common.normalization import normalize_headers, normalize_date, normalize_filterName

# Normalize a headers dictionary
normalized = normalize_headers(headers)

# Normalize specific values
date = normalize_date("2026-01-29T12:30:00")  # "2026-01-29"
filter_name = normalize_filterName("Luminance")  # "L"
```

### filesystem.py - File Operations

```python
from ap_common.filesystem import move_file, copy_file, delete_empty_directories

# Move file with directory creation
move_file("/source/image.fits", "/dest/organized/image.fits")

# Copy file
copy_file("/source/master.xisf", "/library/master.xisf")

# Clean up empty directories
delete_empty_directories("/source")
```

### metadata.py - Metadata Extraction

```python
from ap_common.metadata import get_filtered_metadata, enrich_metadata

# Get filtered metadata from directories
metadata = get_filtered_metadata(
    dirs=["/path/to/images"],
    filters={"type": "LIGHT", "camera": "ASI294MC"},
    profileFromPath=True
)
```

### utils.py - Utility Functions

```python
from ap_common.utils import replace_env_vars, camelCase, get_filenames

# Replace environment variables in paths
path = replace_env_vars("$AP_DATA_ROOT/images")

# Convert to camelCase
name = camelCase("FILTER_NAME")  # "filterName"

# Find files matching patterns
files = get_filenames("/data", patterns=["*.fits", "*.xisf"])
```

## Normalization Data

The package includes normalization mappings for:

- **Filter names**: Maps various filter representations to standard names (L, R, G, B, Ha, OIII, SII, etc.)
- **Header keys**: Standardizes different header key variations
- **Constants**: Common constant value mappings

```python
from ap_common.normalization import FILTER_NORMALIZATION_DATA, CONSTANT_NORMALIZATION_DATA
```

## Repository

[github.com/jewzaam/ap-common](https://github.com/jewzaam/ap-common)
