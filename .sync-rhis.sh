#!/bin/bash

# --- Configuration ---
SOURCE_DIR="/home/sgallego/GIT/RHIS/"
DEST_DIR="/home/sgallego/GIT/rhis-builder-kvm-lz"
BRANCH="shadd"
REMOTE="shaddfork"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# --- 1. Sync Files ---
echo "🚀 Starting rsync from $SOURCE_DIR to $DEST_DIR..."
# Ensure destination exists
mkdir -p "$DEST_DIR"

rsync -av --delete --exclude=".*" "$SOURCE_DIR" "$DEST_DIR/"

# --- 2. Move to Destination and Prep Git ---
cd "$DEST_DIR" || { echo "❌ Failed to enter directory $DEST_DIR"; exit 1; }

# Ensure we are on the correct branch
echo "Checking out branch: $BRANCH..."
git checkout "$BRANCH" || git checkout -b "$BRANCH"

# --- 3. Stage and Check for Changes ---
git add -A

# If there are no changes, don't bother committing or pushing
if git diff-index --quiet HEAD --; then
    echo "✅ No changes detected. Nothing to commit."
    exit 0
fi

# --- 4. Commit and Push ---
echo "💾 Committing changes..."
git commit -m "Sync: Updates from RHIS source ($TIMESTAMP)"

echo "📤 Pushing to $REMOTE..."
git push "$REMOTE" "$BRANCH" || { echo "❌ Push failed"; exit 1; }

# --- 5. Create Pull Request ---
echo "⤴️ Creating Pull Request via gh CLI..."
gh pr create \
    --title "Sync RHIS to rhis-builder ($TIMESTAMP)" \
    --body "Updating builder with latest changes from the RHIS source repository. Generated on: $TIMESTAMP" \
    --base main \
    --head "$BRANCH"

echo "🎉 Workflow complete!"
