# ap-copy-master-to-blink

Copy master calibration frames from library to blink directories for light frame processing.

## Overview

**Status**: Placeholder - This tool has not been implemented yet.

This tool will automate copying master calibration frames (bias, dark, flat) from the calibration library to blink directories where light frames are located. This is a required step before moving lights to the data directory.

The calibration library serves as permanent storage for master frames. This tool copies (not moves) masters to working directories to make them available for the processing pipeline.

## Planned Functionality

The tool will:
1. Scan blink directories for light frames
2. Identify required master frames based on light frame metadata
3. Search calibration library for matching masters
4. Copy matching masters to appropriate blink directories

## Matching Criteria

### Dark Matching
- Camera
- Set temperature
- Gain
- Offset
- Readout mode
- Exposure time (prefer equal, use lower/higher if necessary)

### Flat Matching
- Camera
- Set temperature
- Gain
- Offset
- Readout mode
- Filter
- Date

### Bias Matching
- Camera
- Set temperature
- Gain
- Offset
- Readout mode

## Planned Usage

```bash
# Copy masters from library to blink directories
python -m ap_copy_masters_to_blink <library_dir> <blink_dir> [options]

# Dry run to see what would be copied
python -m ap_copy_masters_to_blink <library_dir> <blink_dir> --dry-run
```

## Workflow Position

This tool fits between:
1. `ap-move-master-to-library` - Organizes masters into library
2. **ap-copy-master-to-blink** - Copies masters to blink (this tool)
3. `ap-move-light-to-data` - Moves lights when calibration available

## Implementation Notes

From legacy workflow (PROCESS-WORKFLOW.md step 2d):
- Current implementation uses `copycalibration.py` script
- Needs refactoring to separate four distinct operations
- Should handle missing flats gracefully (previous night, skip with report, future night)
- All missing flat scenarios are currently handled manually

## Repository

Not yet implemented. Placeholder for future development.
