#!/usr/bin/env bash
set -euo pipefail

readonly BASE_URL="https://linux.mellanox.com/public/repo/doca/"
readonly JSON_FILE="version.json"

die() { echo "ERROR: $*" >&2; exit 1; }
log() { echo "INFO: $*" >&2; }

# Show help message
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Update MLNX-OFED source package information by scanning the latest versions
from https://linux.mellanox.com/public/repo/doca/

OPTIONS:
    --check     Check for updates without applying them
    --commit    Commit changes to git after successful update
    --help      Show this help message

EXAMPLES:
    $0                  # Update to latest version
    $0 --check          # Check for updates only
    $0 --commit         # Update and commit changes
    $0 --check --commit # Invalid: cannot use both flags together

EOF
}

# Extract links from HTML
extract_links() { grep -o 'href="[^"]*"' | cut -d'"' -f2; }

# Check if directory is a versioned release (not a pointer)
is_release() { 
    case "$1" in
        [0-9]*.[0-9]*.[0-9]*-*/) return 0 ;;
        *) return 1 ;;
    esac
}

# Find the MLNX_OFED directory (case insensitive)
find_mlnx_dir() {
    local result
    result=$(curl -s "$1/SOURCES/" 2>/dev/null | extract_links | grep -i '^mlnx[_-]ofed/$' | head -1)
    if [ -n "$result" ]; then
        echo "$result"
    fi
}

# Find debian package in directory
find_package() {
    local result
    result=$(curl -s "$1" | extract_links | grep '^MLNX_OFED_SRC-debian-.*\.tgz$' | head -1)
    if [ -n "$result" ]; then
        echo "$result"
    fi
}

# Find latest version
find_latest() {
    log "Finding latest version"
    
    local dirs
    dirs=$(curl -s "$BASE_URL" | extract_links | grep '/$' | sort -Vr)
    
    local dir
    for dir in $dirs; do
        is_release "$dir" || continue
        
        log "Checking $dir"
        mlnx_dir=$(find_mlnx_dir "${BASE_URL}${dir}")
        if [ -z "$mlnx_dir" ]; then
            continue
        fi
        
        sources_url="${BASE_URL}${dir}SOURCES/${mlnx_dir}"
        package=$(find_package "$sources_url")
        if [ -z "$package" ]; then
            continue
        fi
        
        if echo "$package" | grep -q '^MLNX_OFED_SRC-debian-.*\.tgz$'; then
            # Extract version using parameter expansion instead of sed
            version="${package#MLNX_OFED_SRC-debian-}"
            version="${version%.tgz}"
            echo "${version}|${sources_url}${package}"
            return 0
        fi
    done
    
    die "No packages found"
}

main() {
    # Parse arguments
    local check_only=false
    local commit_changes=false
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --check)
                check_only=true
                shift
                ;;
            --commit)
                commit_changes=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                die "Unknown argument: $1. Use --help for usage information."
                ;;
        esac
    done
    
    # Validate argument combinations
    if [ "$check_only" = true ] && [ "$commit_changes" = true ]; then
        die "Cannot use --check and --commit together"
    fi
    
    # Check dependencies
    command -v jq >/dev/null || die "jq required"
    command -v curl >/dev/null || die "curl required"
    if [ "$commit_changes" = true ]; then
        command -v git >/dev/null || die "git required for --commit"
    fi
    
    # Get current and latest versions
    current=$(jq -r '.version' "$JSON_FILE" 2>/dev/null || echo "none")
    latest_data=$(find_latest)
    IFS='|' read -r latest_version latest_url <<< "$latest_data"
    
    log "Current: $current"
    log "Latest: $latest_version"
    
    # Check if update needed
    if [ "$current" = "$latest_version" ]; then
        log "Up to date"
        exit 0
    fi
    
    log "Update available: $current -> $latest_version"
    if [ "$check_only" = true ]; then
        log "Check mode"
        exit 0
    fi
    
    # Update
    log "Updating..."
    hash=$(nix-prefetch-url "$latest_url" 2>/dev/null | tail -1) || die "Hash failed" 
    hash=$(nix-hash --to-sri --type sha256 "$hash") 
    jq -n --arg v "$latest_version" --arg u "$latest_url" --arg h "$hash" \
        '{version: $v, url: $u, sha256: $h}' > "$JSON_FILE"
    
    log "Updated to $latest_version"
    
    # Commit changes if requested
    if [ "$commit_changes" = true ]; then
        log "Committing changes..."
        git add "$JSON_FILE"
        git commit -m "mlnx-ofed-src: $current -> $latest_version"
        log "Changes committed"
    fi
}

main "$@"
