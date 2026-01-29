# Pending Changes: ap-common

## 1. Standardize Makefile to use target dependencies

**Priority**: High
**Status**: Pending

### Summary
The Makefile uses inline pip install commands, while all other ap-* projects use proper Makefile target dependencies.

### Current State
```makefile
format:
	-$(PYTHON) -m pip install -e ".[dev]" >nul 2>&1 || true
	$(PYTHON) -m black ap_common tests
```

### Desired State
```makefile
format: install-dev
	$(PYTHON) -m black ap_common tests
```

### Changes Required
Update these targets to use `: install-dev` dependency instead of inline pip install:
- `format`
- `lint`
- `test`
- `test-verbose`
- `test-coverage`
- `coverage`

Also update the test comment from:
```
# Testing (try to install deps, but continue if it fails - dependencies may already be installed)
```
to:
```
# Testing (install deps first, then run tests)
```

### Rationale
- More idiomatic Makefile pattern
- Cross-platform (removes Windows-style `>nul` redirect)
- Consistent with ap-move-lights, ap-fits-headers, ap-cull-lights, ap-master-calibration, ap-move-calibration

---

## 2. Fix pyproject.toml inconsistencies

**Priority**: Medium
**Status**: Pending

### Summary
Several fields in pyproject.toml differ from the standard used in other repos.

### Changes Required

#### 2a. Update license format
**Current**:
```toml
license = "Apache-2.0"
license-files = ["LICENSE"]
```

**Desired**:
```toml
license = {text = "Apache-2.0"}
```

#### 2b. Update author name
**Current**:
```toml
authors = [
    {name = "Your Name"}
]
```

**Desired**:
```toml
authors = [
    {name = "Naveen Malik"}
]
```

#### 2c. Consider requires-python
**Current**: `requires-python = ">=3.10"`
**Other repos**: `requires-python = ">=3.8"`

This may be intentional if ap-common uses Python 3.10+ features. Verify before changing.

### Rationale
- Consistency across all ap-* projects
- Correct author attribution
