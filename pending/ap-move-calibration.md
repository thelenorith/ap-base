# Pending Changes: ap-move-calibration

## 1. Add README.md

**Priority**: High
**Status**: Pending

### Summary
README.md is completely missing. This is the only repo without a README.

### Changes Required
Create README.md following the standard structure:

```markdown
# ap-move-calibration

[![Test](https://github.com/jewzaam/ap-move-calibration/workflows/Test/badge.svg)](https://github.com/jewzaam/ap-move-calibration/actions/workflows/test.yml)
[![Coverage](https://github.com/jewzaam/ap-move-calibration/workflows/Coverage%20Check/badge.svg)](https://github.com/jewzaam/ap-move-calibration/actions/workflows/coverage.yml)
[![Lint](https://github.com/jewzaam/ap-move-calibration/workflows/Lint/badge.svg)](https://github.com/jewzaam/ap-move-calibration/actions/workflows/lint.yml)
[![Format](https://github.com/jewzaam/ap-move-calibration/workflows/Format%20Check/badge.svg)](https://github.com/jewzaam/ap-move-calibration/actions/workflows/format.yml)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)

Copy and organize master calibration frames from source to organized library based on FITS/XISF header metadata.

## Overview

[Describe what the tool does, workflow, etc.]

## Installation

### From Source (Development)

\`\`\`powershell
make install-dev
\`\`\`

### From Git Repository

\`\`\`powershell
pip install git+https://github.com/jewzaam/ap-move-calibration.git
\`\`\`

## Usage

[Document CLI usage, options, examples]

## Uninstallation

\`\`\`powershell
make uninstall
\`\`\`
```

### Rationale
- README is essential for project documentation
- Users need to understand what the tool does and how to use it

---

## 2. Add MANIFEST.in

**Priority**: Medium
**Status**: Pending

### Summary
MANIFEST.in is missing. Needed for proper sdist packaging.

### Changes Required
Create MANIFEST.in:

```
include LICENSE
include README.md
recursive-include ap_move_calibration *.py
recursive-include tests *.py
```

### Rationale
- Required for proper source distribution packaging
- Consistency with other ap-* projects

---

## Notes
- Has LICENSE file (good)
- Has GUIDANCE.md - unique to this repo, likely intentional domain-specific documentation
- Has proper Makefile structure (good)
- Workflows are present (good)
