#!/usr/bin/env bash
#
# publish-issues.sh
#
# Publishes GitHub issues for standards violations and documentation gaps
# found across all ap-* submodules in the jewzaam organization.
#
# Prerequisites:
#   - gh CLI installed and authenticated (https://cli.github.com/)
#   - Write access to the jewzaam repos
#
# Usage:
#   ./publish-issues.sh          # Dry run (default) - shows what would be created
#   ./publish-issues.sh --apply  # Actually create the issues
#
# The script checks for existing open issues by title substring match
# before creating new ones to avoid duplicates.

set -euo pipefail

DRYRUN=true
if [[ "${1:-}" == "--apply" ]]; then
    DRYRUN=false
fi

CREATED=0
SKIPPED=0
FAILED=0

# Create an issue if no existing open issue matches the title substring.
# Arguments:
#   $1 - repo (e.g., jewzaam/ap-common)
#   $2 - title
#   $3 - body
create_issue() {
    local repo="$1"
    local title="$2"
    local body="$3"

    # Check for existing open issue with similar title (first significant words)
    local search_term
    search_term=$(echo "$title" | sed 's/^[^:]*: //' | cut -c1-40)
    local existing
    existing=$(gh issue list --repo "$repo" --state open --search "$search_term" --json title --jq '.[].title' 2>/dev/null || echo "")

    if [[ -n "$existing" ]]; then
        echo "SKIP [$repo] Similar issue may exist: $title"
        echo "  Existing: $existing"
        SKIPPED=$((SKIPPED + 1))
        return 0
    fi

    if $DRYRUN; then
        echo "DRYRUN [$repo] Would create: $title"
    else
        if gh issue create --repo "$repo" --title "$title" --body "$body" 2>/dev/null; then
            echo "CREATED [$repo] $title"
            CREATED=$((CREATED + 1))
        else
            echo "FAILED [$repo] $title"
            FAILED=$((FAILED + 1))
        fi
    fi
}

echo "============================================================"
echo "  ap-* Standards Compliance Issue Publisher"
echo "  Mode: $(if $DRYRUN; then echo 'DRY RUN (pass --apply to create)'; else echo 'APPLY'; fi)"
echo "============================================================"
echo ""

###############################################################################
# jewzaam/ap-common (3 issues)
###############################################################################

echo "--- jewzaam/ap-common ---"

create_issue "jewzaam/ap-common" \
    "Add missing TEST_PLAN.md" \
    "$(cat <<'BODY'
## Problem

Per the [testing standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/testing.md), every ap-* project must have a `TEST_PLAN.md` in the repository root documenting the testing rationale.

ap-common currently has a comprehensive test suite (8 test files, 4000+ lines of tests) but lacks the required `TEST_PLAN.md` document.

## Required

