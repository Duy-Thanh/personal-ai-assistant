#!/bin/bash
# Git Conflict Resolution Script for Ubuntu 24.04
# This script safely resolves the merge conflict by backing up local changes

echo "🔧 Fixing Git merge conflict..."
echo "================================"

# Step 1: Check current status
echo "📋 Current Git status:"
git status

echo ""
echo "💾 Backing up untracked file that would be overwritten..."

# Step 2: Backup the conflicting untracked file
if [ -f "start_service.sh" ]; then
    cp start_service.sh start_service.sh.backup
    echo "✅ Backed up start_service.sh to start_service.sh.backup"
    rm start_service.sh
    echo "🗑️ Removed conflicting start_service.sh"
fi

echo ""
echo "📦 Stashing local changes to modified files..."

# Step 3: Stash local changes
git add -A  # Add all changes to staging
git stash push -m "Local changes before pull $(date)"

echo ""
echo "⬇️ Pulling latest changes from remote..."

# Step 4: Pull the latest changes
git pull

echo ""
echo "📤 Reapplying your stashed changes..."

# Step 5: Try to reapply stashed changes
if git stash pop; then
    echo "✅ Successfully reapplied your local changes!"
else
    echo "⚠️ Merge conflicts detected while reapplying stashed changes."
    echo "You may need to manually resolve conflicts in the affected files."
    echo "Use 'git status' to see which files need attention."
fi

echo ""
echo "🔍 Checking if backup file needs to be restored..."

# Step 6: Restore backup if needed
if [ -f "start_service.sh.backup" ]; then
    if [ ! -f "start_service.sh" ]; then
        cp start_service.sh.backup start_service.sh
        echo "📁 Restored your original start_service.sh"
    else
        echo "📁 New start_service.sh exists. Your backup is saved as start_service.sh.backup"
        echo "   Compare them if needed: diff start_service.sh start_service.sh.backup"
    fi
fi

echo ""
echo "📊 Final Git status:"
git status

echo ""
echo "✅ Git conflict resolution complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Review any remaining conflicts with 'git status'"
echo "   2. If conflicts exist, edit the files and run 'git add <file>'"
echo "   3. Check your backup files if needed"
echo "   4. Continue with your work!"
