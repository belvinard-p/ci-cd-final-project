# Issues Encountered & Solutions

## Issue #1: setup.sh fails on Windows with `sudo: command not found`

**Date:** 2025-03-2026

**Error:**
```
./bin/setup.sh: line 7: sudo: command not found
./bin/setup.sh: line 8: sudo: command not found
```

**Cause:**
The `setup.sh` script was written for Linux (Debian/Ubuntu) and used Linux-specific commands (`sudo`, `apt-get`, `.bashrc`) that don't exist on Windows/Git Bash (MINGW64).

**Solution:**
- Removed `sudo apt-get` install commands since Node.js and npm were already installed on the system
- Replaced `.bashrc` exports with direct `export` commands compatible with Git Bash on Windows

---

# Takeaways

## Exercise 0: Update README

- The README is the first thing people see in a repo. It should clearly state the project name and purpose.
- Practiced the basic Git workflow: `git add`, `git commit`, `git push`.

## Exercise 1: Create a CI Workflow with GitHub Actions

### What I did
Created `.github/workflows/workflow.yml` — a GitHub Actions workflow that automatically runs every time code is pushed or 
a pull request is opened on the `main` branch.

### Key concepts learned

- **GitHub Actions** is a CI/CD platform built into GitHub. Workflows are defined as YAML files inside `.github/workflows/`.
- **Triggers (`on`)**: Define *when* the workflow runs. We used `push` and `pull_request` on the `main` branch, meaning 
- the pipeline runs automatically on every code change.
- **Jobs**: A workflow contains one or more jobs. Our `build` job runs on `ubuntu-latest` (a GitHub-hosted Linux VM).
- **Steps**: Each job has a sequence of steps:
  1. `actions/checkout@v3` — Clones the repo into the runner so subsequent steps can access the code.
  2. `actions/setup-node@v3` — Installs a specific Node.js version (20) on the runner.
  3. `npm ci` — Installs dependencies from `package-lock.json`. Unlike `npm install`, `npm ci` is faster and ensures a clean, reproducible install (it deletes `node_modules` first and never modifies `package-lock.json`).

### Why this matters
Without CI, developers must manually run tests and checks before merging code. A CI workflow automates this — every push is validated automatically, catching bugs early before they reach production.
