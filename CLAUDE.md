# Claude Code Context for ap-base

## Purpose

This repository serves as a monorepo aggregating all astrophotography pipeline projects as git submodules. Its primary purposes are:

1. Provide a single place to collect context for ensuring consistency across projects
2. Provide overarching documentation
3. Enable cross-project analysis and coordination

## Repository Structure

```text
ap-base/
├── ap-common/                   # Shared utilities and common code
├── ap-cull-light/               # Light frame selection/culling
├── ap-create-master/            # Master calibration frame creation
├── ap-empty-directory/          # Directory cleanup utility
├── ap-move-light-to-data/       # Light frame data migration
├── ap-move-master-to-library/   # Calibration frame organization
├── ap-move-raw-light-to-blink/  # Light frame organization
├── ap-preserve-header/          # FITS header management
├── patches/             # Git patches organized by branch name
├── standards/           # Project standards documentation
├── Makefile             # Patch application workflow
├── CLAUDE.md            # This file (workflow instructions)
├── PATCHING.md          # Detailed patching workflow documentation
└── .gitmodules          # Submodule configuration
```

## Upstream

- Upstream owner: `jewzaam`
- Fork owner: `thelenorith`
- All submodules reference the upstream `jewzaam` repos
- Patches are pushed to `thelenorith` fork branches

## Multi-Repo Workflow with Claude Sessions

### Limitation

Claude Code sessions are scoped to a single repository for git push access. When working from `ap-base`, changes can be analyzed and prepared for submodules, but cannot be pushed directly to them.

### Patch-Based Workflow

Changes for submodules are stored as git patches in `patches/`. This allows:
- Precise, reviewable diffs
- Automated application via Makefile
- Local execution bypasses session limitations

### Patches Directory

Patches are organized by branch name in subdirectories:

```text
patches/
├── readme-crosslinks-20260130/
│   ├── ap-common.patch
│   ├── ap-cull-light.patch
│   └── ...
└── makefile-fixes-20260201/
    └── ap-common.patch
```

Branch naming convention: `<description>-<YYYYMMDD>`

### Quick Reference

```bash
# Clean slate - ALWAYS start here
make deinit
make init

# Check available patches
make status
make status BRANCH=readme-crosslinks-20260130

# Apply and push patches
make apply-patches BRANCH=readme-crosslinks-20260130
make push-patches BRANCH=readme-crosslinks-20260130

# Reset submodules
make clean-patches
```

**See [PATCHING.md](PATCHING.md) for detailed workflow documentation.**

### Creating Patches (Claude Sessions)

When working in a Claude session, always start with clean submodules:

```bash
make deinit
make init
```

Then create patches following the workflow in [PATCHING.md](PATCHING.md).

## Project Standards

See [standards/](standards/index.md) for detailed documentation:

- [Project Structure](standards/project-structure.md) - Directory layout and required files
- [README Format](standards/readme-format.md) - README structure and content
- [Makefile](standards/makefile.md) - Build targets and conventions
- [GitHub Workflows](standards/github-workflows.md) - CI/CD configuration
- [Testing](standards/testing.md) - Unit testing conventions
- [CLI](standards/cli.md) - Command-line interface conventions

## Working with Submodules

```bash
# After cloning ap-base, initialize submodules
git submodule update --init --recursive

# Update all submodules to latest commits on their default branch
git submodule update --remote

# Pull latest for each submodule
git submodule foreach git pull origin main
```
