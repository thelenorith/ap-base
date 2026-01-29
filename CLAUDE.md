# Claude Code Context for ap-base

## Purpose

This repository serves as a monorepo aggregating all astrophotography pipeline projects as git submodules. Its primary purposes are:

1. Provide a single place to collect context for ensuring consistency across projects
2. Provide overarching documentation
3. Enable cross-project analysis and coordination

## Repository Structure

```
ap-base/
├── ap-common/           # Shared utilities and common code
├── ap-cull-lights/      # Light frame selection/culling
├── ap-fits-headers/     # FITS header management
├── ap-master-calibration/  # Master calibration frame creation
├── ap-move-calibration/ # Calibration frame organization
├── ap-move-lights/      # Light frame organization
├── legacy/
│   └── brave-new-world/ # Legacy codebase for reference
└── CLAUDE.md            # This file
```

## Upstream

- Upstream owner: `jewzaam`
- Fork owner: `thelenorith`
- All submodules reference the `thelenorith` forks

## Multi-Repo Workflow with Claude Sessions

### Limitation

Claude Code sessions are scoped to a single repository for git push access. When working from `ap-base`, changes can be analyzed and prepared for submodules, but cannot be pushed directly to them.

### Recommended Workflow

1. **Analysis session (ap-base)**: Analyze consistency issues across submodules, create GitHub issues with specific changes needed

2. **Execution session (target repo)**: Open a new session pointed at the specific submodule repo, reference the GitHub issue, implement and push changes

### Creating Cross-Repo Issues

When a session has `gh` CLI access, create issues programmatically:

```bash
gh issue create --repo thelenorith/ap-common --title "Issue title" --body "Issue body"
```

If `gh` is not available, document the needed changes in `pending-issues/` directory (see below).

## Pending Issues

When issues cannot be created directly, document them here for manual creation or future sessions.

### ap-common: Standardize Makefile to use target dependencies

**Status**: Pending

**Summary**: The Makefile in ap-common uses inline pip install commands, while all other ap-* projects use proper Makefile target dependencies.

**Current State**:
```makefile
format:
	-$(PYTHON) -m pip install -e ".[dev]" >nul 2>&1 || true
	$(PYTHON) -m black ap_common tests
```

**Desired State**:
```makefile
format: install-dev
	$(PYTHON) -m black ap_common tests
```

**Targets to update**: `format`, `lint`, `test`, `test-verbose`, `test-coverage`, `coverage`

**Also update comment** from:
```
# Testing (try to install deps, but continue if it fails - dependencies may already be installed)
```
to:
```
# Testing (install deps first, then run tests)
```

**Why**:
- More idiomatic Makefile pattern
- Cross-platform (removes Windows-style `>nul` redirect)
- Consistent with all other ap-* projects

## Consistency Standards

### Makefile Structure

All Python projects should use this Makefile pattern:

```makefile
.PHONY: install install-dev install-deps uninstall clean format lint test test-verbose test-coverage coverage default

PYTHON := python

default: format lint test coverage

install:
	$(PYTHON) -m pip install .

install-dev:
	$(PYTHON) -m pip install -e ".[dev]"

install-deps:
	$(PYTHON) -m pip install -e ".[dev]"

uninstall:
	$(PYTHON) -m pip uninstall -y <package-name>

clean:
	rm -rf build/ dist/ *.egg-info <package_name>.egg-info
	find . -type d -name __pycache__ -exec rm -r {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true

format: install-dev
	$(PYTHON) -m black <package_name> tests

lint: install-dev
	$(PYTHON) -m flake8 --jobs=1 --max-line-length=88 --extend-ignore=E203,E266,E501,W503,F401,W605,E722 <package_name> tests

test: install-dev
	$(PYTHON) -m pytest

test-verbose: install-dev
	$(PYTHON) -m pytest -v

test-coverage: install-dev
	$(PYTHON) -m pytest --cov=<package_name> --cov-report=html --cov-report=term

coverage: install-dev
	$(PYTHON) -m pytest --cov=<package_name> --cov-report=term
```

## Working with Submodules

```bash
# After cloning ap-base, initialize submodules
git submodule update --init --recursive

# Update all submodules to latest commits on their default branch
git submodule update --remote

# Pull latest for each submodule
git submodule foreach git pull origin main
```
