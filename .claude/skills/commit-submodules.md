# Commit Submodules Skill

## Purpose

This skill commits changes in git submodules individually, with commit messages tailored to each submodule's specific changes.

**CRITICAL:** This is for committing **submodules**, NOT the base repo (ap-base).

## When to Use

- When you have staged changes in one or more submodules
- After applying changes across multiple submodules (e.g., standards updates, type fixes)
- When you need to commit each submodule with its own appropriate message

## When NOT to Use

- When committing changes to the base repo (ap-base) itself
- When committing submodule pointer updates (use regular `/commit` for that)
- When changes are not yet staged in submodules

## Process

### 1. List all submodules

```bash
# List all submodule paths
git submodule foreach 'echo $path'
```

### 2. For EACH submodule, check and commit if needed

For each submodule path from step 1:

1. `cd` into the submodule
2. Run `git status --short` to check for staged changes
3. If no staged changes (empty output), skip to next submodule
4. If staged changes exist (output shows M, A, D, R, C, or U in first column), proceed with review and commit

### 3. Review submodule's changes

For each submodule:

```bash
cd <submodule-name>
git status                 # See staged files
git diff --staged          # See actual changes
git log -3 --oneline       # Understand commit style
```

### 4. Write submodule-specific commit message

**CRITICAL:** Use ONLY the changes from THIS submodule's diff, not changes from other submodules.

**Title:** Less than 80 characters, imperative mood, no period

**Body:** Bulleted list of changes specific to THIS submodule:
- Focus on what changed in THIS submodule
- Don't mention changes from other submodules
- Don't mention tests (assumed)
- Be specific to the functionality added/fixed/changed

### 5. Commit with attribution

```bash
cd <submodule-name>
git commit -m "$(cat <<'EOF'
Short title specific to this submodule (< 80 chars)

- First change in this submodule
- Second change in this submodule
- Third change in this submodule

Assisted-by: Claude Code (Claude Sonnet 4.5)
EOF
)"
```

### 6. Verify and report

After each commit:

```bash
git status
```

Report any unstaged changes.

## Critical Rules

- **NEVER run `git add`** - only commit what's already staged
- **NEVER push** - user does this explicitly
- **NEVER use `--amend`** unless explicitly requested
- **NEVER mix changes from different submodules** in commit messages
- **ALWAYS cd into each submodule** before reviewing and committing
- **ALWAYS return to base repo** after committing all submodules

## Example Workflow

```bash
# List all submodules
git submodule foreach 'echo $path'
# Output: ap-common, ap-cull-light, ap-preserve-header, etc.

# Check ap-common
cd ap-common
git status --short
# Output shows staged changes
git diff --staged
# Review changes, write commit message based on ap-common changes only
git commit -m "..."
cd ..

# Check ap-cull-light
cd ap-cull-light
git status --short
# No staged changes, skip
cd ..

# Check ap-preserve-header
cd ap-preserve-header
git status --short
# Output shows staged changes
git diff --staged
# Review changes, write commit message based on ap-preserve-header changes only
git commit -m "..."
cd ..

# ... repeat for all submodules
```

## Committing Base Repo vs Submodules

### Committing Submodules (THIS skill)
- Changes are IN the submodule directories
- Each submodule gets its own commit
- `cd` into each submodule to commit
- Commit messages describe changes to that specific submodule

### Committing Base Repo (use regular `/commit`)
- Changes are in ap-base root (e.g., CLAUDE.md, PATCHING.md, standards/)
- OR submodule pointer updates (when submodules have new commits)
- Commit from ap-base root directory
- Commit message describes changes to base repo or which submodules were updated

## Common Commit Message Patterns

### Adding typecheck workflow
```
Add typecheck workflow and fix type annotations

- Add typecheck.yml GitHub workflow for mypy type checking
- Pin mypy to version 1.11.2 in pyproject.toml
- Fix [specific type issues found in this submodule]
```

### Adding __main__ entry point
```
Add __main__ entry point for python -m invocation

- Add __main__.py entry point for python -m <package> invocation
- [Other changes specific to this submodule]
```

### Standards compliance
```
Apply project standards to [specific area]

- Standardize workflow triggers to [main] only
- Fix MANIFEST.in to include LICENSE
- Remove obsolete requirements.txt
```

## Attribution

Always end commit messages with:

```
Assisted-by: Claude Code (Claude Sonnet 4.5)
```

## After All Submodules Committed

1. Return to base repo: `cd` to ap-base root
2. Report summary of all commits made
3. Note which submodules are ahead of their remotes
4. Remind user they need to push each submodule separately (or use git submodule foreach)
