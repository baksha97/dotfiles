#!/bin/bash

# Check if a path is a symlink
is_symlink() {
    [[ -L "$1" ]]
}

# Create a timestamped backup of a file if it exists and is not a symlink
backup_if_exists() {
    local file="$1"
    if [[ -f "$file" ]] && ! is_symlink "$file"; then
        local timestamp
        timestamp=$(date +%Y%m%d_%H%M%S)
        echo "Backing up $file to ${file}.bak.${timestamp}"
        cp "$file" "${file}.bak.${timestamp}"
    fi
}

# Merge specific keys from an existing JSON file into a new one
# Usage: merge_json_preserve_keys <existing_json> <new_json> <keys_file> <output_json>
merge_json_preserve_keys() {
    local existing="$1"
    local new="$2"
    local keys_file="$3"
    local output="$4"

    if [[ ! -f "$existing" ]]; then
        cp "$new" "$output"
        return
    fi

    if [[ ! -f "$keys_file" ]]; then
        echo "Warning: Keys file $keys_file not found, using new file as is."
        cp "$new" "$output"
        return
    fi

    # Start with the new file
    cp "$new" "$output"

    # For each key in the keys file, if it exists in the existing file,
    # copy it over to the output file using jq.
    while IFS= read -r key || [[ -n "$key" ]]; do
        # Skip empty lines and comments
        [[ -z "$key" || "$key" =~ ^# ]] && continue

        # Check if the key exists in the existing file
        if jq -e ".$key" "$existing" >/dev/null 2>&1; then
            echo "Preserving key: $key"
            local value
            value=$(jq -c ".$key" "$existing")
            jq ".$key = $value" "$output" > "${output}.tmp" && mv "${output}.tmp" "$output"
        fi
    done < "$keys_file"
}
