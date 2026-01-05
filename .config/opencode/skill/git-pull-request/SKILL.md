---
name: git-pull-request
description: How to create and manage pull requests in github or git.
---

# What I do

I help you create GitHub pull requests using the `hub` CLI tool. I'll analyze your changes, generate a PR title from your commit message, and work with you interactively to craft the perfect PR description before submitting.

# How I work

## Prerequisites Check
Before starting, I verify:
1. We're in a git repository
2. The current branch is not the base branch (main/master)
3. No PR already exists for this branch
4. `hub` CLI is installed

## Workflow

### 1. Gather Information
I collect:
- Base branch (usually main or master from origin/HEAD)
- Current branch name
- Merge base commit
- Last commit message (becomes PR title)
- Full diff from merge base to HEAD
- Commit log showing all commits in the branch

### 2. Present the Changes
I show you:
- The PR title (from last commit message)
- Commit history for the branch
- A summary of files changed
- Key sections of the diff that are relevant

### 3. Generate Initial PR Body
Based on the diff analysis, I generate a structured PR description with:
- **Summary**: 1-2 sentence overview of the change
- **Motivation**: Why this change is needed
- **Changes**: Bullet points of what changed
- **Features** or **Fixes**: What functionality is added/fixed
- **Usage**: How to use new features (if applicable)
- **Documentation**: Links to docs (omit if none)

### 4. Interactive Refinement
I present the draft PR body and wait for your feedback. You can:
- Approve it and proceed to create the PR
- Request changes to specific sections
- Add/remove sections
- Ask me to emphasize or de-emphasize certain changes

We iterate until you're satisfied.

### 5. Create the Pull Request
Once approved, I:
1. Write the PR body to a temporary file
2. Execute the hub command reading from that temp file:

```bash
hub pull-request -m "<title>" -m "$(cat $TEMPFILE)" -b <base-branch> -o
```

IMPORTANT: Include the `-o` flag so it opens the PR in my browser automatically.
The temp file ensures proper handling of multi-line markdown content.

## Commands I use

### Check if PR exists
```bash
hub pr list --head <current-branch> --format "%U%n"
```

### Get base branch
```bash
git rev-parse --abbrev-ref origin/HEAD | sed 's|origin/||'
```
Fallback to "main" if this fails.

### Get merge base
```bash
git merge-base HEAD origin/<base-branch>
```

### Get last commit message (PR title)
```bash
git log -1 --pretty=%s
```

### Get commit log
```bash
git log --oneline <merge-base>..HEAD
```

### Get diff
```bash
git diff <merge-base>...HEAD
```

### Get files changed summary
```bash
git diff --stat <merge-base>...HEAD
```

### Create PR with hub
```bash
# Write the markdown body to a temp file
pr_body_file=$(mktemp)
cat > "$pr_body_file" << 'EOF'
<markdown body content>
EOF

# Create the PR using the temp file
hub pull-request -m "<title>" -m "$(cat $pr_body_file)" -b <base-branch> -o
```

Note: The first `-m` is the title, second `-m` is the body read from temp file. This ensures proper handling of multi-line markdown content with special characters.

### Add labels (if requested)
```bash
hub api repos/{owner}/{repo}/issues/{pr_number}/labels -f labels[]="label-name"
```

## Error Handling

### Branch not pushed
If the current branch doesn't exist on remote, I tell you:
```
Your branch needs to be pushed to remote first. Please run:
git push -u origin <branch-name>
```

### PR already exists
If a PR exists, I show you the URL and say:
```
A pull request already exists for this branch: <PR-URL>
```

### Not on a feature branch
If you're on main/master, I tell you:
```
You're currently on the base branch. Please checkout a feature branch first.
```

### No commits ahead
If there are no new commits compared to base:
```
Your branch has no commits ahead of <base-branch>. Nothing to create a PR for.
```

## Important Notes

- I **never** push changes to remote - that's your responsibility
- I use the last commit message as the PR title by default, but you can override it
- I default to using markdown formatting in PR bodies
- I focus the PR description on **why** the changes matter, not just **what** changed
- If you ask to add labels, reviewers, or other metadata after PR creation, I'll use `hub api` commands to update the PR

## Example Interaction

**User**: "Create a PR for this branch"

**Me**: 
1. Checks prerequisites
2. Shows you the proposed PR title and commit summary
3. Analyzes the diff
4. Presents a draft PR body like:

```markdown
## Summary
Adds retry logic to the API client to handle transient network failures.

## Motivation
Users were experiencing intermittent failures when network conditions were poor. This change makes the application more resilient.

## Changes
- Added exponential backoff retry mechanism to HTTP client
- Configured max 3 retries with 1s, 2s, 4s delays
- Added logging for retry attempts

## Features
- Automatic retry on 5xx errors and network timeouts
- Configurable retry limits via environment variables

## Usage
Set `API_MAX_RETRIES` and `API_RETRY_BASE_DELAY_MS` to configure behavior.
```

5. Asks: "Does this look good, or would you like me to adjust anything?"

6. After your approval, creates a temp file with the markdown body and runs:
```bash
pr_body_file=$(mktemp)
cat > "$pr_body_file" << 'EOF'
## Summary
Adds retry logic to the API client to handle transient network failures.
...
EOF

hub pull-request -m "Add retry logic to API client" -m "$(cat $pr_body_file)" -b main -o
```

7. Confirms: "Pull request created and opened in your browser!"

## When to Use This Skill

Trigger this skill when the user says things like:
- "Create a PR"
- "Open a pull request"
- "Make a PR for this branch"
- "Submit this for review"
- "Create a pull request"

## What Makes a Good PR Description

I aim to create PR descriptions that:
- Start with the **why** before the **what**
- Are scannable with clear sections and bullet points
- Include enough context for reviewers who aren't familiar with the problem
- Highlight breaking changes or important considerations
- Link to related issues or documentation when relevant
- Are concise but complete - no walls of text, no missing context
