#!/bin/bash
# =============================================================================
# release.sh — Automated Git Flow Release Script
# Usage: ./release.sh <version>
# Example: ./release.sh 1.2.0
# =============================================================================

set -e  # Exit immediately on any error

# ── Helpers ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()     { echo -e "${CYAN}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

confirm() {
  read -r -p "$1 [y/N] " response
  [[ "$response" =~ ^[Yy]$ ]] || { warn "Aborted by user."; exit 0; }
}

# ── Argument validation ───────────────────────────────────────────────────────
VERSION="$1"
[[ -z "$VERSION" ]] && error "Version argument is required.\n  Usage: ./release.sh <version>\n  Example: ./release.sh 1.2.0"

VERSION="${VERSION#v}"   # Strip leading 'v' if provided
RELEASE_BRANCH="release/v${VERSION}"
TAG="v${VERSION}"

# ── Pre-flight checks ─────────────────────────────────────────────────────────
log "Starting release process for ${TAG}..."

git rev-parse --git-dir > /dev/null 2>&1 || error "Not a git repository."

if ! git diff --quiet || ! git diff --cached --quiet; then
  error "You have uncommitted changes. Please commit or stash them before releasing."
fi

if git tag | grep -q "^${TAG}$"; then
  error "Tag ${TAG} already exists. Choose a different version."
fi

if git branch --list | grep -q "${RELEASE_BRANCH}"; then
  error "Branch '${RELEASE_BRANCH}' already exists. Delete it or choose a different version."
fi

confirm "About to release ${TAG}. Continue?"

# ── Step 1: Create release branch from develop ───────────────────────────────
log "Checking out develop and pulling latest..."
git checkout develop
git pull origin develop
success "develop is up to date."

log "Creating release branch: ${RELEASE_BRANCH}"
git checkout -b "$RELEASE_BRANCH"
success "Release branch '${RELEASE_BRANCH}' created."

# ── Step 2: Optional — bump a version file ────────────────────────────────────
# Uncomment the block for your project type:
#
# Plain VERSION file:
# echo "$VERSION" > VERSION
# git add VERSION
# git commit -m "chore: bump version to ${VERSION}"
#
# Node.js / npm:
# npm version "$VERSION" --no-git-tag-version
# git add package.json package-lock.json
# git commit -m "chore: bump version to ${VERSION}"

# ── Step 3: Push release branch ───────────────────────────────────────────────
log "Pushing release branch to origin..."
git push origin "$RELEASE_BRANCH"
success "Release branch pushed."

# ── Step 4: Merge into main ───────────────────────────────────────────────────
log "Merging '${RELEASE_BRANCH}' into main..."
git checkout main
git pull origin main
git merge --no-ff "$RELEASE_BRANCH" -m "chore: merge ${RELEASE_BRANCH} into main"
success "Merged into main."

# ── Step 5: Tag the release ───────────────────────────────────────────────────
log "Creating annotated tag ${TAG}..."
git tag -a "$TAG" -m "Release ${TAG}"
success "Tag ${TAG} created."

# ── Step 6: Push main + tags ──────────────────────────────────────────────────
log "Pushing main and tags to origin..."
git push origin main --tags
success "main and tags pushed."

# ── Step 7: Merge release branch back into develop ───────────────────────────
log "Merging '${RELEASE_BRANCH}' back into develop..."
git checkout develop
git merge --no-ff "$RELEASE_BRANCH" -m "chore: merge ${RELEASE_BRANCH} back into develop"
git push origin develop
success "develop updated with release changes."

# ── Step 8: Clean up release branch ──────────────────────────────────────────
log "Deleting release branch locally and remotely..."
git branch -d "$RELEASE_BRANCH"
git push origin --delete "$RELEASE_BRANCH"
success "Release branch '${RELEASE_BRANCH}' deleted."

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Release ${TAG} completed successfully! 🚀${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "  Merged into  : main, develop"
echo "  Tag created  : ${TAG}"
echo "  Branch       : deleted (local + remote)"
echo ""
