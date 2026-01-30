# Makefile Standards

Standard Makefile targets for ap-* Python projects.

## Required Targets

| Target | Description |
|--------|-------------|
| `default` | Run format, lint, typecheck, test, coverage |
| `install` | Install package |
| `install-dev` | Install in editable mode with dev deps |
| `uninstall` | Uninstall package |
| `clean` | Remove build artifacts |
| `format` | Format code with black |
| `lint` | Lint with flake8 |
| `typecheck` | Type check with mypy |
| `test` | Run pytest |
| `coverage` | Run pytest with coverage |

## Template

```makefile
.PHONY: install install-dev uninstall clean format lint typecheck test test-verbose coverage default

PYTHON := python

default: format lint typecheck test coverage

install:
	$(PYTHON) -m pip install .

install-dev:
	$(PYTHON) -m pip install -e ".[dev]"

uninstall:
	$(PYTHON) -m pip uninstall -y ap-<name>

clean:
	rm -rf build/ dist/ *.egg-info
	find . -type d -name __pycache__ -exec rm -r {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true

format: install-dev
	$(PYTHON) -m black ap_<name> tests

lint: install-dev
	$(PYTHON) -m flake8 --max-line-length=88 --extend-ignore=E203,W503 ap_<name> tests

typecheck: install-dev
	$(PYTHON) -m mypy ap_<name>

test: install-dev
	$(PYTHON) -m pytest

test-verbose: install-dev
	$(PYTHON) -m pytest -v

coverage: install-dev
	$(PYTHON) -m pytest --cov=ap_<name> --cov-report=term
```

## Conventions

### PYTHON variable

Use `$(PYTHON)` instead of hardcoding `python` or `python3`:

```makefile
PYTHON := python
```

### Dependencies

Targets that need the package installed should depend on `install-dev`:

```makefile
format: install-dev
	$(PYTHON) -m black ap_<name> tests
```

### Quiet failures in clean

Use `|| true` for commands that might fail during cleanup:

```makefile
find . -type d -name __pycache__ -exec rm -r {} + 2>/dev/null || true
```

### Line length

Match black's default of 88 characters:

```makefile
--max-line-length=88
```

## What to Avoid

- Complex shell logic
- Platform-specific commands without fallbacks
- Hardcoded paths
- Targets that modify git state
