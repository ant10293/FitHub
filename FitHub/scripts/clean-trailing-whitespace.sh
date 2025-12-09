#!/bin/bash
#
# Script to remove trailing whitespace and extra blank lines from non-Swift files
# Automatically extracts file patterns from .editorconfig to avoid hardcoding extensions
# 
# WARNING: Only removes trailing whitespace and trailing blank lines at END of files.
# Does NOT add blank lines in the middle of files - that's your editor's formatter.
# 
# Run this manually if you notice files accumulating blank lines.
# To prevent Cursor/VS Code from auto-formatting, disable formatOnSave in .vscode/settings.json
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

# Execute find - use Python for reliable trailing newline handling
find . -type f \( "${FIND_PATTERNS[@]}" \) \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    ! -path "*/build/*" \
    ! -path "*/venv/*" \
    ! -path "*/site-packages/*" \
    ! -path "*/DerivedData/*" \
    ! -path "*/scripts/clean-trailing-whitespace.sh" \
    -exec python3 -c "
import sys

file_path = sys.argv[1]

try:
    with open(file_path, 'rb') as f:
        content = f.read()

    # Decode as UTF-8, but handle binary files gracefully
    try:
        text = content.decode('utf-8')
    except UnicodeDecodeError:
        # Skip binary files
        sys.exit(0)

    # ONLY remove trailing whitespace from each line (don't touch blank lines in middle)
    lines = text.split('\n')
    lines = [line.rstrip() for line in lines]

    # ONLY remove trailing blank lines at the END (preserve blank lines in middle of file)
    while lines and lines[-1].strip() == '':
        lines.pop()

    # Join lines and add exactly one newline at end (if file had content)
    # Preserve all original blank lines in the middle of the file
    if lines:
        result = '\n'.join(lines) + '\n'
    else:
        result = ''  # Empty file stays empty

    # Write back ONLY if content changed (to avoid unnecessary file modifications)
    original_cleaned = text.rstrip() + '\n' if text.rstrip() else ''
    if result != original_cleaned:
        with open(file_path, 'wb') as f:
            f.write(result.encode('utf-8'))

except Exception as e:
    # Fail silently to avoid breaking the script
    pass
" {} \;

echo "Done! Files cleaned."