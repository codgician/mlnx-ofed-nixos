#!/usr/bin/env bash
set -euo pipefail

# Configuration
BASE_URL="https://linux.mellanox.com/public/repo/doca/"
JSON_FILE="version.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" >&2
}

# Check if a version folder is valid (not latest/lts/etc)
is_valid_version() {
    local version="$1"
    # Skip folders containing these patterns
    if [[ "$version" =~ (latest|lts|tmp|DGX_|bclinux) ]]; then
        return 1
    fi
    # Only consider folders that look like version numbers with a dash suffix (x.y.z-something)
    # This ensures we get deterministic versions and not dynamic pointers like "3.0.0"
    if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+-.*$ ]]; then
        return 0
    fi
    return 1
}

# Get current version from JSON
get_current_version() {
    if [[ -f "$JSON_FILE" ]]; then
        jq -r '.version' "$JSON_FILE"
    else
        error "JSON file $JSON_FILE not found"
        exit 1
    fi
}

# Find all valid versions with MLNX-OFED sources
find_latest_version() {
    log "Fetching directory listing from $BASE_URL"
    local html
    html=$(curl -s "$BASE_URL")
    
    local directories
    # Sort in descending order for faster search
    directories=$(echo "$html" | grep -oP 'href="[^"]*/"' | sed 's/href="//;s/\/"//' | grep -v "^[.]" | sort -V -r)
    
    local latest_doca_version=""
    local latest_mlnx_version=""
    local latest_url=""
    
    while IFS= read -r dir; do
        [[ -z "$dir" ]] && continue
        
        if ! is_valid_version "$dir"; then
            continue
        fi
        
        log "Checking version folder: $dir"
        
        # Check if SOURCES/MLNX_OFED/ exists
        local sources_url="${BASE_URL}${dir}/SOURCES/MLNX_OFED/"
        local sources_html
        
        if ! sources_html=$(curl -s "$sources_url" 2>/dev/null); then
            warn "  Failed to fetch $sources_url"
            continue
        fi
        
        # Check if it's a 404 or valid page
        if [[ "$sources_html" =~ "404 Not Found" ]]; then
            warn "  No SOURCES/MLNX_OFED/ found in $dir"
            continue
        fi
        
        # Look for debian .tgz file
        local files
        files=$(echo "$sources_html" | grep -oP 'href="[^"]*[^/]"' | sed 's/href="//;s/"//' | grep -v "^[.]")
        
        local debian_file
        debian_file=$(echo "$files" | grep "^MLNX_OFED_SRC-debian-.*\.tgz$" | head -n1)
        
        if [[ -z "$debian_file" ]]; then
            warn "  No debian .tgz file found in $dir"
            continue
        fi
        
        # Extract MLNX version from filename
        local mlnx_version
        if [[ "$debian_file" =~ MLNX_OFED_SRC-debian-(.+)\.tgz ]]; then
            mlnx_version="${BASH_REMATCH[1]}"
        else
            warn "  Could not extract version from $debian_file"
            continue
        fi
        
        local download_url="${sources_url}${debian_file}"
        
        log "  Found: $debian_file (MLNX version: $mlnx_version)"
        
        # Since we're iterating in descending order, the first valid version we find is the latest
        if [[ -z "$latest_mlnx_version" ]]; then
            latest_doca_version="$dir"
            latest_mlnx_version="$mlnx_version"
            latest_url="$download_url"
            
            # Early termination: we found the latest version, no need to continue
            log "  This is the latest version, stopping search"
            break
        fi
        
    done <<< "$directories"
    
    if [[ -z "$latest_mlnx_version" ]]; then
        error "No valid MLNX-OFED versions found"
        exit 1
    fi
    
    echo "$latest_doca_version|$latest_mlnx_version|$latest_url"
}

# Update JSON file with new version info
update_json() {
    local version="$1"
    local url="$2"
    local sha256="$3"
    
    local temp_file
    temp_file=$(mktemp)
    
    jq -n \
        --arg version "$version" \
        --arg url "$url" \
        --arg sha256 "$sha256" \
        '{
            version: $version,
            url: $url,
            sha256: $sha256
        }' > "$temp_file"
    
    mv "$temp_file" "$JSON_FILE"
    success "Updated $JSON_FILE"
}

# Main function
main() {
    local check_only=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --check)
                check_only=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [--check] [--help]"
                echo "  --check    Only check for updates, don't modify files"
                echo "  --help     Show this help message"
                exit 0
                ;;
            *)
                error "Unknown argument: $1"
                exit 1
                ;;
        esac
    done
    
    # Check dependencies
    if ! command -v jq >/dev/null 2>&1; then
        error "jq is required but not installed"
        exit 1
    fi
    
    if ! command -v curl >/dev/null 2>&1; then
        error "curl is required but not installed"
        exit 1
    fi
    
    # Get current version
    local current_version
    current_version=$(get_current_version)
    log "Current version: $current_version"
    
    # Find latest version
    log "Scanning for available MLNX-OFED versions..."
    local latest_info
    latest_info=$(find_latest_version)
    
    IFS='|' read -r doca_version mlnx_version url <<< "$latest_info"
    
    log "Latest version found:"
    log "  DOCA version: $doca_version"
    log "  MLNX version: $mlnx_version"
    log "  URL: $url"
    
    # Check if update is needed
    if [[ "$current_version" == "$mlnx_version" ]]; then
        success "Already up to date!"
        exit 0
    fi
    
    log "Update available: $current_version -> $mlnx_version"
    
    if [[ "$check_only" == true ]]; then
        log "Check-only mode, not updating files"
        exit 0
    fi
    
    # Calculate new SHA256
    log "Calculating SHA256 for $url"
    local new_sha256
    if command -v nix-prefetch-url >/dev/null 2>&1; then
        new_sha256=$(nix-prefetch-url --type sha256 "$url" 2>/dev/null | tail -n1)
    else
        error "nix-prefetch-url not found"
        exit 1
    fi
    
    log "New SHA256: $new_sha256"
    
    # Update JSON file
    update_json "$mlnx_version" "$url" "$new_sha256"
    
    success "Update completed successfully!"
    success "Updated from $current_version to $mlnx_version"
}

# Run main function
main "$@"
