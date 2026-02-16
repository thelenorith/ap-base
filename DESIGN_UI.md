# UI Design: ap-ui

## 1. Overview

### Problem Statement

The astrophotography pipeline consists of 8 independent CLI tools that must be run
in a specific sequence with correct arguments. Today this requires:

- Remembering the tool order and dependencies between stages
- Manually constructing CLI commands with correct directory paths
- No visibility into pipeline state (what's been processed, what's pending)
- No persistent configuration (paths re-entered every session)
- Interactive prompts (ap-cull-light, ap-copy-master-to-blink) break automation

### Goals

| Priority | Goal |
|----------|------|
| P0 | One-click workflow orchestration (run pipeline stages in order with progress) |
| P0 | Persistent configuration of directory paths and tool options |
| P0 | Visual progress and status for running tools |
| P1 | Pipeline state visibility (what stages are complete, what's pending) |
| P1 | Dry-run preview before committing operations |
| P2 | Metadata browsing (frame counts, calibration coverage, gaps) |
| P2 | History/log of past runs |

### Non-Goals

- Image preview or FITS viewer (use PixInsight for visual inspection)
- Multi-user or remote access
- Replacing PixInsight for processing (stages 30-60)
- Real-time capture monitoring (NINA handles this)

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   ap-ui (PySide6)                    │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌───────────────────┐ │
│  │ Workflow  │  │  Config   │  │   Status/Progress │ │
│  │  Engine   │  │  Manager  │  │      Display      │ │
│  └────┬─────┘  └─────┬────┘  └─────────┬─────────┘ │
│       │               │                 │           │
│  ┌────┴───────────────┴─────────────────┴────┐      │
│  │            Tool Runner Layer               │      │
│  │  (subprocess now → Python API later)       │      │
│  └────────────────────┬──────────────────────┘      │
└───────────────────────┼─────────────────────────────┘
                        │
          ┌─────────────┼─────────────────┐
          │             │                 │
    ┌─────┴──────┐ ┌───┴────┐ ┌─────────┴──────┐
    │ ap-common  │ │ ap-*   │ │  PixInsight    │
    │ (library)  │ │ tools  │ │  (binary)      │
    └────────────┘ └────────┘ └────────────────┘
```

**Key architectural decision**: The UI communicates with tools through a **Tool
Runner** abstraction layer. This allows starting with subprocess/CLI invocation
today, then migrating to a formal Python API when the tools expose one — without
changing any UI code.

---

## 3. Technology Choices

### GUI Framework: PySide6

PySide6 (Qt for Python) is the recommended framework.

| Factor | PySide6 | PyQt6 | Tkinter |
|--------|---------|-------|---------|
| License | LGPL (flexible) | GPL (restrictive) | PSF (stdlib) |
| Backing | Qt Company (official) | Riverbank (independent) | Python core |
| Widget set | Comprehensive | Comprehensive | Limited |
| Look & feel | Native | Native | Dated |
| Packaging | pyside6-deploy + PyInstaller | PyInstaller only | PyInstaller |
| Cross-platform | Windows + Linux + macOS | Windows + Linux + macOS | Windows + Linux + macOS |

**Rationale**: LGPL licensing is cleanest for an open-source GitHub project. Official
Qt Company backing ensures long-term maintenance. API is 99%+ identical to PyQt6 if
a switch is ever needed.

### Language: Python

The UI is written in Python. All pipeline tools are Python. Shared constants,
metadata types, and configuration schemas can be defined in ap-common and consumed
by both the CLI and UI without duplication.

However, the UI does **not** directly import tool internals. It depends on:

- **ap-common** — for shared constants, type definitions, and (future) API schemas
- **Tool CLIs** — invoked as subprocesses (phase 1)
- **Tool public APIs** — called as Python functions (phase 2, when tools expose them)

This boundary is critical: tool internals (modules within `ap_cull_light/`,
`ap_create_master/`, etc.) may change in breaking ways within a semver version.
Only the published CLI interface and (future) public API are stable contracts.

### Target OS

- **Windows**: Primary. NINA and PixInsight run here.
- **Linux**: Secondary. PixInsight runs well on Linux. PySide6 is cross-platform.

---

## 4. Tool Integration Strategy

### Phase 1: CLI Subprocess (No Tool Changes Required)

The UI invokes tools as subprocess commands, exactly as a user would type them.

```python
# Conceptual example — not prescriptive implementation
class CliToolRunner:
    def run(self, tool: str, args: list[str],
            on_output: Callable[[str], None]) -> int:
        """Run a tool as a subprocess, streaming output."""
        cmd = [sys.executable, "-m", tool] + args
        process = subprocess.Popen(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, bufsize=1
        )
        for line in process.stdout:
            on_output(line.rstrip())
        return process.wait()
```

**Advantages**:

- Works today with zero tool changes
- Tools behave identically to manual CLI invocation
- `--dryrun` works naturally

**Limitations**:

- Progress is text-based (parse stdout for progress bars)
- Structured results require parsing CLI output
- Interactive prompts (ap-cull-light confirmation, ap-copy-master-to-blink picker)
  cannot be answered programmatically

**Mitigations for interactive tools**:

| Tool | Interactive Element | Workaround |
|------|-------------------|------------|
| ap-cull-light | Confirmation prompt per batch | Use `--auto-accept-percent` to bypass. UI shows summary and user confirms via GUI before running without `--dryrun`. |
| ap-copy-master-to-blink | Flat date picker | Use `--flat-state` with a pre-built YAML file. UI presents the flat date choices via native widgets instead. |

### Phase 2: Public Python API (Requires Tool Changes)

When tools expose a formal public API, the UI calls functions directly.

```python
# Conceptual example of what a tool API could look like
# Defined in each tool's public API surface

@dataclass
class CullResult:
    rejected: list[FrameInfo]
    accepted: list[FrameInfo]
    rejection_percent: float

def cull_lights(
    source_dir: Path,
    reject_dir: Path,
    max_hfr: float | None = None,
    max_rms: float | None = None,
    dryrun: bool = False,
    progress_callback: Callable[[int, int], None] | None = None,
) -> CullResult:
    ...
```

**Advantages**:

- Structured return values (dataclasses, not parsed text)
- Native progress callbacks (feed directly into Qt progress bars)
- No subprocess overhead
- Type safety

**What this requires from each tool** (see Section 5):

- A public API module with stable function signatures
- Dataclass return types for results
- Optional progress callback parameters
- Separation of "business logic" from "CLI presentation"

### Tool Runner Abstraction

The UI defines an abstract interface so the transition from Phase 1 to Phase 2
is invisible to the rest of the application:

```python
class ToolRunner(Protocol):
    def move_raw_lights(self, source: Path, dest: Path, *,
                        dryrun: bool = False,
                        on_progress: ProgressCallback | None = None
                        ) -> ToolResult: ...

    def cull_lights(self, source: Path, reject: Path, *,
                    max_hfr: float | None = None,
                    max_rms: float | None = None,
                    dryrun: bool = False,
                    on_progress: ProgressCallback | None = None
                    ) -> ToolResult: ...

    # ... one method per tool
```

Two implementations: `CliToolRunner` (phase 1) and `ApiToolRunner` (phase 2).

---

## 5. Impact on Existing Tools

### Required Changes (Phase 1 — CLI subprocess)

**No changes required to tool code.** The UI works with the current CLI interfaces.

Minor quality-of-life improvements that would help (but are not blockers):

| Tool | Improvement | Benefit |
|------|-------------|---------|
| All tools | Exit code consistency (all return 0/1) | UI can reliably detect success/failure |
| All tools | Machine-readable summary line on stdout | Easier to parse results |
| ap-cull-light | `--yes` or `--no-prompt` flag | Skip interactive confirmation |
| ap-copy-master-to-blink | `--no-prompt` flag | Skip interactive flat picker |

### Required Changes (Phase 2 — Python API)

Each tool needs a **public API module** alongside its CLI module:

```
ap-cull-light/
├── ap_cull_light/
│   ├── __init__.py
│   ├── api.py           # NEW: Public API with stable signatures
│   ├── cull_lights.py   # Existing: CLI entry point (calls api.py)
│   └── ...
```

The refactoring pattern for each tool:

1. Extract core logic from `main()` into a function with typed parameters and
   return value
2. Have `main()` call the new function (CLI becomes a thin wrapper)
3. Mark `api.py` as the public interface; everything else is internal
4. Add `progress_callback` parameter for UI integration

**ap-common changes**:

- Define shared types: `FrameInfo`, `ToolResult`, `ProgressCallback`
- Define shared configuration schema (see Section 7)
- These types are the contract between tools and UI

### Scope of Phase 2 Refactoring Per Tool

| Tool | Complexity | Notes |
|------|-----------|-------|
| ap-empty-directory | Low | Simple operation, minimal state |
| ap-preserve-header | Low | Single function, clear inputs/outputs |
| ap-move-raw-light-to-blink | Low | Scan + move, well-structured already |
| ap-move-master-to-library | Low | Scan + move, similar pattern |
| ap-cull-light | Medium | Interactive confirmation needs alternative path |
| ap-move-light-to-data | Medium | Matching logic + conditional moves |
| ap-copy-master-to-blink | Medium | Interactive picker, flat state management |
| ap-create-master | High | PixInsight subprocess, multi-phase, polling |

---

## 6. UI Application Design

### Main Window Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  ap-ui                                               [─] [□] [×]│
├───────────────┬─────────────────────────────────────────────────┤
│               │                                                 │
│  WORKFLOW     │  STAGE DETAIL                                   │
│  ─────────    │  ──────────────                                 │
│               │                                                 │
│  ● Preserve   │  ap-move-raw-light-to-blink                     │
│    Headers    │                                                 │
│  ● Move Raw   │  Source: /capture/tonight          [Browse]     │
│    Lights  ◄──│  Dest:   /data/astrophotography    [Browse]     │
│  ○ Cull       │                                                 │
│    Lights     │  Options:                                       │
│  ○ Create     │  ☑ Create accept directories                    │
│    Masters    │  Blink dir name: [10_Blink        ]             │
│  ○ Organize   │                                                 │
│    Library    │  ┌─────────────────────────────────────────┐    │
│  ○ Copy       │  │  Ready to run.                          │    │
│    Masters    │  │  Source: 47 FITS files found             │    │
│  ○ Move to    │  │  Dest: directory exists                  │    │
│    Data       │  └─────────────────────────────────────────┘    │
│  ○ Cleanup    │                                                 │
│               │  [▶ Run]  [👁 Dry Run]  [⏭ Run All Remaining]   │
│  ─────────    │                                                 │
│  PROFILES     │  OUTPUT LOG                                     │
│  ─────────    │  ──────────────                                 │
│  Nightly      │  ┌─────────────────────────────────────────┐    │
│  Calibration  │  │ Processing files  [████████░░]  80%     │    │
│  Full Run     │  │ Moved image_001.fits → 10_Blink/M31/.. │    │
│               │  │ Moved image_002.fits → 10_Blink/M31/.. │    │
│               │  │ ...                                     │    │
│               │  └─────────────────────────────────────────┘    │
│               │                                                 │
└───────────────┴─────────────────────────────────────────────────┘
```

### Panel Descriptions

**Left Panel — Workflow Steps**:

- Vertical list of pipeline stages in execution order
- Status indicators: ● complete, ◄ current/selected, ○ pending, ✕ failed
- Click a stage to view its configuration in the detail panel
- "Run All Remaining" executes from current stage through the end

**Left Panel — Profiles** (below workflow):

- Named configurations: "Nightly", "Calibration Only", "Full Pipeline"
- Each profile stores: which stages to run, directory paths, tool options
- Quick-switch between imaging sessions or equipment configurations

**Right Panel — Stage Detail** (top):

- Shows the selected stage's configuration
- Directory path inputs with Browse buttons
- Tool-specific options as native widgets (checkboxes, spinners, dropdowns)
- Pre-run validation: file counts, directory existence checks
- Dry-run preview

**Right Panel — Output Log** (bottom):

- Streaming stdout/stderr from the running tool
- Progress bar (parsed from tool output in phase 1, native callback in phase 2)
- Scrollable log with timestamps
- Copy-to-clipboard for error reporting

### Workflow Engine

The workflow engine manages stage execution:

```python
@dataclass
class StageConfig:
    tool: str                          # e.g., "ap_move_raw_light_to_blink"
    args: dict[str, Any]               # Resolved arguments
    enabled: bool = True               # Skip this stage if False
    stop_on_error: bool = True         # Halt pipeline on failure

@dataclass
class StageResult:
    exit_code: int
    stdout: str
    duration_seconds: float
    skipped: bool = False

class WorkflowEngine:
    stages: list[StageConfig]

    async def run_stage(self, index: int) -> StageResult: ...
    async def run_remaining(self, from_index: int) -> list[StageResult]: ...
    async def run_all(self) -> list[StageResult]: ...
    def cancel(self) -> None: ...
```

**Key behaviors**:

- Stages run sequentially (pipeline has strict ordering)
- Each stage runs in a background thread (QThread) to keep UI responsive
- Output streams to the log panel in real time
- Cancel button sends SIGTERM/SIGINT to the subprocess
- Failed stage halts the pipeline (configurable per-profile)
- Manual review points (blinking between cull and move-to-data) pause the
  pipeline and prompt the user to continue

### Stage Definitions

The pipeline defines these stages in order. Users can enable/disable stages
per profile.

| # | Stage | Tool | Required Inputs | Notes |
|---|-------|------|-----------------|-------|
| 1 | Preserve Light Headers | ap-preserve-header | raw_dir, include_keys | Optional but recommended |
| 2 | Move Raw Lights | ap-move-raw-light-to-blink | source_dir, dest_dir | — |
| 3 | Cull Lights | ap-cull-light | source_dir, reject_dir, thresholds | Auto-accept or GUI confirm |
| 4 | Manual Blink Review | (pause) | — | User reviews in PixInsight, moves to accept/ |
| 5 | Preserve Cal Headers | ap-preserve-header | cal_raw_dir, include_keys | Same tool, different input |
| 6 | Create Masters | ap-create-master | cal_input, cal_output, pi_binary | Longest stage |
| 7 | Organize Library | ap-move-master-to-library | source_dir, library_dir | — |
| 8 | Cleanup Cal Output | ap-empty-directory | cal_output_dir | Optional |
| 9 | Copy Masters to Blink | ap-copy-master-to-blink | library_dir, blink_dir | Flat state managed by UI |
| 10 | Move Lights to Data | ap-move-light-to-data | blink_dir, data_dir | Only moves when cal available |

---

## 7. Configuration and State

### Configuration File Format: YAML

A single YAML file stores all persistent settings. Location:

- **Windows**: `%APPDATA%/ap-ui/config.yaml`
- **Linux**: `~/.config/ap-ui/config.yaml`

```yaml
# ap-ui configuration
version: 1

# Global directories (used as defaults across profiles)
directories:
  raw_lights: "D:/Capture/Lights"
  raw_calibration: "D:/Capture/Calibration"
  data_root: "E:/Astrophotography"
  reject: "E:/Astrophotography/Reject"
  calibration_output: "D:/Calibration/Output"
  calibration_library: "E:/Calibration/Library"
  pixinsight_binary: "C:/Program Files/PixInsight/bin/PixInsight.exe"

# Named profiles
profiles:
  nightly:
    description: "Standard nightly light processing"
    stages:
      preserve_light_headers:
        enabled: true
        include_keys: ["CAMERA", "OPTIC", "FILTER"]
      move_raw_lights:
        enabled: true
      cull_lights:
        enabled: true
        max_hfr: 2.5
        max_rms: 2.0
        auto_accept_percent: 5.0
      manual_blink:
        enabled: true
      preserve_cal_headers:
        enabled: false
      create_masters:
        enabled: false
      organize_library:
        enabled: false
      cleanup_cal_output:
        enabled: false
      copy_masters:
        enabled: false
      move_to_data:
        enabled: false

  calibration:
    description: "Calibration frame processing"
    stages:
      preserve_light_headers:
        enabled: false
      move_raw_lights:
        enabled: false
      cull_lights:
        enabled: false
      manual_blink:
        enabled: false
      preserve_cal_headers:
        enabled: true
        include_keys: ["CAMERA", "OPTIC", "FILTER"]
      create_masters:
        enabled: true
        script_only: false
      organize_library:
        enabled: true
      cleanup_cal_output:
        enabled: true
      copy_masters:
        enabled: true
        scale_dark: false
      move_to_data:
        enabled: true
        scale_dark: false

  full_run:
    description: "Complete pipeline end-to-end"
    # All stages enabled with defaults from global directories
```

### Run History

Each pipeline run is logged to a history file for auditability.

```yaml
# ~/.config/ap-ui/history/2026-02-15T22-30-00.yaml
profile: nightly
started: "2026-02-15T22:30:00"
completed: "2026-02-15T22:35:12"
stages:
  - name: move_raw_lights
    exit_code: 0
    duration_seconds: 45.2
    summary: "Moved 47 files"
  - name: cull_lights
    exit_code: 0
    duration_seconds: 12.1
    summary: "Rejected 3/47 (6.4%)"
```

---

## 8. Repository Structure

The UI lives in a **separate repository**: `ap-ui`.

```
ap-ui/
├── pyproject.toml           # PySide6, ap-common dependency
├── CLAUDE.md
├── README.md
├── Makefile                 # test, lint, format, typecheck, run
├── src/
│   └── ap_ui/
│       ├── __init__.py
│       ├── __main__.py      # Entry point
│       ├── app.py           # QApplication setup
│       ├── config.py        # YAML config load/save
│       ├── runner/
│       │   ├── __init__.py
│       │   ├── base.py      # ToolRunner protocol
│       │   ├── cli.py       # Phase 1: subprocess runner
│       │   └── api.py       # Phase 2: direct API runner (future)
│       ├── workflow/
│       │   ├── __init__.py
│       │   ├── engine.py    # Stage sequencing and execution
│       │   ├── stages.py    # Stage definitions
│       │   └── history.py   # Run history logging
│       ├── widgets/
│       │   ├── __init__.py
│       │   ├── main_window.py
│       │   ├── workflow_panel.py
│       │   ├── stage_detail.py
│       │   ├── output_log.py
│       │   ├── profile_selector.py
│       │   └── directory_picker.py
│       └── resources/
│           └── icons/       # Stage status icons
├── tests/
│   ├── test_config.py
│   ├── test_engine.py
│   ├── test_cli_runner.py
│   └── test_stages.py
└── .github/
    └── workflows/
        └── ci.yml
```

### Dependencies

```toml
[project]
name = "ap-ui"
requires-python = ">=3.10"
dependencies = [
    "PySide6>=6.6",
    "PyYAML>=6.0",
    "ap-common @ git+https://github.com/jewzaam/ap-common.git",
]

[project.scripts]
ap-ui = "ap_ui.__main__:main"

[project.optional-dependencies]
dev = [
    "pytest",
    "pytest-cov",
    "pytest-mock",
    "pytest-qt",       # PySide6/PyQt testing
    "black",
    "flake8",
    "mypy",
]
```

### Why ap-common Is a Dependency

The UI imports ap-common for:

- **Constants** (`constants.py`): Frame types, header keys, normalized names.
  These define the domain vocabulary shared between tools and UI.
- **Type definitions** (future): Shared dataclasses for `FrameInfo`, metadata
  structures, calibration matching results.
- **Configuration schema** (future): If ap-common defines a standard config
  format, the UI can validate against it.

The UI does **not** import:
- `ap_common.fits` (no direct FITS reading)
- `ap_common.filesystem` (no direct file operations)
- `ap_common.metadata` (tools handle this internally)

If ap-common exposes types needed by the API layer, the UI depends on those types.
If ap-common never exposes such types, the UI can define its own or remove the
dependency entirely.

---

## 9. Implementation Phases

### Phase 1: MVP with CLI Subprocess (~3 sprints)

**Goal**: Working desktop app that orchestrates the pipeline via CLI commands.

**Sprint 1 — Skeleton**:
- PySide6 main window with workflow panel and stage detail
- YAML config load/save
- Directory picker widgets with validation
- Single-stage execution via subprocess (ap-empty-directory as simplest test)

**Sprint 2 — Full Pipeline**:
- All 10 stages defined with their configuration widgets
- Sequential stage execution with progress and output streaming
- Profile management (create, edit, switch)
- Dry-run support

**Sprint 3 — Polish**:
- Pre-run validation (directory existence, file counts)
- Cancel running stage
- Run history logging
- Error handling and user-friendly messages
- Windows packaging with PyInstaller or pyside6-deploy

### Phase 2: API Integration (~2 sprints per tool group)

**Prerequisites**: Tools expose public API modules (see Section 5).

**Work per tool**:
1. Implement `ApiToolRunner` method for that tool
2. Structured return values → richer UI display
3. Progress callbacks → native progress bars
4. Remove stdout parsing fallback for that tool

**Priority order** (easiest to highest value):
1. ap-empty-directory, ap-preserve-header (simple, low risk)
2. ap-move-raw-light-to-blink, ap-move-master-to-library (scan + move)
3. ap-cull-light, ap-move-light-to-data (matching logic)
4. ap-copy-master-to-blink (interactive picker → native UI)
5. ap-create-master (PixInsight integration, most complex)

### Phase 3: Enhanced Features (future)

- Metadata browser panel (frame counts per target/filter/date)
- Calibration coverage matrix (which masters exist for which lights)
- Batch scheduling (queue multiple sessions)
- System tray mode (minimize, notify on completion)
- Notification on pipeline completion (toast/sound)

---

## 10. Open Questions

| # | Question | Impact | Current Assumption |
|---|----------|--------|--------------------|
| 1 | Where does the API layer live? In each tool's repo, or centralized in ap-common? | Determines dependency graph for phase 2 | Each tool owns its own API module |
| 2 | Should ap-common publish shared types (FrameInfo, ToolResult) for API consumers? | UI type safety, cross-tool consistency | Yes, ap-common defines shared types |
| 3 | How should the UI handle the manual blink step? Timer? Button? Filesystem watch? | UX for the pause between cull and move-to-data | Button: "I've finished blinking, continue" |
| 4 | Should profiles support per-stage directory overrides, or only global directories? | Config complexity vs. flexibility | Global directories with per-stage overrides possible |
| 5 | Should the UI manage virtual environments / tool installation, or assume tools are pre-installed? | Onboarding complexity | Tools are pre-installed in the Python environment |
| 6 | What is the versioning relationship between ap-ui and the tools? | Compatibility matrix | ap-ui is version-independent; CLI interface is stable |
| 7 | Should the flat date picker (ap-copy-master-to-blink) be reimplemented as a native Qt dialog? | Better UX but duplicates logic | Yes, for phase 2. Phase 1 uses --flat-state YAML |
| 8 | Should ap-ui be added as a submodule in ap-base for cross-project coordination? | Visibility and documentation | No — separate repo, referenced in ap-base README |

---

## 11. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| CLI output format changes break parsing | Medium | Low | Phase 1 parsing is best-effort; phase 2 eliminates it |
| PySide6 packaging issues on Windows | Low | Medium | Test packaging early in sprint 1; fall back to PyInstaller |
| Tool API design delays phase 2 | High | Medium | Phase 1 is fully functional without APIs |
| PixInsight binary path differences across OS | Low | Low | Config stores per-machine path; UI validates existence |
| Qt event loop + subprocess interaction | Low | High | Use QThread for subprocess execution, signal/slot for UI updates |

---

## 12. Summary of Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Language | Python | Same as all tools; shared types possible |
| Framework | PySide6 | LGPL license, official Qt backing, cross-platform |
| Tool integration (initial) | CLI subprocess | Zero tool changes required |
| Tool integration (future) | Python API | Structured results, progress callbacks |
| Configuration | YAML file | Human-readable, already used by ap-copy-master-to-blink |
| Repository | Separate repo (ap-ui) | Independent release cycle, clean dependency graph |
| Target OS | Windows primary, Linux secondary | Matches NINA + PixInsight deployment |
| Image preview | Not included | PixInsight handles visual inspection |
