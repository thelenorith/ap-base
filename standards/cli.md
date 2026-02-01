# CLI Standards

Command-line interface conventions for ap-* tools.

## Options

| Type | Example | Rule |
|------|---------|------|
| Single concept | `--dryrun`, `--debug` | No hyphens |
| Qualified/compound | `--no-overwrite`, `--blink-dir` | Hyphen separates qualifier |

## Required Options

All CLI tools must support:

| Option | Short | Type | Description |
|--------|-------|------|-------------|
| `--debug` | | flag | Enable debug output |
| `--dryrun` | | flag | Perform dry run without side effects |
| `--quiet` | `-q` | flag | Suppress progress output |

## Option Naming

| Pattern | Example | Use |
|---------|---------|-----|
| `--<word>` | `--debug`, `--dryrun` | Single-concept flags |
| `--no-<feature>` | `--no-overwrite`, `--no-accept` | Disable default behavior |
| `--<qualifier>-dir` | `--blink-dir`, `--accept-dir` | Directory paths |

## Positional Arguments

Source and destination directories are positional, not options.

## Help Text

| Rule | Example |
|------|---------|
| Start with lowercase | `help="enable debug output"` |
| No period at end | `help="source directory"` |
| Under 60 characters | Keep it brief |

## Exit Codes

Define as module-level constants with `EXIT_` prefix:

| Constant | Value | Meaning |
|----------|-------|---------|
| `EXIT_SUCCESS` | 0 | Success |
| `EXIT_ERROR` | 1 | Error |
