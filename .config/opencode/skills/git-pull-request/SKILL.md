---
name: git-pull-request
description: How to create and manage pull requests in github using gh CLI.
---

# Git Pull Request Skill

Create GitHub pull requests using the `gh` CLI tool with parallel context gathering for efficiency.

---

## PHASE 1: Parallel Context Gathering (MANDATORY FIRST STEP)

Execute ALL of the following commands IN PARALLEL to minimize latency:

### Group 1: Repository State
```bash
git status
git branch --show-current
git log --oneline -10
```

### Group 2: Change Analysis
```bash
git diff main...HEAD --stat
git diff main...HEAD
git log main..HEAD --format='%h %s%n%b'
git remote get-url origin
```

**Capture these data points simultaneously:**
1. Working tree status (clean or dirty)
2. Current branch name
3. Recent commit history for context
4. Files changed (diff stats)
5. Full diff content
6. Commits on this branch (hash, subject, body)
7. Remote repository URL

---

## PHASE 2: Branch Status Check

Check if branch is tracking remote and push status:

```bash
git branch -vv | grep "<current-branch>"
```

**Determine:**
- Is branch tracking a remote?
- Is branch ahead/behind remote?
- Does branch need to be pushed?

---

## PHASE 3: Push Branch (If Needed)

If branch is not pushed or needs updating:

```bash
git push -u origin <branch-name>
```

**Notes:**
- Use `-u` flag to set upstream tracking
- If already pushed and up-to-date, this is a no-op

---

## PHASE 4: Create Pull Request

Use `gh pr create` with heredoc for the body to ensure proper formatting:

```bash
gh pr create --title "<PR Title>" --body "$(cat <<'EOF'
## Summary

- <bullet point 1>
- <bullet point 2>
- <bullet point 3>

## Changes

<Description of what changed and why>

1. **Section 1**: <description>
2. **Section 2**: <description>
3. **Section 3**: <description>
EOF
)" --base main
```

**Critical:**
- Use `<<'EOF'` (with quotes) to prevent variable expansion in the heredoc
- The `--base` flag specifies the target branch (usually `main`)
- Title should be concise and descriptive
- Body uses markdown formatting

---

## PR Body Structure

### Summary Section
- 1-3 bullet points capturing the high-level changes
- Focus on **what** and **why**

### Changes Section
- Detailed description of modifications
- Numbered list for multiple distinct changes
- Use bold for section/file names
- Use regular bullet points, never checkboxes

---

## IMPORTANT: No Checkboxes

**NEVER use checkboxes (`- [ ]` or `- [x]`) in PR bodies.**

Checkboxes require manual updating after PR creation which is tedious and gets ignored. Use regular bullet points instead.

---

## Error Handling

### Branch not pushed
```
Branch needs to be pushed first:
git push -u origin <branch-name>
```

### PR already exists
Check first:
```bash
gh pr list --head <branch-name>
```

### Not on a feature branch
```
You're on main/master. Checkout a feature branch first.
```

### No commits ahead
```
Branch has no commits ahead of main. Nothing to create a PR for.
```

---

## Quick Reference Commands

| Action | Command |
|--------|---------|
| Check status | `git status` |
| Current branch | `git branch --show-current` |
| Diff stats | `git diff main...HEAD --stat` |
| Full diff | `git diff main...HEAD` |
| Branch commits | `git log main..HEAD --format='%h %s%n%b'` |
| Remote URL | `git remote get-url origin` |
| Tracking status | `git branch -vv \| grep "<branch>"` |
| Push with tracking | `git push -u origin <branch>` |
| Create PR | `gh pr create --title "..." --body "..." --base main` |
| List PRs for branch | `gh pr list --head <branch>` |
| View PR | `gh pr view` |

---

## Trigger Phrases

Use this skill when user says:
- "Create a PR"
- "Open a pull request"
- "Make a PR for this branch"
- "Submit this for review"
- "Create a pull request"
- "PR this"

---

## Example Workflow Execution

```bash
# PHASE 1: Parallel context gathering
# Group 1
git status
git branch --show-current
git log --oneline -10

# Group 2 (parallel with Group 1)
git diff main...HEAD --stat
git diff main...HEAD
git log main..HEAD --format='%h %s%n%b'
git remote get-url origin

# PHASE 2: Check tracking
git branch -vv | grep "feature-branch"

# PHASE 3: Push if needed
git push -u origin feature-branch

# PHASE 4: Create PR
gh pr create --title "Add feature X" --body "$(cat <<'EOF'
## Summary

- Added feature X to improve Y
- Fixed issue with Z
- Updated documentation

## Changes

This PR implements feature X which allows users to do Y more efficiently.

1. **Component A**: Added new handler for X
2. **Component B**: Updated interface to support X
3. **Docs**: Added usage examples
EOF
)" --base main
```

Output: `https://github.com/owner/repo/pull/123`
