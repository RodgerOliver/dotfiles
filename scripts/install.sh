#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_DIR="$REPO_DIR/packages"
TARGET_DIR="$HOME"
DRY_RUN=true
INCLUDE_FONTS=true
INCLUDE_APPEARANCE=true
BACKUP=false
CUSTOM_PACKAGES=()

detect_distro() {
    local id="" id_like=""

    if [[ -r /etc/os-release ]]; then
        . /etc/os-release
        id="${ID:-}"
        id_like="${ID_LIKE:-}"
    fi

    case "$id" in
        pop|pop-os)
            echo "pop-os"
            ;;
        fedora)
            echo "fedora"
            ;;
        bazzite)
            echo "bazzite"
            ;;
        cachyos)
            echo "cachyos"
            ;;
        *)
            case " $id_like " in
                *" fedora "*) echo "fedora" ;;
                *" arch "*) echo "cachyos" ;;
                *) echo "unknown" ;;
            esac
            ;;
    esac
}

detect_desktop() {
    local desktop="${XDG_CURRENT_DESKTOP:-}"

    desktop="${desktop,,}"

    case "$desktop" in
        *cosmic*) echo "cosmic" ;;
        *gnome*) echo "gnome" ;;
        *kde*|*plasma*) echo "kde" ;;
        *) echo "unknown" ;;
    esac
}

parse_args() {
    while (($#)); do
        case "$1" in
            --install)
                DRY_RUN=false
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --package)
                if (($# < 2)) || [[ "$2" == --* ]]; then
                    echo "Error: --package requires a package name" >&2
                    exit 1
                fi
                CUSTOM_PACKAGES+=("$2")
                shift
                ;;
            --no-fonts)
                INCLUDE_FONTS=false
                ;;
            --no-appearance)
                INCLUDE_APPEARANCE=false
                ;;
            --target)
                if (($# < 2)) || [[ -z "$2" || "$2" == --* ]]; then
                    echo "Error: --target requires a directory" >&2
                    exit 1
                fi
                TARGET_DIR="$2"
                shift
                ;;
            --backup)
                BACKUP=true
                ;;
            --help|-h)
                cat <<'EOF'
Usage: ./scripts/install.sh [OPTIONS]

Options:
  --install         Create symlinks (isolated targets only)
  --dry-run         Preview installation (default)
  --package NAME    Select a package (repeatable)
  --no-fonts        Exclude fonts
  --no-appearance   Exclude appearance
  --target DIR      Set installation target (default: HOME)
  --backup          Back up conflicting files before installation
  -h, --help        Show this help
EOF
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
        shift
    done
}

run_stow() {
    local -a packages=("$@")
    local -a options=(
        --dir="$PACKAGES_DIR"
        --target="$TARGET_DIR"
        --no-folding
        --verbose=2
    )

    if ! command -v stow >/dev/null 2>&1; then
        echo "Error: GNU Stow is not installed." >&2
        return 1
    fi

    if [[ "$DRY_RUN" == true ]]; then
        options+=(--simulate)
        printf '\nGNU Stow dry-run:\n'
    else
        if [[ "$TARGET_DIR" == "$(cd -- "$HOME" && pwd -P)" ]]; then
            echo "Error: Installing into HOME is disabled during development." >&2
            return 1
        fi

        if [[ "$BACKUP" == true ]]; then
            printf '\nBacking up conflicting files:\n'

            if ! backup_stow_conflicts "${packages[@]}"; then
                echo "Error: Backup failed. Installation aborted." >&2
                return 1
            fi
        fi

        printf '\nGNU Stow installation:\n'
    fi

    stow "${options[@]}" -- "${packages[@]}"
}

get_stow_conflicts() {
    local output
    local -a packages=("$@")

    output="$(
        stow \
            --dir="$PACKAGES_DIR" \
            --target="$TARGET_DIR" \
            --no-folding \
            --simulate \
            --verbose=2 \
            -- "${packages[@]}" 2>&1
    )" || true

    printf '%s\n' "$output" |
        sed -n \
            's/^CONFLICT when stowing [^:]*: existing target is neither a link nor a directory: //p'
}

