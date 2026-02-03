#!/bin/bash

# Define source and destination paths
MARKDOWN_DIR="/Users/nolanmiller/Vault/blog-posts"
ATTACHMENTS_DIR="/Users/nolanmiller/Vault/attachments"
S3_BUCKET_NAME="nolanmiller-image-hosting"
HUGO_SITE_DIR="/Users/nolanmiller/Projects/breaking-changes"
SCRIPTS="/Users/nolanmiller/Projects/dotfiles/bin"
PYTHON_EXE="$SCRIPTS/.venv/bin/python"
CONTENT="$HUGO_SITE_DIR/content/posts"
CURRENT_PATH="$(pwd)"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

run_safe() {
    "$@"
    if [ $? -ne 0 ]; then
        log "Error executing: $1"
        exit 1
    fi
}

log "Executing blog pipeline script"

log "Replacing attached images with s3 links"
$PYTHON_EXE $SCRIPTS/images.py "$MARKDOWN_DIR" "$S3_BUCKET_NAME" "$ATTACHMENTS_DIR"

# Move the files from source to destination
log "Moving files from $MARKDOWN_DIR to $CONTENT"
run_safe rsync -av --delete "$MARKDOWN_DIR/" "$CONTENT/"

# Change to the GitHub repository directory
cd "$HUGO_SITE_DIR" || exit

log "Running Hugo build..."
run_safe hugo

log "Committing changes to GitHub repository"
run_safe git add -A
commit_message="You Got Mail... on $(date '+%Y-%m-%d %H:%M:%S')"
run_safe git commit -m "$commit_message" -m "Automated commit brought to you by \~BASH\~"

run_safe git pull --rebase -X ours
run_safe git push 

# Change to the scripts directory
log "Pushing changes to DEV.to"
cd "$SCRIPTS" || exit
$PYTHON_EXE pushtodev.py "$MARKDOWN_DIR"

# Return to the original directory
log "Blog pipeline exited successfully"
cd "$CURRENT_PATH" || exit
