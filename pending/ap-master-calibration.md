# Pending Changes: ap-master-calibration

## 1. Add README badges

**Priority**: Low
**Status**: Pending

### Summary
README.md is missing status badges that ap-common has.

### Changes Required
Add badges after the title:

```markdown
# ap-master-calibration

[![Test](https://github.com/jewzaam/ap-master-calibration/workflows/Test/badge.svg)](https://github.com/jewzaam/ap-master-calibration/actions/workflows/test.yml)
[![Coverage](https://github.com/jewzaam/ap-master-calibration/workflows/Coverage%20Check/badge.svg)](https://github.com/jewzaam/ap-master-calibration/actions/workflows/coverage.yml)
[![Lint](https://github.com/jewzaam/ap-master-calibration/workflows/Lint/badge.svg)](https://github.com/jewzaam/ap-master-calibration/actions/workflows/lint.yml)
[![Format](https://github.com/jewzaam/ap-master-calibration/workflows/Format%20Check/badge.svg)](https://github.com/jewzaam/ap-master-calibration/actions/workflows/format.yml)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)
```

### Rationale
- Consistency with ap-common which has full badge set
- Visual indication of CI status

---

## Notes
- Has LICENSE file (good)
- Has MANIFEST.in (good)
- Has CRITICAL_INFO.md - unique to this repo, likely intentional domain-specific documentation
- Has examples/ directory - unique to this repo, good for documentation
- No requirements.txt (consistent with ap-common approach)
- Overall well-structured
