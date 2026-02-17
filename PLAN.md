# Plan: Adopt venv Standard Across All Submodules

## Problem

Currently, no submodule Makefile creates or manages a virtual environment. All
`pip install` commands run against whatever Python environment is active, which
can pollute the system Python, cause dependency conflicts between projects, and
make local development less reproducible.

## Goal

Every submodule Makefile automatically creates and uses a `.venv` virtual
environment. Developers run `make test` (or any other target) and the venv is
transparently created and used. CI workflows continue to work unchanged.

---

## Changes Required

### 1. Update the Makefile template in `standards/`

**File:** `standards/standards/templates/Makefile`

Add venv management variables and a venv creation target. Change all targets to
use the venv Python instead of the system Python.

**Key changes:**

```makefile
PYTHON := python
VENV_DIR := .venv
VENV_PYTHON := $(VENV_DIR)/bin/python
VENV_PIP := $(VENV_PYTHON) -m pip

# Venv creation (directory as target, only runs once)
$(VENV_DIR):
	$(PYTHON) -m venv $(VENV_DIR)
	$(VENV_PYTHON) -m pip install --upgrade pip

install: $(VENV_DIR)
	$(VENV_PIP) install .

install-dev: $(VENV_DIR)
	$(VENV_PIP) install -e ".[dev]"

install-no-deps: $(VENV_DIR)
	$(VENV_PIP) install -e . --no-deps

uninstall:
	$(VENV_PIP) uninstall -y ap-<name>

clean:
	rm -rf $(VENV_DIR) build/ dist/ *.egg-info
	find . -type d -name __pycache__ -exec rm -r {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true

format: install-dev
	$(VENV_PYTHON) -m black ap_<name> tests

lint: install-dev
	$(VENV_PYTHON) -m flake8 --max-line-length=88 --extend-ignore=E203,W503 ap_<name> tests

typecheck: install-dev
	$(VENV_PYTHON) -m mypy ap_<name>

test: install-dev
	$(VENV_PYTHON) -m pytest

test-verbose: install-dev
	$(VENV_PYTHON) -m pytest -v

coverage: install-dev
	$(VENV_PYTHON) -m pytest --cov=ap_<name> --cov-report=term
```

**Design decisions:**

- `VENV_DIR` is overridable (`make VENV_DIR=../shared install-dev`) for
  monorepo shared-venv development
- `$(VENV_DIR)` as a directory target means Make only creates it once
- `PYTHON` still refers to the system python (used only for `venv` creation)
- `VENV_PYTHON` and `VENV_PIP` are used for all in-venv operations
- `clean` removes the venv alongside build artifacts

### 2. Update the Makefile standard documentation

**File:** `standards/standards/makefile.md`

- Add a **Virtual Environment** section explaining the venv pattern
- Update the Required Targets table to include the implicit `$(VENV_DIR)` target
- Update the Conventions section to document `VENV_DIR`, `VENV_PYTHON`, and
  `VENV_PIP` variables
- Update the Monorepo Development section to show the `VENV_DIR` override
  pattern for cross-project work

### 3. Update each submodule Makefile (9 submodules)

Apply the same pattern to each submodule's Makefile. Each is a mechanical
transformation:

1. Add `VENV_DIR`, `VENV_PYTHON`, `VENV_PIP` variables
2. Add `$(VENV_DIR)` creation target
3. Replace `$(PYTHON) -m pip` with `$(VENV_PIP)` in install targets
4. Replace `$(PYTHON) -m` with `$(VENV_PYTHON) -m` in all other targets
5. Change `install-dev` dependency from nothing to `$(VENV_DIR)`
6. Add `$(VENV_DIR)` removal to `clean`
7. Add `$(VENV_DIR)` to `.PHONY` exclusion (it must NOT be phony since it's a
   real directory target)

**Submodules to update:**

| # | Submodule | Notes |
|---|-----------|-------|
| 1 | `ap-common` | Straightforward |
| 2 | `ap-copy-master-to-blink` | Has extra `format-check` target (also needs `VENV_PYTHON`) |
| 3 | `ap-create-master` | Straightforward |
| 4 | `ap-cull-light` | Straightforward |
| 5 | `ap-empty-directory` | Straightforward |
| 6 | `ap-move-light-to-data` | Also has a `requirements.txt` (redundant, consider removing) |
| 7 | `ap-move-master-to-library` | Straightforward |
| 8 | `ap-move-raw-light-to-blink` | Straightforward |
| 9 | `ap-preserve-header` | Straightforward |

### 4. Update GitHub workflow templates (no changes needed)

The workflow templates already call `make install-dev` and `make test` etc.
Since the Makefile now handles venv creation internally, **no workflow changes
are required**. The `actions/setup-python` step puts the correct Python version
on `PATH`, and `python -m venv .venv` inside the Makefile will use that version.
This is one of the key benefits of this approach: CI and local dev use the
same Makefile logic.

### 5. Verify `.gitignore` coverage

All submodules already have `.venv` and `venv/` in their `.gitignore` files.
**No changes needed**, but verify during implementation.

---

## Execution Order

Since Claude Code sessions are scoped to a single repo for git push, the
implementation must be done across multiple sessions (one per submodule) or
prepared in ap-base and applied submodule-by-submodule.

**Recommended order:**

1. **`standards`** - Update template and docs first (sets the reference)
2. **`ap-common`** - Update first since other projects depend on it
3. **Remaining 8 submodules** - Can be done in any order; all are independent

Each submodule update is a single commit:
- Update `Makefile`
- Run `make clean && make default` to validate (creates venv, installs, runs
  all checks)

---

## Monorepo Development Impact

The current monorepo pattern:

```bash
cd ap-common && make install-dev
cd ../ap-copy-master-to-blink && make install-no-deps
```

installs both packages into the same environment. With per-project venvs, each
project gets its own `.venv`, so cross-project editable installs need a shared
venv. The new pattern:

```bash
# Create a shared venv at the ap-base root
python -m venv .venv

# Install into the shared venv
cd ap-common && make VENV_DIR=../.venv install-dev
cd ../ap-copy-master-to-blink && make VENV_DIR=../.venv install-no-deps
```

Document this in the updated `makefile.md` standard.

---

## Risk Assessment

- **Low risk**: Each submodule change is mechanical and isolated
- **Backward compatible in CI**: Workflows call Make targets, which now handle
  venv internally
- **Local dev impact**: Developers must run `make clean` once to reset, then
  subsequent `make` commands auto-create the venv
- **Monorepo impact**: Cross-project development requires the `VENV_DIR`
  override (document clearly)
