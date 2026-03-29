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