validate_stow_conflicts() {
    local output
    local -a packages=("$@")

    if output="$(
        stow \
            --dir="$PACKAGES_DIR" \
            --target="$TARGET_DIR" \
            --no-folding \
            --simulate \
            --verbose=2 \
            -- "${packages[@]}" 2>&1
    )"; then
        return 0
    fi

    if ! grep -q '^CONFLICT when stowing ' <<< "$output"; then
        echo "Error: GNU Stow failed without reporting a recognized conflict." >&2
        printf '%s\n' "$output" >&2
        return 1
    fi

    if grep '^CONFLICT when stowing ' <<< "$output" |
        grep -v 'existing target is neither a link nor a directory:'; then
        echo "Error: Unsupported GNU Stow conflict type." >&2
        return 1
    fi

    return 0
}

move_file() {
    command mv -- "$@"
}

backup_stow_conflicts() {
    local backup_dir conflict previous
    local -a packages=("$@")
    local -a conflicts=()
    local -a moved=()

    if ! validate_stow_conflicts "${packages[@]}"; then
        return 1
    fi

    mapfile -t conflicts < <(get_stow_conflicts "${packages[@]}")

    if ((${#conflicts[@]} == 0)); then
        echo "No conflicting files to back up."
        return 0
    fi

    backup_dir="$(create_backup_dir)" || return 1

    for conflict in "${conflicts[@]}"; do
        if ! command mkdir -p -- "$backup_dir/$(dirname -- "$conflict")" ||
           ! move_file "$TARGET_DIR/$conflict" "$backup_dir/$conflict"; then

            echo "Error: Failed to back up $conflict. Rolling back." >&2

            for previous in "${moved[@]}"; do
                if ! move_file \
                    "$backup_dir/$previous" \
                    "$TARGET_DIR/$previous"; then
                    echo "CRITICAL: Could not restore $previous" >&2
                    echo "Backup directory: $backup_dir" >&2
                fi
            done

            return 1
        fi

        moved+=("$conflict")
        printf 'Backed up: %s\n' "$conflict"
    done

    printf 'Backup directory: %s\n' "$backup_dir"
}

create_backup_dir() {
    local backup_root

    backup_root="$TARGET_DIR/.dotfiles-backups"

    command mkdir -p -- "$backup_root" >&2

    mktemp -d -- "$backup_root/$(date +%Y%m%d-%H%M%S)-XXXXXX"
}

main() {
    local distro desktop package
    local -a packages=(common terminal)

    parse_args "$@"

    if [[ ! -d "$TARGET_DIR" ]]; then
        echo "Error: Target directory does not exist: $TARGET_DIR" >&2
        return 1
    fi

    TARGET_DIR="$(cd -- "$TARGET_DIR" && pwd -P)"

    distro="$(detect_distro)"
    desktop="$(detect_desktop)"

    if ((${#CUSTOM_PACKAGES[@]})); then
        packages=("${CUSTOM_PACKAGES[@]}")
    else
        [[ "$INCLUDE_FONTS" == true ]] && packages+=(fonts)
        [[ "$INCLUDE_APPEARANCE" == true ]] && packages+=(appearance)

        if [[ "$desktop" != "unknown" ]]; then
            packages+=("desktop-$desktop")
        fi
    fi

    for package in "${packages[@]}"; do
        if [[ ! -d "$PACKAGES_DIR/$package" ]]; then
            echo "Error: Package '$package' does not exist." >&2
            exit 1
        fi
    done

    printf 'Distribution: %s\n' "$distro"
    printf 'Desktop:      %s\n' "$desktop"
    printf 'Repository:   %s\n' "$REPO_DIR"
    printf 'Target:       %s\n' "$TARGET_DIR"
    printf '\nSelected packages:\n'
    printf '  %s\n' "${packages[@]}"
    if ! run_stow "${packages[@]}"; then
        echo "GNU Stow operation failed." >&2
        return 1
    fi

    if [[ "$DRY_RUN" == true ]]; then
        printf '\nDry-run complete. No files have been changed.\n'
    else
        printf '\nInstallation complete.\n'
    fi
}

main "$@"
