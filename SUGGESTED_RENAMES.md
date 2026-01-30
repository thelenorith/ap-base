# Suggested Project Renames

## Naming Taxonomy

### Nouns (singular, consistent)

| Noun | Definition |
|------|------------|
| **light** | A light frame (science image of a target) |
| **master** | An integrated calibration frame (bias, dark, or flat) |
| **header** | Metadata stored in the file |

### Destinations

| Destination | Directory | Purpose |
|-------------|-----------|---------|
| **blink** | `10_Blink/` | Initial QC stage, visual review |
| **data** | `20_Data/` | Accepted frames, collecting more |
| **library** | `Calibration/Library/` | Organized master frame storage |

### Qualifiers

| Qualifier | Meaning |
|-----------|---------|
| **raw** | Unprocessed, directly from capture |

### Verbs

| Verb | Action |
|------|--------|
| **create** | Generate (masters from raw frames) |
| **cull** | Filter/reject based on quality metrics |
| **calibrate** | Apply calibration frames to lights |
| **preserve** | Save metadata (e.g., path → header) |
| **move** | Transfer from one location to another |
| **delete** | Remove files/frames |
| **empty** | Clean up (e.g., remove empty directories) |

## Naming Pattern

All tools follow: `ap-{verb}-{qualifier?}-{noun}-to-{destination?}`

- Every tool name starts with a **verb**
- **Qualifier** (like `raw`) is optional
- **Noun** is always singular
- **Destination** is used when the tool moves data somewhere

## Data Flow

```mermaid
flowchart TB
    subgraph Capture["Capture (NINA)"]
        RAW_LIGHT[Raw Light]
        RAW_CAL[Raw Calibration<br/>bias / dark / flat]
    end

    subgraph Pipeline["Processing Pipeline"]
        subgraph LightPath["Light Path"]
            TO_BLINK[ap-move-raw-light-to-blink]
            CULL[ap-cull-light]
            PRESERVE[ap-preserve-header]
            CALIBRATE[ap-calibrate-light]
            TO_DATA[ap-move-light-to-data]
        end

        subgraph MasterPath["Master Path"]
            CREATE[ap-create-master]
            TO_LIB[ap-move-master-to-library]
            MASTER_BLINK[ap-move-master-to-blink]
        end
    end

    subgraph Storage["Storage"]
        BLINK[10_Blink]
        DATA[20_Data]
        LIBRARY[(Calibration<br/>Library)]
        REJECT[Reject]
    end

    RAW_LIGHT --> TO_BLINK --> BLINK
    BLINK --> CULL --> REJECT
    CULL --> PRESERVE
    PRESERVE --> MASTER_BLINK
    MASTER_BLINK --> CALIBRATE --> TO_DATA --> DATA

    RAW_CAL --> CREATE --> TO_LIB --> LIBRARY
    LIBRARY --> MASTER_BLINK
```

## Proposed Renames

### Summary Table

| Current | Proposed | Pattern | Rationale |
|---------|----------|---------|-----------|
| `ap-move-lights` | `ap-move-raw-light-to-blink` | verb-qualifier-noun-to-dest | Move raw lights from capture → blink |
| `ap-cull-lights` | `ap-cull-light` | verb-noun | Cull (reject) poor quality lights |
| `ap-fits-headers` | `ap-preserve-header` | verb-noun | Preserve path metadata into header |
| `ap-master-calibration` | `ap-create-master` | verb-noun | Create masters from raw calibration |
| `ap-move-calibration` | `ap-move-master-to-library` | verb-noun-to-dest | Move masters → library |
| `ap-common` | `ap-common` | — | Shared utilities (no change) |

### New Projects

| Name | Pattern | Purpose |
|------|---------|---------|
| `ap-move-master-to-blink` | verb-noun-to-dest | Copy matching masters from library → blink for a target |
| `ap-calibrate-light` | verb-noun | Apply masters to lights |
| `ap-move-light-to-data` | verb-noun-to-dest | Move accepted lights from blink → data (future) |

## Detailed Analysis

### ap-move-raw-light-to-blink (was: ap-move-lights)

**Pattern:** `verb-qualifier-noun-to-destination`

The tool moves raw light frames from NINA capture directory into the organized `10_Blink` structure.

```mermaid
flowchart LR
    RAW[Raw Light<br/>from capture] --> TOOL[ap-move-raw-light-to-blink]
    TOOL --> BLINK[10_Blink/<br/>target/DATE/FILTER_EXP/]
```

### ap-cull-light (was: ap-cull-lights)

**Pattern:** `verb-noun`

The tool culls (rejects) lights based on HFR and RMS thresholds.

```mermaid
flowchart LR
    LIGHT[Light in blink] --> TOOL[ap-cull-light]
    TOOL --> KEEP[Keep]
    TOOL --> REJECT[Reject]
```

### ap-preserve-header (was: ap-fits-headers)

**Pattern:** `verb-noun`

