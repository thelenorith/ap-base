# Pending Changes: ap-fits-headers

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
# ap-fits-headers

[![Test](https://github.com/jewzaam/ap-fits-headers/workflows/Test/badge.svg)](https://github.com/jewzaam/ap-fits-headers/actions/workflows/test.yml)
[![Coverage](https://github.com/jewzaam/ap-fits-headers/workflows/Coverage%20Check/badge.svg)](https://github.com/jewzaam/ap-fits-headers/actions/workflows/coverage.yml)
[![Lint](https://github.com/jewzaam/ap-fits-headers/workflows/Lint/badge.svg)](https://github.com/jewzaam/ap-fits-headers/actions/workflows/lint.yml)
[![Format](https://github.com/jewzaam/ap-fits-headers/workflows/Format%20Check/badge.svg)](https://github.com/jewzaam/ap-fits-headers/actions/workflows/format.yml)
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
Decide whether to standardize on:
- Having requirements.txt (for pip install -r compatibility)
- Not having it (pyproject.toml is the source of truth)

If keeping, ensure it stays in sync with pyproject.toml dependencies.
