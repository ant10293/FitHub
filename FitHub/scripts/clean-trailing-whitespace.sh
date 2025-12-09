#!/bin/bash
#
# Script to remove trailing whitespace and extra blank lines from non-Swift files
# Automatically extracts file patterns from .editorconfig to avoid hardcoding extensions
# Run this manually if you notice files accumulating blank lines
#

echo "Cleaning trailing whitespace and extra blank lines..."

# Find the .editorconfig file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EDITORCONFIG="$REPO_ROOT/FitHub/.editorconfig"

# Extract file extensions from .editorconfig patterns
# Handles patterns like: [*.{ts,js}], [*.json], [*.md], [*.sh]
extract_extensions() {
    local editorconfig_file="$1"
    local extensions=()

    if [ ! -f "$editorconfig_file" ]; then
        return 1
    fi

    # Read .editorconfig and extract patterns (skip [*] universal and [*.swift])
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Match patterns like [*.{ts,js}], [*.json], [*.md]
        # Skip [*] universal pattern (exactly [*]) and [*.swift]
        if [[ "$line" =~ ^\[.*\*.*\]$ ]] && [[ ! "$line" =~ ^\[\*\]$ ]] && [[ ! "$line" =~ swift ]]; then
            # Remove brackets: [*.{ts,js}] -> *.{ts,js}
            pattern="${line#[}"
            pattern="${pattern%]}"

            # Handle brace expansion patterns: *.{ts,js}
            if [[ "$pattern" =~ \{([^}]+)\} ]]; then
                # Extract extensions from {ts,js}
                brace_content="${BASH_REMATCH[1]}"
                IFS=',' read -ra EXTS <<< "$brace_content"
                for ext in "${EXTS[@]}"; do
                    ext=$(echo "$ext" | xargs) # trim whitespace
                    # Extract prefix before brace (usually "*.")
                    prefix="${pattern%{*}"
                    extensions+=("${prefix}${ext}")
                done
            elif [[ "$pattern" == *"*"* ]]; then
                # Simple wildcard pattern like *.json, *.md
                extensions+=("$pattern")
            fi
        fi
    done < "$editorconfig_file"

    # Output extensions as space-separated list
    echo "${extensions[@]}"
    return 0
}

# Try to extract extensions from .editorconfig, fall back to defaults
EXTENSIONS=$(extract_extensions "$EDITORCONFIG")
if [ $? -ne 0 ] || [ -z "$EXTENSIONS" ]; then
    echo "Warning: Could not parse .editorconfig, using default extensions"
    EXTENSIONS=("*.json" "*.ts" "*.js" "*.md" "*.txt" "*.html" "*.sh")
fi

# Build find command with -o separated -name patterns
FIND_PATTERNS=()
for ext in $EXTENSIONS; do
    FIND_PATTERNS+=("-name" "$ext")
    FIND_PATTERNS+=("-o")
done
# Remove the last "-o"
unset 'FIND_PATTERNS[${#FIND_PATTERNS[@]}-1]'

# Execute find
find . -type f \( "${FIND_PATTERNS[@]}" \) \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    ! -path "*/build/*" \
    ! -path "*/venv/*" \
    ! -path "*/site-packages/*" \
    ! -path "*/DerivedData/*" \
    ! -path "*/scripts/clean-trailing-whitespace.sh" \
    -exec sh -c '
        file="$1"
        # Remove trailing whitespace from each line
        sed -i "" "s/[[:space:]]*$//" "$file"
        # Remove all trailing blank lines and ensure exactly one newline at end
        # This removes all trailing newlines, then adds exactly one
        perl -i -0777 -pe "s/\n+$/\n/" "$file"
    ' _ {} \;

echo "Done! Files cleaned."
