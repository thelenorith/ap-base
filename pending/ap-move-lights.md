# Pending Changes: ap-move-lights

## 1. Add README badges

**Priority**: Low
**Status**: Pending

### Summary
README.md is missing status badges that ap-common has.

### Changes Required
Add badges after the title:

```markdown
# ap-move-lights

[![Test](https://github.com/jewzaam/ap-move-lights/workflows/Test/badge.svg)](https://github.com/jewzaam/ap-move-lights/actions/workflows/test.yml)
[![Coverage](https://github.com/jewzaam/ap-move-lights/workflows/Coverage%20Check/badge.svg)](https://github.com/jewzaam/ap-move-lights/actions/workflows/coverage.yml)
[![Lint](https://github.com/jewzaam/ap-move-lights/workflows/Lint/badge.svg)](https://github.com/jewzaam/ap-move-lights/actions/workflows/lint.yml)
[![Format](https://github.com/jewzaam/ap-move-lights/workflows/Format%20Check/badge.svg)](https://github.com/jewzaam/ap-move-lights/actions/workflows/format.yml)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)
```

### Rationale
- Consistency with ap-common which has full badge set
- Visual indication of CI status

---

## 2. Remove requirements.txt (optional)

**Priority**: Low
**Status**: Pending

### Summary
Has requirements.txt which duplicates dependencies in pyproject.toml. Some repos have it, some don't.

### Decision Needed
Decide whether to standardize on having or not having requirements.txt across all repos.

---

## Notes
This repo is otherwise well-structured and consistent with standards.
