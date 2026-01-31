# GitHub Workflows

Standard CI workflows for ap-* projects.

## Required Workflows

| Workflow | File | Trigger |
|----------|------|---------|
| Test | `test.yml` | push, PR |
| Lint | `lint.yml` | push, PR |
| Typecheck | `typecheck.yml` | push, PR |
| Format Check | `format.yml` | push, PR |
| Coverage | `coverage.yml` | push, PR |

## test.yml

```yaml
name: Test

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.10", "3.11", "3.12", "3.13", "3.14"]

    steps:
      - uses: actions/checkout@v4
        with:
          lfs: true

      - name: Set up Python ${{ matrix.python-version }}
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}

      - name: Install dependencies
        run: make install-dev

      - name: Run tests
        run: make test
```

## lint.yml

```yaml
name: Lint

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Install dependencies
        run: make install-dev

      - name: Run linter
        run: make lint
```

## typecheck.yml

```yaml
name: Typecheck

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  typecheck:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Install dependencies
        run: make install-dev

      - name: Run type checker
        run: make typecheck
```

## format.yml

```yaml
name: Format Check

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  format:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Install dependencies
        run: make install-dev

      - name: Check formatting
        run: $(PYTHON) -m black --check ap_<name> tests
```

## coverage.yml

```yaml
name: Coverage Check

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  coverage:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Install dependencies
        run: make install-dev

      - name: Run coverage
        run: make coverage
```

## Conventions

### Python versions

Test on Python 3.10 through 3.14. Use 3.12 for single-version jobs (lint, format, coverage).

### Actions versions

Use current major versions:
- `actions/checkout@v4`
- `actions/setup-python@v5`

### Triggers

Run on push to main and all PRs to main:

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```

### Use Makefile targets

Workflows should call Makefile targets, not duplicate commands:

```yaml
- name: Run tests
  run: make test
```

### Git LFS

For projects with test fixtures tracked in Git LFS (e.g., FITS/XISF files), add `lfs: true` to the checkout step in test.yml:

```yaml
- uses: actions/checkout@v4
  with:
    lfs: true
```

This ensures fixture files are downloaded rather than just their LFS pointer files.
