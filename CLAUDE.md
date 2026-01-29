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
├── pending/             # Pending changes for each submodule
├── CLAUDE.md            # This file (workflow instructions)
└── .gitmodules          # Submodule configuration
```

## Upstream

- Upstream owner: `jewzaam`
- Fork owner: `thelenorith`
- All submodules reference the `thelenorith` forks

## Multi-Repo Workflow with Claude Sessions

### Limitation

Claude Code sessions are scoped to a single repository for git push access. When working from `ap-base`, changes can be analyzed and prepared for submodules, but cannot be pushed directly to them.

### Recommended Workflow

1. **Analysis session (ap-base)**: Analyze consistency issues across submodules, document needed changes in `pending/<submodule>.md`

2. **Execution session (target repo)**: Open a new session pointed at the specific submodule repo, reference the pending file from ap-base, implement and push changes

3. **Cleanup**: After changes are merged, update or remove the corresponding pending file

### Pending Directory Structure

The `pending/` directory contains one markdown file per submodule with documented changes needed:

```
pending/
├── ap-common.md
├── ap-cull-lights.md
├── ap-fits-headers.md
├── ap-master-calibration.md
├── ap-move-calibration.md
└── ap-move-lights.md
```

Each file contains:
- Issues/changes needed for that submodule
- Current state vs desired state
- Rationale for changes
- Priority/status of each item

When working in a submodule session, read the corresponding `pending/<submodule>.md` file from ap-base for context on what needs to be done.

### Creating Cross-Repo Issues

When a session has `gh` CLI access, create issues programmatically:

```bash
gh issue create --repo thelenorith/ap-common --title "Issue title" --body "Issue body"
```

## Consistency Standards

### Required Files

All ap-* Python projects should have:

| File | Purpose |
|------|---------|
| `LICENSE` | Apache-2.0 license file |
| `README.md` | Project documentation with badges |
| `MANIFEST.in` | Package manifest for sdist |
| `Makefile` | Standard build/test targets |
| `pyproject.toml` | Project configuration |
| `.github/workflows/` | CI workflows (test, lint, format, coverage) |

### pyproject.toml Structure

```toml
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "ap-<name>"
version = "0.1.0"
description = "..."
readme = "README.md"
requires-python = ">=3.10"
license = {text = "Apache-2.0"}
authors = [
    {name = "Naveen Malik"}
]
keywords = ["astrophotography", ...]
classifiers = [
    "Development Status :: 4 - Beta",
    "Intended Audience :: Science/Research",
    "License :: OSI Approved :: Apache Software License",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
    "Programming Language :: Python :: 3.12",
    "Programming Language :: Python :: 3.13",
    "Programming Language :: Python :: 3.14",
]
```

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

### README Structure

READMEs should include:
1. Title with project name
2. Status badges (Test, Coverage, Lint, Format, Python version, code style)
3. Brief description
4. Overview section
5. Installation section (dev install, pip install from git)
6. Usage section with examples
7. Uninstallation section

Badge format:
```markdown
[![Test](https://github.com/jewzaam/<repo>/workflows/Test/badge.svg)](https://github.com/jewzaam/<repo>/actions/workflows/test.yml)
[![Coverage](https://github.com/jewzaam/<repo>/workflows/Coverage%20Check/badge.svg)](https://github.com/jewzaam/<repo>/actions/workflows/coverage.yml)
[![Lint](https://github.com/jewzaam/<repo>/workflows/Lint/badge.svg)](https://github.com/jewzaam/<repo>/actions/workflows/lint.yml)
[![Format](https://github.com/jewzaam/<repo>/workflows/Format%20Check/badge.svg)](https://github.com/jewzaam/<repo>/actions/workflows/format.yml)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)
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
