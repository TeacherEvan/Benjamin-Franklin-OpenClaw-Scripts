#!/bin/bash
# Common functions and constants for OpenClaw scripts
# Source this file: source "$(dirname "$0")/lib/common.sh"

# Workspace paths - single source of truth
WORKSPACE="${OPENCLAW_WORKSPACE:-/home/ubuntu/.openclaw/clawd}"
MEMORY_DIR="$WORKSPACE/memory"
IMAGE_STORE="$MEMORY_DIR/images"
METADATA_STORE="$IMAGE_STORE/metadata.json"

# Logging utilities
log_info() {
    echo "ℹ️  $*" >&2
}

log_success() {
    echo "✅ $*" >&2
}

log_error() {
    echo "❌ $*" >&2
}

log_warning() {
    echo "⚠️  $*" >&2
}

# Input validation
validate_file_exists() {
    local file="$1"
    local description="${2:-File}"
    
    if [ -z "$file" ]; then
        log_error "$description path not provided"
        return 1
    fi
    
    if [ ! -f "$file" ]; then
        log_error "$description not found: $file"
        return 1
    fi
    
    return 0
}

validate_env_var() {
    local var_name="$1"
    local description="${2:-Environment variable}"
    
    if [ -z "${!var_name-}" ]; then
        log_error "$description ($var_name) not set"
        return 1
    fi
    
    return 0
}

# Directory management
ensure_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || {
            log_error "Failed to create directory: $dir"
            return 1
        }
    fi
    return 0
}

# Safe path handling - prevent directory traversal
sanitize_path() {
    local path="$1"
    local base_dir="${2:-$WORKSPACE}"

    # Resolve base directory to an absolute path
    local resolved_base
    resolved_base="$(realpath -m "$base_dir" 2>/dev/null)" || {
        log_error "Failed to resolve base directory: $base_dir"
        return 1
    }

    # Resolve the input path to an absolute path
    local resolved_path
    resolved_path="$(realpath -m "$path" 2>/dev/null)" || {
        log_error "Failed to resolve path: $path"
        return 1
    }

    # Ensure the resolved path is within the base directory
    if [ "$resolved_path" != "$resolved_base" ] && [[ "$resolved_path" != "$resolved_base"/* ]]; then
        log_error "Path escapes base directory: $resolved_path (base: $resolved_base)"
        return 1
    fi

    echo "$resolved_path"
    return 0
}

# API key validation
validate_api_key() {
    local key="$1"
    local service="${2:-API}"
    
    if [ -z "$key" ]; then
        log_error "$service key not found"
        return 1
    fi
    
    # Basic validation - not empty and reasonable length
    if [ ${#key} -lt 10 ]; then
        log_error "$service key appears invalid (too short)"
        return 1
    fi
    
    return 0
}
