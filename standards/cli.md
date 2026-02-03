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
| `--quiet` | `-q` | flag | Suppress non-essential output (see below) |

### `--quiet` Flag Behavior

The `--quiet` flag enables minimal output mode for scripting, automation, and clean logging.

**Suppressed when `--quiet` is set:**

| Output Type | Examples |
|-------------|----------|
| Progress indicators | Progress bars, spinners, percentage counters |
| INFO-level logging | "Starting processing", "Found N files" |
| Summary statistics | "Processed 42 files successfully" |

**Never suppressed (always shown):**

| Output Type | Rationale |
|-------------|-----------|
| WARNING messages | Indicate potential issues requiring attention |
| ERROR messages | Critical for diagnosing failures |
| Exit codes | Required for scripting and automation |
| Dry-run output | User explicitly requested this information |

**Use cases:**

- Scripting/automation requiring minimal output
- Cron jobs avoiding unnecessary email notifications
- File logging where progress bars create unwanted artifacts
- CI/CD pipelines with cleaner logs

See [Logging and Progress Standards](logging-progress.md) for implementation patterns.

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
