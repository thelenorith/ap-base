# Pending Changes: ap-cull-lights

## 1. Add LICENSE file

**Priority**: High
**Status**: Pending

### Summary
LICENSE file is missing. All other repos have Apache-2.0 license file.

### Changes Required
Copy the standard Apache-2.0 LICENSE file to the repository root.

### Rationale
- Required for proper open source licensing
- Consistency with other ap-* projects
- pyproject.toml references Apache-2.0 but file is missing

---

## 2. Add README badges

**Priority**: Low
**Status**: Pending

### Summary
README.md is missing status badges that other repos have.

### Changes Required
Add badges after the title:

```markdown
# ap-cull-lights

[![Test](https://github.com/jewzaam/ap-cull-lights/workflows/Test/badge.svg)](https://github.com/jewzaam/ap-cull-lights/actions/workflows/test.yml)
[![Coverage](https://github.com/jewzaam/ap-cull-lights/workflows/Coverage%20Check/badge.svg)](https://github.com/jewzaam/ap-cull-lights/actions/workflows/coverage.yml)
[![Lint](https://github.com/jewzaam/ap-cull-lights/workflows/Lint/badge.svg)](https://github.com/jewzaam/ap-cull-lights/actions/workflows/lint.yml)
[![Format](https://github.com/jewzaam/ap-cull-lights/workflows/Format%20Check/badge.svg)](https://github.com/jewzaam/ap-cull-lights/actions/workflows/format.yml)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)
```

### Rationale
- Consistency with ap-common which has full badge set
- Visual indication of CI status

---

## 3. Remove requirements.txt (optional)

**Priority**: Low
**Status**: Pending

### Summary
Has requirements.txt which duplicates dependencies in pyproject.toml. Some repos have it, some don't.

### Decision Needed
Decide whether to standardize on having or not having requirements.txt across all repos.