The tool preserves path-encoded metadata into the file header. The key insight: we're not modifying FITS specifically—we're preserving information that would otherwise be lost.

```mermaid
flowchart LR
    PATH["/CAMERA_ASI294/OPTIC_C8E/img.fits"] --> TOOL[ap-preserve-header]
    TOOL --> HEADER["Header: CAMERA=ASI294, OPTIC=C8E"]
```

### ap-create-master (was: ap-master-calibration)

**Pattern:** `verb-noun`

The tool creates master calibration frames by integrating raw bias/dark/flat frames via PixInsight.

```mermaid
flowchart LR
    RAW[Raw bias/dark/flat] --> TOOL[ap-create-master]
    TOOL --> MASTER[Master frame]
```

### ap-move-master-to-library (was: ap-move-calibration)

**Pattern:** `verb-noun-to-destination`

The tool moves master frames from PixInsight output into the organized calibration library.

```mermaid
flowchart LR
    MASTER[Master from<br/>PixInsight output] --> TOOL[ap-move-master-to-library]
    TOOL --> LIBRARY[(Calibration<br/>Library)]
```

### ap-move-master-to-blink (new)

**Pattern:** `verb-noun-to-destination`

Copy matching masters from the library into the blink directory for a specific target, enabling calibration.

```mermaid
flowchart LR
    LIBRARY[(Calibration<br/>Library)] --> TOOL[ap-move-master-to-blink]
    TOOL --> BLINK[10_Blink/<br/>target/calibration/]
```

**Matching logic:**
- Read light frame headers in target directory
- Find matching bias (camera, temp, gain, offset)
- Find matching dark (+ exposure)
- Find matching flat (+ filter, nearest date)
- Copy to target's calibration subdirectory

### ap-calibrate-light (new)

**Pattern:** `verb-noun`

Apply calibration masters to light frames (may wrap PixInsight WBPP or similar).

```mermaid
flowchart LR
    LIGHT[Light] --> TOOL[ap-calibrate-light]
    MASTER[Master] --> TOOL
    TOOL --> CALIBRATED[Calibrated Light]
```

### ap-move-light-to-data (future)

**Pattern:** `verb-noun-to-destination`

Move accepted lights from blink to data stage.

```mermaid
flowchart LR
    BLINK[10_Blink/accept/] --> TOOL[ap-move-light-to-data]
    TOOL --> DATA[20_Data/]
```

## Complete Workflow with New Names

```mermaid
flowchart TB
    subgraph Capture
        NINA[NINA]
    end

    subgraph Ingest
        RAW_TO_BLINK[ap-move-raw-light-to-blink]
        CULL[ap-cull-light]
        PRESERVE[ap-preserve-header]
    end

    subgraph Calibration
        CREATE[ap-create-master]
        TO_LIB[ap-move-master-to-library]
        TO_BLINK[ap-move-master-to-blink]
        APPLY[ap-calibrate-light]
    end

    subgraph Promotion
        TO_DATA[ap-move-light-to-data]
    end

    subgraph Stages
        BLINK[10_Blink]
        DATA[20_Data]
        LIBRARY[(Library)]
    end

    NINA -->|lights| RAW_TO_BLINK --> BLINK
    BLINK --> CULL --> PRESERVE --> TO_BLINK
    TO_BLINK --> APPLY --> TO_DATA --> DATA

    NINA -->|calibration| CREATE --> TO_LIB --> LIBRARY
    LIBRARY --> TO_BLINK
```

## Module/Package Names

Python packages use underscores:

| Project | Package |
|---------|---------|
| `ap-move-raw-light-to-blink` | `ap_move_raw_light_to_blink` |
| `ap-cull-light` | `ap_cull_light` |
| `ap-preserve-header` | `ap_preserve_header` |
| `ap-create-master` | `ap_create_master` |
| `ap-move-master-to-library` | `ap_move_master_to_library` |
| `ap-move-master-to-blink` | `ap_move_master_to_blink` |
| `ap-calibrate-light` | `ap_calibrate_light` |
| `ap-move-light-to-data` | `ap_move_light_to_data` |

## Migration Checklist

For each renamed project:

- [ ] Create new GitHub repository with new name
- [ ] Update `pyproject.toml` (name, package name)
- [ ] Rename package directory
- [ ] Update imports in code
- [ ] Update CLI entry points
- [ ] Update README and badges
- [ ] Update GitHub Actions workflows
- [ ] Archive old repository (or redirect)

For ap-base:

- [ ] Update `.gitmodules` with new URLs
- [ ] Update `patches/` directory
- [ ] Update `Makefile` targets
- [ ] Update `docs/` references
- [ ] Update `CLAUDE.md`

## Open Questions

1. Should `ap-move-master-to-blink` also set up a PixInsight project, or just copy files?
2. Is `ap-calibrate-light` a wrapper around WBPP, or a standalone calibration tool?
3. Do we need `ap-move-light-to-data`, or is that a manual step (drag/drop in file manager)?
