#!/bin/bash

# --- Configuration ---
SOURCE_DIR="$HOME/GIT/RHIS/"
DEST_DIR="$HOME/GIT/rhis-builder-kvm-lz"
BRANCH="shadd"
REMOTE="shaddfork"
BASE_REMOTE="origin"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

get_github_owner_repo_from_remote() {
    local remote_name="$1"
    local url path

    url="$(git remote get-url "$remote_name" 2>/dev/null || true)"
    [ -n "$url" ] || return 1

    case "$url" in
        git@github.com:*)
            path="${url#git@github.com:}"
            ;;
        https://github.com/*)
            path="${url#https://github.com/}"
            ;;
        http://github.com/*)
            path="${url#http://github.com/}"
            ;;
        *)
            return 1
            ;;
    esac

    path="${path%.git}"
    printf '%s\n' "$path"
}

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

BASE_REPO="$(get_github_owner_repo_from_remote "$BASE_REMOTE")" || { echo "❌ Could not determine upstream GitHub repo from remote '$BASE_REMOTE'"; exit 1; }
HEAD_REPO="$(get_github_owner_repo_from_remote "$REMOTE")" || { echo "❌ Could not determine fork GitHub repo from remote '$REMOTE'"; exit 1; }
HEAD_OWNER="${HEAD_REPO%%/*}"
HEAD_REF="${HEAD_OWNER}:${BRANCH}"

if [ "$(gh pr list --repo "$BASE_REPO" --head "$HEAD_REF" --json number --jq 'length' 2>/dev/null || echo 0)" != "0" ]; then
    echo "ℹ️ A pull request for branch '$BRANCH' may already exist in $BASE_REPO. Skipping creation."
    echo "🎉 Workflow complete!"
    exit 0
fi

gh pr create \
    --repo "$BASE_REPO" \
    --title "Sync RHIS to rhis-builder ($TIMESTAMP)" \
    --body "Updating builder with latest changes from the RHIS source repository. Generated on: $TIMESTAMP" \
    --base main \
    --head "$HEAD_REF"

echo "🎉 Workflow complete!"
