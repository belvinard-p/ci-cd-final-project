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

## Issue #2: `gh` command not recognized in PowerShell

**Error:**
```
gh : The term 'gh' is not recognized as the name of a cmdlet, function, script file, or operable program.
```

**Cause:**
The GitHub CLI (`gh`) was not installed on the system. It's a separate tool from Git — Git handles version control, while `gh` is for interacting with GitHub (viewing workflow runs, creating PRs, etc.).

**Solution:**
- `winget` and `choco` were also not available on this system
- Download the installer manually from https://cli.github.com/ and run the `.msi` file
- After install, restart the terminal and run `gh auth login`
- Alternative: skip `gh` entirely and check workflow runs in the browser at `https://github.com/<username>/ci-cd-final-project/actions`

## Issue #3: `gh auth login` — one-time code not visible

**Error:**
After running `gh auth login`, the browser asked for a code but it wasn't obvious where to find it.

**Cause:**
The one-time code is displayed in the terminal, not in the browser. It's easy to miss if you switch to the browser too quickly.

**Solution:**
Look back at the terminal — the code is shown as `XXXX-XXXX` before the browser opens. If missed, run `gh auth login` again to get a new code.
`gh run list`
`https://cli.github.com/`
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

## Exercise 2: Add Linting Step to CI Workflow

### What I did
Added a `Lint with ESLint` step to the CI workflow that runs `npm run lint` after installing dependencies.

### Key concepts learned

- **Linting** is static code analysis — it checks code for style issues, potential bugs, and bad practices *without running it*.
- **ESLint** is the standard linter for JavaScript/Node.js. The rules are configured in `.eslintrc.js`.
- By adding linting to the CI pipeline, every push is automatically checked for code quality. If linting fails, the pipeline fails and the code won't be merged.
- The order of steps matters: linting runs *after* `npm ci` because ESLint and its plugins are installed as dev dependencies.

### Why this matters
Linting in CI enforces consistent code quality across the team. No one can merge code that violates the project's coding standards, even by accident.

## Exercise 3: Add Test Step to CI Workflow

### What I did
Added a `Run unit tests with Jest` step to the CI workflow that runs `npm test` after linting.

### Key concepts learned

- **Jest** is a JavaScript testing framework. Combined with **Supertest**, it can test HTTP endpoints by simulating requests against the Express app without starting a real server.
- The test suite covers all CRUD operations (Create, Read, Update, Delete), the health check, and edge cases like duplicates and missing counters.
- Tests run *after* linting — there's no point running tests if the code doesn't even pass basic quality checks.
- If any test fails, the CI pipeline fails, preventing broken code from being merged.

### Why this matters
Automated testing in CI is the core of Continuous Integration. Every code change is validated by running the full test suite, giving confidence that new changes don't break existing functionality (regression testing).

### CI Workflow Summary (Exercises 1–3)
The complete pipeline now runs on every push/PR to `main`:
1. **Checkout** → clone the repo
2. **Setup Node.js** → install Node 20
3. **Install dependencies** → `npm ci`
4. **Lint** → `npm run lint`
5. **Test** → `npm test`

## Exercise 5: Create Cleanup Tekton Task

### What I did
Created a `cleanup` Tekton Task in `.tekton/tasks.yml` that deletes all files from a workspace to ensure the CD pipeline starts fresh.

### Key concepts learned

- **Tekton** is a Kubernetes-native CI/CD framework that runs pipelines as containers inside an OpenShift/Kubernetes cluster — unlike GitHub Actions which runs on GitHub-hosted VMs.
- **Task**: The basic building block in Tekton. A Task defines one or more steps that run sequentially in containers.
- **Workspaces**: Shared storage between tasks in a pipeline. The `source` workspace holds the cloned repo code.
- **Steps**: Each step runs in its own container image. The `cleanup` task uses `alpine:3` (a minimal Linux image) to run a shell script.
- **securityContext**: `runAsUser: 0` runs the step as root, which is needed to delete all files regardless of ownership.
- The cleanup script is careful not to `rm -rf /` — it only deletes the *contents* of the workspace, not the workspace directory itself.

### Why this matters
A cleanup task ensures each pipeline run starts with a clean slate. Without it, leftover files from previous runs could cause unpredictable behavior (e.g., stale build artifacts, cached dependencies).

## Exercise 6: Create Lint Tekton Task

### What I did
Added an `eslint` Tekton Task to `.tekton/tasks.yml` that installs dependencies and runs ESLint inside a `node:20-alpine` container.

### Key concepts learned

- **Params**: Tekton tasks can accept parameters to make them reusable. The `args` param has a default value (`src/ tests/ --ext *.js`) but can be overridden when the task is called in a pipeline.
- Unlike the cleanup task (which used `alpine:3`), the lint task uses `node:20-alpine` because it needs Node.js and npm to install dependencies and run ESLint.
- Each Tekton task runs in its own container, so dependencies must be installed within the step — there's no shared state between tasks unless you use workspaces.
- `npm ci` is run first because the workspace only contains the cloned source code, not `node_modules`.

### Tekton vs GitHub Actions
| Aspect | GitHub Actions | Tekton |
|--------|---------------|--------|
| Runs on | GitHub-hosted VMs | Kubernetes pods |
| Defined in | `.github/workflows/` | `.tekton/` |
| Unit of work | Step | Step (inside a Task) |
| Reusability | Actions from marketplace | Parameterized Tasks |
| Environment | Pre-built VM images | Container images |
