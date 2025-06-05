# Fix Git Merge Conflict on Ubuntu 24.04

## Option 1: Quick Fix (run the automated script)
```bash
chmod +x fix_git_conflict.sh
./fix_git_conflict.sh
```

## Option 2: Manual Step-by-Step

### Step 1: Backup conflicting untracked file
```bash
cp start_service.sh start_service.sh.backup
rm start_service.sh
```

### Step 2: Stash your local changes
```bash
git add -A
git stash push -m "Local changes before pull $(date)"
```

### Step 3: Pull the latest changes
```bash
git pull
```

### Step 4: Reapply your stashed changes
```bash
git stash pop
```

### Step 5: Restore backup if needed
```bash
# Check if new start_service.sh exists, if not restore backup
if [ ! -f "start_service.sh" ]; then
    cp start_service.sh.backup start_service.sh
fi
```

## If there are merge conflicts after stash pop:
```bash
# See which files have conflicts
git status

# Edit the conflicting files to resolve conflicts
# Look for <<<<<<< HEAD, =======, and >>>>>>> markers

# After resolving conflicts, add the files
git add <conflicted-file>

# Complete the merge
git commit -m "Resolved merge conflicts"
```