# Git Workflow Guide

This guide covers every Git command you need to work on this project — from first clone to pushing your changes. Designed for newbies who have never used Git before.

---

## Table of Contents

1. [What is Git and Why Do We Use It?](#1-what-is-git-and-why-do-we-use-it)
2. [One-Time Setup](#2-one-time-setup)
3. [Daily Workflow](#3-daily-workflow)
4. [Branching Strategy](#4-branching-strategy)
5. [Common Git Commands Reference](#5-common-git-commands-reference)
6. [Handling Conflicts](#6-handling-conflicts)
7. [Undoing Mistakes](#7-undoing-mistakes)
8. [Working with GitHub](#8-working-with-github)

---

## 1. What is Git and Why Do We Use It?

Git is a **version control system** — it tracks every change made to every file, lets multiple people work on the same project without overwriting each other's work, and lets you roll back any mistake.

```
Your machine                          GitHub (shared)
─────────────                         ───────────────
Working files  ──git add──►  Staging  ──git commit──►  Local history  ──git push──►  Remote repo
               ◄──────────────────────────────────────────────────────git pull──────
```

---

## 2. One-Time Setup

### Install Git

**macOS:**
```bash
# Git ships with Xcode Command Line Tools
git --version
# If not found, macOS prompts you to install it automatically
```

**Windows:**
- Download from: https://git-scm.com/download/win
- Run installer — keep all defaults
- Open **Git Bash** from Start menu for a Unix-style terminal, or use Command Prompt / PowerShell

### Configure Your Identity

Git attaches your name and email to every commit you make. Set these once:

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
```

Verify:
```bash
git config --list
# Expected lines:
# user.name=Your Name
# user.email=you@example.com
```

### Set the Default Branch Name to `main`

```bash
git config --global init.defaultBranch main
```

### Set a Default Editor (optional)

```bash
# VS Code
git config --global core.editor "code --wait"

# Notepad++ (Windows)
git config --global core.editor "'C:/Program Files/Notepad++/notepad++.exe' -multiInst -nosession"

# nano (macOS/Linux)
git config --global core.editor nano
```

### Clone the Repository

```bash
git clone https://github.com/mongoemon/robotframework_automation.git
cd robotframework_automation
```

### Set Up SSH (recommended — avoids typing password every push)

**macOS:**
```bash
# Generate SSH key pair
ssh-keygen -t ed25519 -C "you@example.com"
# Press Enter to accept default file location
# Enter a passphrase (or leave blank)

# Copy public key to clipboard
cat ~/.ssh/id_ed25519.pub | pbcopy
```

**Windows (Git Bash):**
```bash
ssh-keygen -t ed25519 -C "you@example.com"
cat ~/.ssh/id_ed25519.pub | clip
```

Then:
1. Go to GitHub → **Settings → SSH and GPG keys → New SSH key**
2. Paste the key, give it a title (e.g. "My Laptop"), click **Add SSH key**

Test it:
```bash
ssh -T git@github.com
# Expected: Hi mongoemon! You've successfully authenticated...
```

Switch your clone to use SSH:
```bash
git remote set-url origin git@github.com:mongoemon/robotframework_automation.git
```

---

## 3. Daily Workflow

### Before You Start Working — Pull Latest Changes

Always pull before you start so you have the latest code from your team:

```bash
git pull origin main
```

If you are on a feature branch:
```bash
git pull origin main --rebase
```

### Check What You Have Changed

```bash
git status
```

Output explained:
```
On branch feature/add-profile-tests
Changes not staged for commit:
  modified:   resources/pages/login_page.robot      ← you edited this

Untracked files:
  resources/pages/profile_page.robot                ← new file, git doesn't know about it yet
```

### See Exactly What Changed (line by line)

```bash
# Changes to tracked files
git diff

# Changes already staged (ready to commit)
git diff --staged
```

### Stage Your Changes

```bash
# Stage a specific file
git add resources/pages/profile_page.robot

# Stage multiple files
git add resources/pages/profile_page.robot tests/smoke/02_profile_smoke.robot

# Stage all changed files in the current directory (use with care)
git add .
```

### Commit Your Changes

A commit is a snapshot saved to your local history.

```bash
git commit -m "add profile page object and smoke test"
```

**Good commit message rules:**
- Use present tense: "add" not "added", "fix" not "fixed"
- Keep the first line under 72 characters
- Describe *what* and *why*, not *how*

```bash
# Good
git commit -m "add profile page object with name verification keyword"
git commit -m "fix login locator broken after app update to v2.3"
git commit -m "increase timeout to 60s for CI environment"

# Bad
git commit -m "stuff"
git commit -m "WIP"
git commit -m "fixed the thing"
```

### Push to GitHub

```bash
git push origin main
# Or push a feature branch:
git push origin feature/add-profile-tests
```

The first time you push a new branch:
```bash
git push --set-upstream origin feature/add-profile-tests
# Short form:
git push -u origin feature/add-profile-tests
```

After that, just `git push` is enough.

---

## 4. Branching Strategy

Never commit directly to `main`. Always work on a branch.

```
main  ─────────────────────────────────────────────► (always stable, tested)
          │                    │
          ▼                    ▼
  feature/login-tests    fix/locator-update
  (your work branch)     (another branch)
```

### Create a Branch

```bash
# Create and switch to a new branch in one command
git checkout -b feature/add-profile-tests

# Modern equivalent (Git 2.23+)
git switch -c feature/add-profile-tests
```

Branch naming convention used in this project:

| Prefix | Use for | Example |
|--------|---------|---------|
| `feature/` | New test suites or page objects | `feature/add-checkout-tests` |
| `fix/` | Fixing a broken locator or test | `fix/login-locator-v2` |
| `chore/` | Maintenance (updating configs, docs) | `chore/update-android-caps` |
| `refactor/` | Restructuring without changing tests | `refactor/extract-base-keywords` |

### Switch Between Branches

```bash
# List all local branches (* = current)
git branch

# List all branches including remote
git branch -a

# Switch to an existing branch
git checkout main
git switch main          # modern syntax
```

### Merge Your Branch Back to Main

When your work is done and tested:

```bash
# Switch to main
git checkout main

# Pull latest (important!)
git pull origin main

# Merge your branch
git merge feature/add-profile-tests

# Push the updated main
git push origin main
```

### Delete a Branch After Merging

```bash
# Delete local branch
git branch -d feature/add-profile-tests

# Delete remote branch
git push origin --delete feature/add-profile-tests
```

---

## 5. Common Git Commands Reference

### Viewing History

```bash
# Full log
git log

# Compact one-line-per-commit log
git log --oneline

# Visual branch graph
git log --oneline --graph --all

# Show changes in a specific commit
git show abc1234

# Show who changed each line in a file
git blame resources/pages/login_page.robot
```

### Checking Remote

```bash
# List remotes
git remote -v
# Expected:
# origin  https://github.com/mongoemon/robotframework_automation.git (fetch)
# origin  https://github.com/mongoemon/robotframework_automation.git (push)

# Fetch latest info from remote without merging
git fetch origin
```

### Stashing Work in Progress

If you need to switch branches but aren't ready to commit:

```bash
# Save uncommitted changes to a stash
git stash

# List stashes
git stash list

# Restore the most recent stash
git stash pop

# Restore a specific stash
git stash pop stash@{1}

# Discard the most recent stash
git stash drop
```

---

## 6. Handling Conflicts

A conflict happens when two people change the same lines in a file. Git cannot decide which version to keep, so it marks the conflict and asks you to resolve it.

### What a Conflict Looks Like

```
<<<<<<< HEAD
${LOGIN_BUTTON}    accessibility_id=Login Button
=======
${LOGIN_BUTTON}    accessibility_id=Sign In Button
>>>>>>> feature/update-locators
```

- `<<<<<<< HEAD` — your current version
- `=======` — separator
- `>>>>>>> feature/update-locators` — the incoming version

### Resolving a Conflict

1. Open the conflicted file in your editor
2. Decide which version is correct (or combine both)
3. Delete the conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
4. Save the file

```robot
# Resolved — chose the incoming version
${LOGIN_BUTTON}    accessibility_id=Sign In Button
```

4. Stage and commit:
```bash
git add resources/variables/common_variables.robot
git commit -m "resolve merge conflict: update login button locator to v2 label"
```

### Tips to Avoid Conflicts

- Pull `main` before starting any new branch: `git pull origin main`
- Keep branches short-lived — merge them within a few days
- Communicate with teammates when editing shared files (`common_variables.robot`)

---

## 7. Undoing Mistakes

### Undo Changes in a File (not yet staged)

```bash
git restore resources/pages/login_page.robot
# macOS older Git:
git checkout -- resources/pages/login_page.robot
```

### Unstage a File (staged but not committed)

```bash
git restore --staged resources/pages/login_page.robot
```

### Undo the Last Commit (keep the changes in files)

```bash
git reset --soft HEAD~1
```

### Undo the Last Commit and Discard All Changes

> ⚠️ Destructive — cannot be undone

```bash
git reset --hard HEAD~1
```

### Fix the Last Commit Message (before pushing)

```bash
git commit --amend -m "corrected commit message"
```

### Revert a Commit That Is Already Pushed

Reverting creates a new commit that undoes the changes — safe for shared branches:

```bash
# Find the commit hash to revert
git log --oneline

# Revert it
git revert abc1234

# Push the revert commit
git push origin main
```

---

## 8. Working with GitHub

### Viewing the Repository

- **Code:** https://github.com/mongoemon/robotframework_automation
- **Issues:** https://github.com/mongoemon/robotframework_automation/issues
- **Pull Requests:** https://github.com/mongoemon/robotframework_automation/pulls
- **Actions (CI):** https://github.com/mongoemon/robotframework_automation/actions

### Opening a Pull Request (PR)

Instead of merging directly to `main`, open a PR so teammates can review:

1. Push your branch:
   ```bash
   git push -u origin feature/add-profile-tests
   ```
2. Go to: https://github.com/mongoemon/robotframework_automation
3. Click the yellow **"Compare & pull request"** banner that appears
4. Write a description of what changed and why
5. Click **"Create pull request"**
6. After approval, click **"Merge pull request"**

### Syncing a Fork

If you forked the repo and need to get updates from the original:

```bash
# Add the original as upstream (one-time)
git remote add upstream https://github.com/mongoemon/robotframework_automation.git

# Fetch and merge upstream changes
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

### Cloning with SSH vs HTTPS

| Method | Clone URL | When to use |
|--------|-----------|-------------|
| HTTPS | `https://github.com/mongoemon/robotframework_automation.git` | Simplest, uses GitHub password / PAT |
| SSH | `git@github.com:mongoemon/robotframework_automation.git` | Recommended, no password after key setup |

Switch an existing clone from HTTPS to SSH:
```bash
git remote set-url origin git@github.com:mongoemon/robotframework_automation.git
```

---

## Quick Reference Card

```
─────────────────────────────────────────────────────────────
SETUP (once)
  git config --global user.name  "Name"
  git config --global user.email "email"
  git clone https://github.com/mongoemon/robotframework_automation.git

DAILY START
  git pull origin main           ← get latest from GitHub

NEW WORK
  git checkout -b feature/name   ← create + switch to branch
  # ... make changes ...
  git status                     ← what changed?
  git diff                       ← line-by-line changes
  git add path/to/file.robot     ← stage specific file
  git commit -m "describe change"← save to local history
  git push -u origin feature/name← send branch to GitHub

REVIEW HISTORY
  git log --oneline              ← see all commits
  git show abc1234               ← see one commit's changes

MERGE BACK
  git checkout main
  git pull origin main
  git merge feature/name
  git push origin main

UNDO
  git restore file.robot         ← discard unstaged changes
  git restore --staged file.robot← unstage a file
  git reset --soft HEAD~1        ← undo last commit (keep files)
─────────────────────────────────────────────────────────────
```