Create `TEST_PLAN.md` using the [template](https://github.com/jewzaam/ap-base/blob/main/standards/standards/templates/TEST_PLAN.md). Document:

- Testing philosophy for a shared library (vs CLI tools)
- Test categories: unit tests for each module (fits.py, normalization.py, metadata.py, etc.)
- Coverage goals (80%+)
- Test data strategy (programmatic generation, tmp_path fixtures)
- Untested areas and rationale

## Reference

- [Testing Standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/testing.md#test_planmd)
- [TEST_PLAN.md Template](https://github.com/jewzaam/ap-base/blob/main/standards/standards/templates/TEST_PLAN.md)
BODY
)"

create_issue "jewzaam/ap-common" \
    "Add pytest-mock>=3.0 to dev dependencies in pyproject.toml" \
    "$(cat <<'BODY'
## Problem

Per the [project structure standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/project-structure.md), all ap-* projects must include `pytest-mock>=3.0` in their dev dependencies. This dependency is required by the [CLI testing standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/cli-testing.md) for the `mocker` fixture.

Current `pyproject.toml` dev dependencies are missing `pytest-mock>=3.0`.

## Fix

Add to `pyproject.toml` under `[project.optional-dependencies]`:

```toml
dev = [
    "pytest>=7.0",
    "pytest-cov>=4.0",
    "pytest-mock>=3.0",  # Add this line
    "black>=23.0",
    "flake8>=6.0",
    "mypy==1.11.2",
]
```

## Reference

- [Project Structure - pyproject.toml](https://github.com/jewzaam/ap-base/blob/main/standards/standards/project-structure.md#pyprojecttoml)
- [CLI Testing - Dependencies](https://github.com/jewzaam/ap-base/blob/main/standards/standards/cli-testing.md#dependencies)
BODY
)"

create_issue "jewzaam/ap-common" \
    "README missing documentation for multiple modules and exported functions" \
    "$(cat <<'BODY'
## Problem

The README.md Package Structure section lists only 5 module files, but the actual package contains 9 modules. The Available Functions / API Reference section is also missing many exported functions.

### Modules missing from README

These modules exist in `ap_common/` but are not listed in the README package structure:

1. **`calibration.py`** - `find_matching_darks`, `find_matching_flats`, `find_matching_bias` (and `*_from_cache` variants)
2. **`constants.py`** - All shared constants (`HEADER_*`, `NORMALIZED_HEADER_*`, `TYPE_*`, `FILE_EXTENSION_*`, `DIRECTORY_*`, etc.)
3. **`logging_config.py`** - `setup_logging()`, `get_logger()`
4. **`progress.py`** - `progress_iter()`, `ProgressTracker`

### Exported functions missing from README

These are exported in `__init__.py` but not documented in the README:

- `update_xisf_headers` (from fits.py)
- `denormalize_header` (from normalization.py)
- `group_by_directory`, `get_directories_with_lights` (from metadata.py)
- `resolve_path` (from utils.py)
- All calibration matching functions
- All constants

## Required

Update README.md to:
1. Add the 4 missing modules to the Package Structure section
2. Add undocumented exported functions to the API Reference section
3. Follow the [README format standard](https://github.com/jewzaam/ap-base/blob/main/standards/standards/readme-format.md)
BODY
)"

###############################################################################
# jewzaam/ap-copy-master-to-blink (3 issues)
###############################################################################

echo ""
echo "--- jewzaam/ap-copy-master-to-blink ---"

create_issue "jewzaam/ap-copy-master-to-blink" \
    "Add missing TEST_PLAN.md" \
    "$(cat <<'BODY'
## Problem

Per the [testing standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/testing.md), every ap-* project must have a `TEST_PLAN.md` in the repository root.

ap-copy-master-to-blink has a comprehensive test suite (10 test files) but lacks the required `TEST_PLAN.md` document.

## Required

Create `TEST_PLAN.md` using the [template](https://github.com/jewzaam/ap-base/blob/main/standards/standards/templates/TEST_PLAN.md). Document:

- Testing philosophy and approach
- Test categories: unit tests per module (matching, scanning, orchestration, etc.) and CLI tests
- Coverage goals (80%+)
- Untested areas (e.g., flat_batch_selection.py currently has no tests)

## Reference

- [Testing Standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/testing.md#test_planmd)
- [TEST_PLAN.md Template](https://github.com/jewzaam/ap-base/blob/main/standards/standards/templates/TEST_PLAN.md)
BODY
)"

create_issue "jewzaam/ap-copy-master-to-blink" \
    "Add pytest-mock>=3.0 to dev dependencies and add tests for flat_batch_selection.py" \
    "$(cat <<'BODY'
## Problem

Two testing-related standards issues:

### 1. Missing pytest-mock dev dependency

Per the [project structure standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/project-structure.md), `pytest-mock>=3.0` is required in dev dependencies but is currently missing from `pyproject.toml`.

### 2. flat_batch_selection.py has no unit tests

The module `ap_copy_master_to_blink/flat_batch_selection.py` (260 lines) has no corresponding test file. Per the [testing standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/testing.md), every module should have tests.

## Fix

1. Add `pytest-mock>=3.0` to `[project.optional-dependencies]` dev list in `pyproject.toml`
2. Create `tests/test_flat_batch_selection.py` with tests covering the module's functionality

## Reference

- [Project Structure - pyproject.toml](https://github.com/jewzaam/ap-base/blob/main/standards/standards/project-structure.md#pyprojecttoml)
- [Testing Standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/testing.md)
BODY
)"

create_issue "jewzaam/ap-copy-master-to-blink" \
    "Standardize GitHub workflow branch triggers to [main] only" \
    "$(cat <<'BODY'
## Problem

Per the [GitHub workflow standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/github-workflows.md), all workflows should trigger on `branches: [main]` only.

Currently, 4 of 5 workflows in this repo use `branches: [main, master]`:
- `.github/workflows/test.yml`
- `.github/workflows/lint.yml`
- `.github/workflows/format.yml`
- `.github/workflows/coverage.yml`

Only `typecheck.yml` correctly uses `branches: [main]`.

## Fix

Update the `on:` section in each affected workflow file:

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```

## Reference

- [GitHub Workflows - Triggers](https://github.com/jewzaam/ap-base/blob/main/standards/standards/github-workflows.md#triggers)
- [Workflow Templates](https://github.com/jewzaam/ap-base/blob/main/standards/standards/templates/workflows/)
BODY
)"

###############################################################################
# jewzaam/ap-create-master (1 issue)
###############################################################################

echo ""
echo "--- jewzaam/ap-create-master ---"

create_issue "jewzaam/ap-create-master" \
    "Replace hardcoded strings with ap-common constants" \
    "$(cat <<'BODY'
## Problem

Per the [ap-common usage standard](https://github.com/jewzaam/ap-base/blob/main/standards/standards/ap-common-usage.md), all ap-* projects must use constants from `ap-common` rather than redefining or hardcoding them locally.

### Violations found

**`calibrate_masters.py`:**
- Lines 186-188: Hardcoded `"MASTER BIAS"`, `"MASTER DARK"`, `"MASTER FLAT"` in `type_mapping` dict. Should use `TYPE_MASTER_BIAS`, `TYPE_MASTER_DARK`, `TYPE_MASTER_FLAT` from `ap_common.constants`.
- Line 208: Hardcoded `"IMAGETYP"` as fallback. Should use `HEADER_IMAGETYP` from `ap_common.constants`.
- Line 279: Hardcoded file patterns `[r".*\.fits$", r".*\.fit$"]`. Should use `DEFAULT_FITS_PATTERN` from `ap_common.constants` (note: `.fit` support may need to be added to ap-common).

**`master_matching.py`:**
- Line 59: Dynamically constructs `f"MASTER {master_type.upper()}"` instead of using `TYPE_MASTER_*` constants.
- Line 82: Hardcoded file extension patterns. Should use constants from ap-common.

**`config.py`:**
- Line 74: `IGNORED_TYPES = ["light"]` hardcodes the string. Could derive from `TYPE_LIGHT` for consistency.

## Fix

Import and use the appropriate constants from `ap_common.constants`:

```python
from ap_common.constants import (
    TYPE_MASTER_BIAS, TYPE_MASTER_DARK, TYPE_MASTER_FLAT,
    HEADER_IMAGETYP, DEFAULT_FITS_PATTERN,
)
```

## Reference

- [ap-common Usage Standard](https://github.com/jewzaam/ap-base/blob/main/standards/standards/ap-common-usage.md)
BODY
)"

###############################################################################
# jewzaam/ap-cull-light (3 issues)
###############################################################################

echo ""
echo "--- jewzaam/ap-cull-light ---"

create_issue "jewzaam/ap-cull-light" \
    "Add missing TEST_PLAN.md" \
    "$(cat <<'BODY'
## Problem

Per the [testing standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/testing.md), every ap-* project must have a `TEST_PLAN.md` in the repository root.

ap-cull-light has tests (40+ test methods in test_cull_lights.py) but lacks the required `TEST_PLAN.md` document.

## Required

Create `TEST_PLAN.md` using the [template](https://github.com/jewzaam/ap-base/blob/main/standards/standards/templates/TEST_PLAN.md).

## Reference

- [Testing Standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/testing.md#test_planmd)
- [TEST_PLAN.md Template](https://github.com/jewzaam/ap-base/blob/main/standards/standards/templates/TEST_PLAN.md)
BODY
)"

create_issue "jewzaam/ap-cull-light" \
    "Add pytest-mock>=3.0 to dev dependencies in pyproject.toml" \
    "$(cat <<'BODY'
## Problem

Per the [project structure standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/project-structure.md), `pytest-mock>=3.0` is required in dev dependencies.

Current `pyproject.toml` dev dependencies are missing `pytest-mock>=3.0`.

## Fix

Add `"pytest-mock>=3.0"` to the dev dependency list in `pyproject.toml`.

## Reference

- [Project Structure - pyproject.toml](https://github.com/jewzaam/ap-base/blob/main/standards/standards/project-structure.md#pyprojecttoml)
BODY
)"

create_issue "jewzaam/ap-cull-light" \
    "Use ap-common constants instead of hardcoded strings; fix README module invocation" \
    "$(cat <<'BODY'
## Problem

Two standards issues:

### 1. Hardcoded string literal violates ap-common usage standard

In `cull_lights.py` (lines 208, 225, 233), the string `"filename"` is used directly:
```python
filename_for_log = metadata.get("filename", "unknown")
```

Per the [ap-common usage standard](https://github.com/jewzaam/ap-base/blob/main/standards/standards/ap-common-usage.md), this should use `NORMALIZED_HEADER_FILENAME` from `ap_common.constants`.

### 2. README uses non-standard module invocation

The README documents usage as:
```bash
python -m ap_cull_light.cull_lights <source_dir> <reject_dir>
```

Since `__main__.py` exists, the standard invocation should be:
```bash
python -m ap_cull_light <source_dir> <reject_dir>
```

This is consistent with all other tools in the pipeline that use `python -m <package>` pattern.

## Fix

1. Import and use `NORMALIZED_HEADER_FILENAME` from `ap_common`:
   ```python
   from ap_common import NORMALIZED_HEADER_FILENAME
   filename_for_log = metadata.get(NORMALIZED_HEADER_FILENAME, "unknown")
   ```

2. Update README.md to use `python -m ap_cull_light` in all usage examples.

## Reference

- [ap-common Usage Standard](https://github.com/jewzaam/ap-base/blob/main/standards/standards/ap-common-usage.md)
BODY
)"

###############################################################################
# jewzaam/ap-empty-directory (4 issues)
###############################################################################

echo ""
echo "--- jewzaam/ap-empty-directory ---"

create_issue "jewzaam/ap-empty-directory" \
    "Add missing TEST_PLAN.md" \
    "$(cat <<'BODY'
## Problem

Per the [testing standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/testing.md), every ap-* project must have a `TEST_PLAN.md` in the repository root.

ap-empty-directory has tests (test_empty.py, test_cli.py) but lacks the required `TEST_PLAN.md` document.

## Required

Create `TEST_PLAN.md` using the [template](https://github.com/jewzaam/ap-base/blob/main/standards/standards/templates/TEST_PLAN.md).

## Reference

- [Testing Standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/testing.md#test_planmd)
- [TEST_PLAN.md Template](https://github.com/jewzaam/ap-base/blob/main/standards/standards/templates/TEST_PLAN.md)
BODY
)"

create_issue "jewzaam/ap-empty-directory" \
    "Update pyproject.toml: add pytest-mock>=3.0, pin mypy==1.11.2" \
    "$(cat <<'BODY'
## Problem

The `pyproject.toml` dev dependencies have two issues per the [project structure standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/project-structure.md):

1. **Missing `pytest-mock>=3.0`**: Required by the standard but not present.
2. **`mypy` not version-pinned**: Currently listed as just `"mypy"` with no version. Standard requires `"mypy==1.11.2"` for consistent type checking across environments.

## Fix

Update `[project.optional-dependencies]` in `pyproject.toml`:

```toml
dev = [
    "pytest>=7.0",
    "pytest-cov>=4.0",
    "pytest-mock>=3.0",
    "black>=23.0",
    "flake8>=6.0",
    "mypy==1.11.2",
]
```

## Reference

- [Project Structure - pyproject.toml](https://github.com/jewzaam/ap-base/blob/main/standards/standards/project-structure.md#pyprojecttoml)
BODY
)"

create_issue "jewzaam/ap-empty-directory" \
    "Update format.yml and coverage.yml to match standard templates" \
    "$(cat <<'BODY'
## Problem

Two GitHub workflow files deviate significantly from the [standard templates](https://github.com/jewzaam/ap-base/blob/main/standards/standards/templates/workflows/):

### format.yml

Current implementation uses a simple `python -m black --check` command. The standard template uses a more robust approach that:
- Runs `make format` (to apply formatting)
- Uses `git diff --exit-code` to detect changes
- Provides clear error messages listing files that need formatting

### coverage.yml

Current implementation is a basic coverage report with significant missing features:
- Missing `permissions:` section (`contents: read`, `pull-requests: write`)
- Missing coverage percentage extraction and threshold calculation
- Missing 80% coverage threshold enforcement
- Missing PR comment with coverage report on failure
- Missing final pass/fail verification step

## Fix

Replace both workflow files with the standard templates from [standards/templates/workflows/](https://github.com/jewzaam/ap-base/blob/main/standards/standards/templates/workflows/). No modifications are needed since workflows use Makefile targets.

## Reference

- [GitHub Workflows Standard](https://github.com/jewzaam/ap-base/blob/main/standards/standards/github-workflows.md)
- [format.yml template](https://github.com/jewzaam/ap-base/blob/main/standards/standards/templates/workflows/format.yml)
- [coverage.yml template](https://github.com/jewzaam/ap-base/blob/main/standards/standards/templates/workflows/coverage.yml)
BODY
)"

create_issue "jewzaam/ap-empty-directory" \
    "README missing documentation for --exclude-regex/-e flag" \
    "$(cat <<'BODY'
## Problem

The README.md options table does not document the `--exclude-regex` / `-e` flag, which exists in the CLI.

In `cli.py` (lines 48-54):
```python
parser.add_argument(
    "--exclude-regex", "-e",
    type=str, default=None,
    help="regex pattern to exclude files from deletion (matched against filename)",
)
```

The README options table lists `--recursive`, `--dryrun`, `--debug`, and `--quiet` but omits `--exclude-regex`.

## Fix

Add to the README options table:

```markdown
| `--exclude-regex REGEX, -e` | Regex pattern to exclude files from deletion |
```

Also add a usage example showing the flag in action.

## Reference

- [README Format Standard](https://github.com/jewzaam/ap-base/blob/main/standards/standards/readme-format.md)
BODY
)"

###############################################################################
# jewzaam/ap-move-light-to-data (1 issue)
###############################################################################

echo ""
echo "--- jewzaam/ap-move-light-to-data ---"

create_issue "jewzaam/ap-move-light-to-data" \
    "Pin mypy==1.11.2 in pyproject.toml and standardize workflow branch triggers" \
    "$(cat <<'BODY'
## Problem

Two minor standards deviations:

### 1. mypy not version-pinned in pyproject.toml

The `pyproject.toml` lists `"mypy"` without a version pin (line 35). The [project structure standard](https://github.com/jewzaam/ap-base/blob/main/standards/standards/project-structure.md) requires `"mypy==1.11.2"` for consistent type checking.

### 2. Workflow branch triggers include `master`

`test.yml` and `lint.yml` use `branches: [ main, master ]` instead of the standard `branches: [main]`.

## Fix

1. In `pyproject.toml`, change `"mypy",` to `"mypy==1.11.2",`
2. In `.github/workflows/test.yml` and `.github/workflows/lint.yml`, change branch triggers to `[main]` only.

## Reference

- [Project Structure - pyproject.toml](https://github.com/jewzaam/ap-base/blob/main/standards/standards/project-structure.md#pyprojecttoml)
- [GitHub Workflows - Triggers](https://github.com/jewzaam/ap-base/blob/main/standards/standards/github-workflows.md#triggers)
BODY
)"

###############################################################################
# jewzaam/ap-move-master-to-library (3 issues)
###############################################################################

echo ""
echo "--- jewzaam/ap-move-master-to-library ---"

create_issue "jewzaam/ap-move-master-to-library" \
    "Update format.yml to use Python 3.12 per standard" \
    "$(cat <<'BODY'
## Problem

Per the [GitHub workflow standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/github-workflows.md), single-version jobs (lint, format, typecheck, coverage) should use Python 3.12.

The `format.yml` workflow currently uses Python 3.14 instead of 3.12. All other workflows in this repo correctly use 3.12.

## Fix

In `.github/workflows/format.yml`, change the Python version:

```yaml
- name: Set up Python
  uses: actions/setup-python@v5
  with:
    python-version: "3.12"
```

## Reference

- [GitHub Workflows - Python versions](https://github.com/jewzaam/ap-base/blob/main/standards/standards/github-workflows.md#python-versions)
BODY
)"

create_issue "jewzaam/ap-move-master-to-library" \
    "Replace hardcoded string literals with ap-common constants" \
    "$(cat <<'BODY'
## Problem

Per the [ap-common usage standard](https://github.com/jewzaam/ap-base/blob/main/standards/standards/ap-common-usage.md), all ap-* projects must use constants from `ap-common` rather than hardcoding string literals.

### Violations found in `move_calibration.py`

Multiple uses of hardcoded `"type"` string instead of `NORMALIZED_HEADER_TYPE`:

- Line 46: `datum["type"]` — should use `datum[NORMALIZED_HEADER_TYPE]`
- Line 49: `config.FILENAME_PROPERTIES[datum["type"]]` — same
- Lines 73, 90, 108: `datum["type"]` in `_build_dest_path` functions
- Lines 140, 143: `"type" not in datum` and `datum["type"]`

Also:
- Line 266: Hardcoded file extension patterns `[r".*\.xisf$", r".*\.fits$"]` — should use `DEFAULT_CALIBRATION_PATTERNS` from `ap_common.constants`
- Line 269: Hardcoded `{"type": frame_type}` filter key — should use `{NORMALIZED_HEADER_TYPE: frame_type}`

Note: `config.py` already imports `NORMALIZED_HEADER_TYPE` from `ap_common.constants`, so this constant just needs to be used consistently in `move_calibration.py`.

## Fix

In `move_calibration.py`, import `NORMALIZED_HEADER_TYPE` and replace all `"type"` string literals with the constant. Import `DEFAULT_CALIBRATION_PATTERNS` for file patterns.

## Reference

- [ap-common Usage Standard](https://github.com/jewzaam/ap-base/blob/main/standards/standards/ap-common-usage.md)
BODY
)"

create_issue "jewzaam/ap-move-master-to-library" \
    "CLI tests for --quiet flag don't verify kwargs passing" \
    "$(cat <<'BODY'
## Problem

Per the [CLI testing standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/cli-testing.md), CLI tests must verify `call_args.kwargs` to catch attribute name mismatches.

In `tests/test_main.py`, the `test_quiet_flag()` and `test_all_flags_combined()` tests verify that `main()` executes successfully when `--quiet` is passed, but they do **not** verify that `quiet=True` is passed through to `copy_calibration_frames()` via `call_args.kwargs["quiet"]`.

The code in `move_calibration.py` line 378 correctly passes `quiet=args.quiet`, but the test doesn't assert this, meaning a typo like `quiet=args.quie` would not be caught.

## Fix

Add kwargs verification to the quiet flag tests:

```python
def test_quiet_flag(self, mock_validate, mock_copy):
    # ... existing test setup ...
    call_args = mock_copy.call_args
    assert call_args.kwargs["quiet"] == True

def test_all_flags_combined(self, mock_validate, mock_copy):
    # ... existing test setup ...
    call_args = mock_copy.call_args
    assert call_args.kwargs["quiet"] == True
```

## Reference

- [CLI Testing Standards - Required Coverage](https://github.com/jewzaam/ap-base/blob/main/standards/standards/cli-testing.md#required-coverage)
BODY
)"

###############################################################################
# jewzaam/ap-move-raw-light-to-blink (5 issues)
###############################################################################

echo ""
echo "--- jewzaam/ap-move-raw-light-to-blink ---"

create_issue "jewzaam/ap-move-raw-light-to-blink" \
    "Add missing TEST_PLAN.md" \
    "$(cat <<'BODY'
## Problem

Per the [testing standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/testing.md), every ap-* project must have a `TEST_PLAN.md` in the repository root.

## Required

Create `TEST_PLAN.md` using the [template](https://github.com/jewzaam/ap-base/blob/main/standards/standards/templates/TEST_PLAN.md).

## Reference

- [Testing Standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/testing.md#test_planmd)
BODY
)"

create_issue "jewzaam/ap-move-raw-light-to-blink" \
    "Add pytest-mock>=3.0 to dev dependencies in pyproject.toml" \
    "$(cat <<'BODY'
## Problem

Per the [project structure standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/project-structure.md), `pytest-mock>=3.0` is required in dev dependencies but is currently missing from `pyproject.toml`.

## Fix

Add `"pytest-mock>=3.0"` to the dev dependency list in `pyproject.toml`.

## Reference

- [Project Structure - pyproject.toml](https://github.com/jewzaam/ap-base/blob/main/standards/standards/project-structure.md#pyprojecttoml)
BODY
)"

create_issue "jewzaam/ap-move-raw-light-to-blink" \
    "Replace hardcoded strings with ap-common constants" \
    "$(cat <<'BODY'
## Problem

Per the [ap-common usage standard](https://github.com/jewzaam/ap-base/blob/main/standards/standards/ap-common-usage.md), all string constants should come from `ap-common`.

### Violations found

**`config.py` line 8:**
```python
DIRECTORY_ACCEPT = "accept"
```
This redefines `DIRECTORY_ACCEPT` which is already exported by `ap_common.constants`. Should import instead.

**`move_lights.py` lines 60-71:**
```python
required_properties = ["camera", "type", "date", "exposureseconds", ...]
```
Hardcoded normalized header name strings. Should use `NORMALIZED_HEADER_CAMERA`, `NORMALIZED_HEADER_TYPE`, `NORMALIZED_HEADER_DATE`, `NORMALIZED_HEADER_EXPOSURESECONDS`, etc.

**`move_lights.py` line 79:**
```python
filters={"type": "LIGHT"},
```
Should be `{NORMALIZED_HEADER_TYPE: TYPE_LIGHT}`.

**`move_lights.py` lines 92, 94:**
```python
filename_src = datum["filename"]
if "type" not in datum:
```
Should use `NORMALIZED_HEADER_FILENAME` and `NORMALIZED_HEADER_TYPE`.

## Fix

Import constants from `ap_common` and replace all hardcoded string literals.

## Reference

- [ap-common Usage Standard](https://github.com/jewzaam/ap-base/blob/main/standards/standards/ap-common-usage.md)
BODY
)"

create_issue "jewzaam/ap-move-raw-light-to-blink" \
    "Add missing CLI flag tests and update README" \
    "$(cat <<'BODY'
## Problem

Two related issues with CLI coverage and documentation:

### 1. Missing CLI flag tests

Per the [CLI testing standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/cli-testing.md), every CLI flag must have tests. The following flags lack test coverage:

- `--quiet` / `-q`
- `--blink-dir`
- `--accept-dir`
- `--no-accept`

Only `--debug` and `--dryrun` are tested in `test_move_lights.py`.

### 2. README documentation gaps

- **Missing `--quiet` / `-q` flag** from the README options list (the flag exists in argparse at `move_lights.py` line 148)
- **Non-standard module invocation**: README documents `python -m ap_move_raw_light_to_blink.move_lights` but the standard pattern (since `__main__.py` exists) is `python -m ap_move_raw_light_to_blink`

## Fix

1. Add test methods for each missing flag in `tests/test_move_lights.py` following the [CLI testing pattern](https://github.com/jewzaam/ap-base/blob/main/standards/standards/cli-testing.md#testing-pattern-reference-implementation)
2. Add `--quiet` / `-q` to README options table
3. Update README usage examples to use `python -m ap_move_raw_light_to_blink`

## Reference

- [CLI Testing Standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/cli-testing.md)
- [README Format Standard](https://github.com/jewzaam/ap-base/blob/main/standards/standards/readme-format.md)
BODY
)"

create_issue "jewzaam/ap-move-raw-light-to-blink" \
    "Standardize workflow branch triggers and format.yml Python version" \
    "$(cat <<'BODY'
## Problem

GitHub workflow deviations from [standard templates](https://github.com/jewzaam/ap-base/blob/main/standards/standards/templates/workflows/):

### 1. Branch triggers include `master`

`test.yml`, `lint.yml`, and `format.yml` use `branches: [ main, master ]` instead of the standard `branches: [main]`.

### 2. format.yml uses wrong Python version

`format.yml` uses Python 3.14 instead of the standard 3.12 for single-version jobs. It also includes custom pip install steps not present in the template.

## Fix

1. Update branch triggers in `test.yml`, `lint.yml`, `format.yml` to `[main]` only
2. Replace `format.yml` with the [standard template](https://github.com/jewzaam/ap-base/blob/main/standards/standards/templates/workflows/format.yml)

## Reference

- [GitHub Workflows - Triggers](https://github.com/jewzaam/ap-base/blob/main/standards/standards/github-workflows.md#triggers)
- [GitHub Workflows - Python versions](https://github.com/jewzaam/ap-base/blob/main/standards/standards/github-workflows.md#python-versions)
BODY
)"

###############################################################################
# jewzaam/ap-preserve-header (3 issues)
###############################################################################

echo ""
echo "--- jewzaam/ap-preserve-header ---"

create_issue "jewzaam/ap-preserve-header" \
    "Add missing TEST_PLAN.md" \
    "$(cat <<'BODY'
## Problem

Per the [testing standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/testing.md), every ap-* project must have a `TEST_PLAN.md` in the repository root.

ap-preserve-header has tests (31+ test methods in test_preserve_headers.py) but lacks the required `TEST_PLAN.md` document.

## Required

Create `TEST_PLAN.md` using the [template](https://github.com/jewzaam/ap-base/blob/main/standards/standards/templates/TEST_PLAN.md).

## Reference

- [Testing Standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/testing.md#test_planmd)
BODY
)"

create_issue "jewzaam/ap-preserve-header" \
    "Add pytest-mock>=3.0 to dev dependencies in pyproject.toml" \
    "$(cat <<'BODY'
## Problem

Per the [project structure standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/project-structure.md), `pytest-mock>=3.0` is required in dev dependencies but is currently missing from `pyproject.toml`.

## Fix

Add `"pytest-mock>=3.0"` to the dev dependency list in `pyproject.toml`.

## Reference

- [Project Structure - pyproject.toml](https://github.com/jewzaam/ap-base/blob/main/standards/standards/project-structure.md#pyprojecttoml)
BODY
)"

create_issue "jewzaam/ap-preserve-header" \
    "Update format.yml and coverage.yml to match standard templates; fix README module invocation" \
    "$(cat <<'BODY'
## Problem

Three standards issues:

### 1. format.yml deviates from template

- Uses non-standard indentation (4 spaces instead of 2)
- Uses `branches: [ main, master ]` instead of `[main]`
- Contains custom pip install steps not in the template

### 2. coverage.yml deviates from template

- Uses `branches: [ main, master ]` instead of `[main]`
- Uses explicit `python -m pytest --cov=...` instead of `make coverage`
- Contains custom pip install with comments
- Uses `lfs: true` in checkout (not in template)

### 3. README uses non-standard module invocation

The README documents:
```bash
python -m ap_preserve_header.preserve_headers <root_dir>
```

Since `__main__.py` exists, the standard invocation should be:
```bash
python -m ap_preserve_header <root_dir>
```

## Fix

1. Replace `format.yml` with the [standard template](https://github.com/jewzaam/ap-base/blob/main/standards/standards/templates/workflows/format.yml)
2. Replace `coverage.yml` with the [standard template](https://github.com/jewzaam/ap-base/blob/main/standards/standards/templates/workflows/coverage.yml)
3. Update README.md to use `python -m ap_preserve_header` in all usage examples

## Reference

- [GitHub Workflows Standard](https://github.com/jewzaam/ap-base/blob/main/standards/standards/github-workflows.md)
- [Workflow Templates](https://github.com/jewzaam/ap-base/blob/main/standards/standards/templates/workflows/)
BODY
)"

###############################################################################
# jewzaam/ap-base (5 issues)
###############################################################################

echo ""
echo "--- jewzaam/ap-base ---"

create_issue "jewzaam/ap-base" \
    "docs/tools/ap-common.md: Multiple incorrect function signatures" \
    "$(cat <<'BODY'
## Problem

The `docs/tools/ap-common.md` documentation contains multiple incorrect function signatures and behavior descriptions that would mislead users.

### Incorrect function signatures

1. **`get_fits_headers`**: Doc shows `get_fits_headers("image.fits", profileFromPath=True)` but actual signature requires `profileFromPath` as positional and has additional params: `normalize`, `file_naming_override`, `directory_accept`.

2. **`get_xisf_headers`**: Doc shows `get_xisf_headers("image.xisf")` but `profileFromPath` is a required positional parameter — this call would fail.

3. **`get_file_headers`**: Doc shows `get_file_headers("/CAMERA_ASI294/image.fits")` but `profileFromPath` is required — this call would fail.

4. **`replace_env_vars`**: Doc shows `$VAR` syntax but the actual code uses `%VAR%` syntax (Windows-style percent delimiters).

5. **`get_filenames`**: Doc shows `get_filenames("/data", patterns=["*.fits"])` but the first parameter must be a **list** not a string, and patterns are **regex** not glob: `get_filenames(["/data"], patterns=[r".*\.fits$"])`.

6. **`build_normalized_filters`**: Doc shows a 1-parameter call but actual function requires 3 params: `(metadata, headers, overrides=None)`.

### Incorrect behavior description

- Doc says `normalize_filterName("Luminance")` returns `"L"` but the actual function is a no-op that returns its input unchanged (`"Luminance"`).

## Fix

Update all function signatures and examples in `docs/tools/ap-common.md` to match the actual code in `ap_common/`.

## Reference

- Source: `ap-common/ap_common/fits.py`, `ap_common/utils.py`, `ap_common/metadata.py`, `ap_common/normalization.py`
BODY
)"

create_issue "jewzaam/ap-base" \
    "docs/tools/ap-common.md: Missing documentation for calibration, constants, logging, and progress modules" \
    "$(cat <<'BODY'
## Problem

The `docs/tools/ap-common.md` tool documentation is missing coverage of 4 modules that are part of the ap-common package:

### Missing modules

1. **`calibration.py`** — Provides calibration frame matching: `find_matching_darks()`, `find_matching_flats()`, `find_matching_bias()`, and their `*_from_cache` variants. This is critical functionality used by ap-copy-master-to-blink and ap-move-light-to-data.

2. **`constants.py`** — Defines all shared constants: `HEADER_*`, `NORMALIZED_HEADER_*`, `TYPE_*`, `FILE_EXTENSION_*`, `DIRECTORY_*`, `CALIBRATION_TYPES`, `MASTER_CALIBRATION_TYPES`, etc. Referenced by the [ap-common usage standard](https://github.com/jewzaam/ap-base/blob/main/standards/standards/ap-common-usage.md) as the single source of truth.

3. **`logging_config.py`** — Provides `setup_logging()` and `get_logger()`. Referenced by the [logging standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/logging-progress.md) as the required way to configure logging.

4. **`progress.py`** — Provides `progress_iter()` and `ProgressTracker`. Referenced by the [logging standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/logging-progress.md) as the required progress indicator utilities.

## Fix

Add sections to `docs/tools/ap-common.md` documenting each missing module with:
- Module purpose and description
- Key functions with correct signatures
- Usage examples

## Reference

- Source: `ap-common/ap_common/calibration.py`, `constants.py`, `logging_config.py`, `progress.py`
- [ap-common Usage Standard](https://github.com/jewzaam/ap-base/blob/main/standards/standards/ap-common-usage.md)
- [Logging & Progress Standards](https://github.com/jewzaam/ap-base/blob/main/standards/standards/logging-progress.md)
BODY
)"

create_issue "jewzaam/ap-base" \
    "docs/tools: --quiet/-q flag missing from 5 tool documentation pages" \
    "$(cat <<'BODY'
## Problem

The `--quiet` / `-q` CLI flag is a [required standard flag](https://github.com/jewzaam/ap-base/blob/main/standards/standards/cli.md#required-options) for all ap-* tools. All the following tools implement this flag in their argparse code, but their documentation pages in `docs/tools/` do not list it.

### Affected documentation pages

1. **`docs/tools/ap-cull-light.md`** — `--quiet`/`-q` exists in `cull_lights.py` line 408 but not in the doc
2. **`docs/tools/ap-empty-directory.md`** — `--quiet`/`-q` exists in `cli.py` line 43 but not in the doc
3. **`docs/tools/ap-move-master-to-library.md`** — `--quiet`/`-q` exists in `move_calibration.py` line 357 but not in the doc
4. **`docs/tools/ap-move-raw-light-to-blink.md`** — `--quiet`/`-q` exists in `move_lights.py` line 148 but not in the doc
5. **`docs/tools/ap-preserve-header.md`** — `--quiet`/`-q` exists in `preserve_headers.py` line 398 but not in the doc

## Fix

Add `--quiet` / `-q` to the CLI options table in each affected documentation page:

```markdown
| `--quiet`, `-q` | Suppress non-essential output (progress, INFO logs, summaries) |
```

## Reference

- [CLI Standards - Required Options](https://github.com/jewzaam/ap-base/blob/main/standards/standards/cli.md#required-options)
BODY
)"

create_issue "jewzaam/ap-base" \
    "docs/tools/ap-copy-master-to-blink.md: Undocumented CLI flags and outdated limitations" \
    "$(cat <<'BODY'
## Problem

The `docs/tools/ap-copy-master-to-blink.md` documentation is missing recently added CLI flags and contains outdated information.

### Missing CLI flags

These flags exist in `__main__.py` but are not documented:

1. **`--flat-state PATH`** (lines 130-138): Enables flexible flat date matching with a YAML state file for interactive selection when no exact date match exists.

2. **`--picker-limit N`** (lines 140-147): Maximum number of older/newer flat dates to show in the interactive picker. Default: 5.

3. **`--date-dir-pattern PATTERN`** (lines 149-155): Regex pattern to match date directories. Default: `^DATE_.*`.

### Outdated limitation

The "Current Limitations" section states:
> "DATE must match exactly: Current implementation requires exact date match for flats."

This is outdated — the `--flat-state` flag provides flexible flat date matching with interactive selection when no exact date match exists.

## Fix

1. Add the three missing flags to the Options/CLI section
2. Update or remove the "Current Limitations" section about exact DATE matching
3. Add documentation about the flat-state workflow

## Reference

- Source: `ap-copy-master-to-blink/ap_copy_master_to_blink/__main__.py` lines 130-155
BODY
)"

create_issue "jewzaam/ap-base" \
    "docs/tools: Minor inaccuracies across multiple tool documentation pages" \
    "$(cat <<'BODY'
## Problem

Several minor documentation inaccuracies found across `docs/tools/` pages:

### docs/tools/ap-create-master.md

1. **Mermaid diagram missing Readout Mode**: The second flowchart (grouping keys diagram) omits Readout Mode from all three frame types (Bias, Dark, Flat), but Readout Mode is part of the actual grouping keys in `config.py`.

2. **Troubleshooting mentions .xisf as valid input**: The troubleshooting section says "Verify file extensions (.fit, .fits, .xisf)" but the actual code only scans `.fits` and `.fit` files — `.xisf` is not a valid input format for this tool.

### docs/tools/ap-move-master-to-library.md

3. **MASTER FLAT metadata table missing Readout Mode**: The "Metadata Extraction" table shows MASTER FLAT "Filename Keys" as "Filter, Gain, Offset, Temp, Focal Length" but the actual `FILENAME_PROPERTIES` config also includes Readout Mode.

### docs/tools/ap-move-light-to-data.md

4. **--path-pattern default value not documented**: The `--path-pattern` flag has a default value of `r".*[/\\]accept[/\\].*"` (only processes paths containing an `accept` directory), but the documentation doesn't mention this default. Users would expect all lights to be processed without this flag.

## Fix

1. Add Readout Mode to the grouping keys mermaid diagram in ap-create-master.md
2. Remove `.xisf` from the troubleshooting "valid extensions" list in ap-create-master.md
3. Add Readout Mode to the MASTER FLAT filename keys in ap-move-master-to-library.md
4. Document the default value of `--path-pattern` in ap-move-light-to-data.md
BODY
)"

###############################################################################
# Summary
###############################################################################

echo ""
echo "============================================================"
echo "  Summary"
echo "============================================================"

if $DRYRUN; then
    echo "  Mode: DRY RUN (no issues created)"
    echo "  Run with --apply to create issues"
else
    echo "  Created: $CREATED"
    echo "  Skipped (possible duplicate): $SKIPPED"
    echo "  Failed: $FAILED"
fi

echo ""
echo "  Issue breakdown by repo:"
echo "    jewzaam/ap-common:                  3 issues"
echo "    jewzaam/ap-copy-master-to-blink:    3 issues"
echo "    jewzaam/ap-create-master:           1 issue"
echo "    jewzaam/ap-cull-light:              3 issues"
echo "    jewzaam/ap-empty-directory:         4 issues"
echo "    jewzaam/ap-move-light-to-data:      1 issue"
echo "    jewzaam/ap-move-master-to-library:  3 issues"
echo "    jewzaam/ap-move-raw-light-to-blink: 5 issues"
echo "    jewzaam/ap-preserve-header:         3 issues"
echo "    jewzaam/ap-base:                    5 issues"
echo "    ─────────────────────────────────────────"
echo "    Total:                             31 issues"
echo ""
