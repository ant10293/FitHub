#!/bin/bash
#
# Script to remove trailing whitespace and extra blank lines from non-Swift files
# Run this manually if you notice files accumulating blank lines
#

echo "Cleaning trailing whitespace and extra blank lines..."

# Find all relevant files and clean them
find . -type f \( -name "*.json" -o -name "*.ts" -o -name "*.js" -o -name "*.md" -o -name "*.txt" -o -name "*.html" -o -name "*.sh" \) \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    ! -path "*/build/*" \
    ! -path "*/venv/*" \
    ! -path "*/site-packages/*" \
    ! -path "*/DerivedData/*" \
    ! -path "./scripts/clean-trailing-whitespace.sh" \
    -exec sh -c '
        file="$1"
        # Remove trailing whitespace from each line
        sed -i "" "s/[[:space:]]*$//" "$file"
        # Remove all trailing blank lines
        perl -i -pe "chomp if eof" "$file"
        # Add exactly one newline at the end if file is not empty
        if [ -s "$file" ]; then
            echo "" >> "$file"
        fi
    ' _ {} \;

echo "Done! Files cleaned."
