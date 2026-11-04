#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_DIR="$REPO_DIR/packages"
TARGET_DIR="$HOME"
BACKUP_DIR=""
ACTION="install"
CUSTOM_DESKTOP=""
CUSTOM_DISTRO=""
DRY_RUN=true
INCLUDE_FONTS=true
INCLUDE_APPEARANCE=true
BACKUP=false
PREEXISTING_LINKS=()
CUSTOM_PACKAGES=()

detect_distro() {
    local os_release="${1:-/etc/os-release}"
    local id=""

    if [[ -r "$os_release" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            case "$line" in
                ID=*)
                    id="${line#ID=}"
                    id="${id%$'\r'}"

                    # Remove matching surrounding quotes.
                    if [[ "$id" == \"*\" && "$id" == *\" ]] ||
                       [[ "$id" == \'*\' && "$id" == *\' ]]; then
                        id="${id:1:${#id}-2}"
                    fi
                    break
                    ;;
            esac
        done < "$os_release"
    fi

    case "$id" in
        pop|pop-os) echo "pop-os" ;;
        fedora) echo "fedora" ;;
        bazzite) echo "bazzite" ;;
        cachyos) echo "cachyos" ;;
        *) echo "unknown" ;;
    esac
}

detect_desktop() {
    local desktop="${1:-}"

    if [[ -z "$desktop" ]]; then
        desktop="${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-}}"
    fi

    desktop="${desktop,,}"

    case ":$desktop:" in
        *:cosmic:*) echo "cosmic" ;;
        *:gnome:*) echo "gnome" ;;
        *:kde:*|*:plasma:*) echo "kde" ;;
        *) echo "unknown" ;;
    esac
}

parse_args() {
    while (($#)); do
        case "$1" in
            --install)
                ACTION="install"
                DRY_RUN=false
                ;;
            --uninstall)
                ACTION="uninstall"
                DRY_RUN=false
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --distro)
                if (($# < 2)) || [[ "$2" == --* ]]; then
                    echo "Error: --distro requires a value." >&2
                    exit 1
                fi

                case "$2" in
                    pop-os|fedora|bazzite|cachyos|none)
                        CUSTOM_DISTRO="$2"
                        ;;
                    *)
                        echo "Error: Unsupported distribution: $2" >&2
                        exit 1
                        ;;
                esac

                shift
                ;;
            --desktop)
                if (($# < 2)) || [[ "$2" == --* ]]; then
                    echo "Error: --desktop requires a value." >&2
                    exit 1
                fi

                case "$2" in
                    cosmic|gnome|kde|none)
                        CUSTOM_DESKTOP="$2"
                        ;;
                    *)
                        echo "Error: Unsupported desktop: $2" >&2
                        exit 1
                        ;;
                esac

                shift
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
  --uninstall       Remove managed symlinks (isolated targets only)
  --dry-run         Preview installation (default)
  --distro NAME     Select pop-os, fedora, bazzite, cachyos, or none
  --desktop NAME    Select cosmic, gnome, kde, or none
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

        BACKUP_DIR=""
        if ! snapshot_stow_links "${packages[@]}"; then
            echo "Error: Could not snapshot existing symlinks. Installation aborted." >&2
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

    if stow "${options[@]}" -- "${packages[@]}"; then
        return 0
    fi

    echo "Error: GNU Stow installation failed." >&2

    if [[ "$DRY_RUN" == false ]]; then
        if ! recover_failed_installation "${packages[@]}"; then
            echo "Error: Automatic recovery was incomplete." >&2
        fi
    fi

    return 1
}

get_stow_conflicts() {
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

    if grep -Eiq '(^|[[:space:]])(error|fatal):|permission denied|no such file or directory' <<< "$output"; then
        echo "Error: GNU Stow reported an additional error." >&2
        printf '%s\n' "$output" >&2
        return 1
    fi

    printf '%s\n' "$output" |
        sed -n \
            's/^CONFLICT when stowing [^:]*: existing target is neither a link nor a directory: //p'
}

move_file() {
    command mv -- "$@"
}

rollback_backup_moves() {
    local backup_dir="$1"
    shift

    local relative
    local failed=false
    local -a moved=("$@")

    for relative in "${moved[@]}"; do
        if ! is_safe_relative_path "$relative" ||
            has_symlinked_parent "$relative"; then
            echo "CRITICAL: Unsafe rollback path: $relative" >&2
            failed=true
            continue
        fi

        if [[ -e "$TARGET_DIR/$relative" || -L "$TARGET_DIR/$relative" ]]; then
            echo "CRITICAL: Rollback destination already exists: $relative" >&2
            failed=true
            continue
        fi

        if ! move_file \
            "$backup_dir/$relative" \
            "$TARGET_DIR/$relative"; then
            echo "CRITICAL: Could not restore $relative" >&2
            failed=true
        else
            printf 'Rolled back: %s\n' "$relative"
        fi
    done

    if [[ "$failed" == true ]]; then
        echo "CRITICAL: Backup rollback incomplete." >&2
        echo "Backup directory: $backup_dir" >&2
        return 1
    fi

    return 0
}

backup_stow_conflicts() {
    local backup_dir conflict previous conflict_output
    local -a packages=("$@")
    local -a conflicts=()
    local -a moved=()

    if ! conflict_output="$(get_stow_conflicts "${packages[@]}")"; then
        echo "Error: Could not discover Stow conflicts." >&2
        return 1
    fi

    if [[ -n "$conflict_output" ]]; then
        mapfile -t conflicts <<< "$conflict_output"
    fi

    if ((${#conflicts[@]} == 0)); then
        echo "No conflicting files to back up."
        return 0
    fi

    backup_dir="$(create_backup_dir)" || return 1

    for conflict in "${conflicts[@]}"; do
        if ! is_safe_relative_path "$conflict" ||
            has_symlinked_parent "$conflict"; then
            echo "Error: Unsafe backup path: $conflict. Rolling back." >&2

            if ! rollback_backup_moves "$backup_dir" "${moved[@]}"; then
                echo "CRITICAL: Manual recovery may be required." >&2
            fi

            return 1
        fi
        if ! command mkdir -p -- "$backup_dir/$(dirname -- "$conflict")" ||
           ! move_file "$TARGET_DIR/$conflict" "$backup_dir/$conflict"; then

            echo "Error: Failed to back up $conflict. Rolling back." >&2

            if ! rollback_backup_moves "$backup_dir" "${moved[@]}"; then
                echo "CRITICAL: Manual recovery may be required." >&2
            fi

            return 1
        fi

        moved+=("$conflict")
        printf 'Backed up: %s\n' "$conflict"
    done

    BACKUP_DIR="$backup_dir"
    printf 'Backup directory: %s\n' "$BACKUP_DIR"
}

create_backup_dir() {
    local backup_root

    backup_root="$TARGET_DIR/.dotfiles-backups"

    command mkdir -p -- "$backup_root" >&2

    mktemp -d -- "$backup_root/$(date +%Y%m%d-%H%M%S)-XXXXXX"
}

restore_backup() {
    local backup_dir="$1"
    local file relative destination file_list
    local failed=false

    if [[ -z "$backup_dir" || ! -d "$backup_dir" ]]; then
        echo "Error: Invalid backup directory." >&2
        return 1
    fi

    file_list="$(mktemp)" || return 1

    if ! find "$backup_dir" \
        \( -type f -o -type l \) -print0 > "$file_list"; then
        echo "Error: Could not enumerate backup files." >&2
        command rm -f -- "$file_list"
        return 1
    fi

    while IFS= read -r -d '' file; do
        relative="${file#"$backup_dir"/}"
        destination="$TARGET_DIR/$relative"

        if ! is_safe_relative_path "$relative"; then
            echo "Error: Unsafe restore path: $relative" >&2
            failed=true
            continue
        fi

        if has_symlinked_parent "$relative"; then
            echo "Error: Cannot restore $relative: symlinked parent directory." >&2
            failed=true
            continue
        fi

        if [[ -e "$destination" || -L "$destination" ]]; then
            echo "Error: Cannot restore $relative: destination exists." >&2
            failed=true
            continue
        fi

        if ! command mkdir -p -- "$(dirname -- "$destination")" ||
           ! move_file "$file" "$destination"; then
            echo "Error: Could not restore $relative." >&2
            failed=true
            continue
        fi

        printf 'Restored: %s\n' "$relative"
    done < "$file_list"

    if ! command rm -f -- "$file_list"; then
        echo "Warning: Could not remove temporary restore file: $file_list" >&2
        failed=true
    fi

    [[ "$failed" == false ]]
}

cleanup_stow() {
    local -a packages=("$@")

    stow \
        --dir="$PACKAGES_DIR" \
        --target="$TARGET_DIR" \
        --no-folding \
        --delete \
        --verbose=2 \
        -- "${packages[@]}"
}

snapshot_stow_links() {
    local package source relative destination file_list
    local -a packages=("$@")

    PREEXISTING_LINKS=()

    file_list="$(mktemp)" || return 1

    for package in "${packages[@]}"; do
        if ! find "$PACKAGES_DIR/$package" \
            \( -type f -o -type l \) -print0 > "$file_list"; then
            echo "Error: Could not enumerate package: $package" >&2
            command rm -f -- "$file_list"
            PREEXISTING_LINKS=()
            return 1
        fi

        while IFS= read -r -d '' source; do
            relative="${source#"$PACKAGES_DIR/$package/"}"
            destination="$TARGET_DIR/$relative"

            if ! is_safe_relative_path "$relative" ||
                has_symlinked_parent "$relative"; then
                echo "Error: Unsafe snapshot path: $relative" >&2
                command rm -f -- "$file_list"
                PREEXISTING_LINKS=()
                return 1
            fi

            if [[ -L "$destination" ]]; then
                PREEXISTING_LINKS+=(
                    "$relative"
                    "$(readlink -- "$destination")"
                )
            fi
        done < "$file_list"
    done

    command rm -f -- "$file_list"
    return 0
}

has_symlinked_parent() {
    local relative="$1"
    local parent="${relative%/*}"
    local current="$TARGET_DIR"
    local component

    [[ "$relative" == */* ]] || return 1

    while [[ "$parent" == */* ]]; do
        component="${parent%%/*}"
        current="$current/$component"

        [[ -L "$current" ]] && return 0

        parent="${parent#*/}"
    done

    [[ -L "$current/$parent" ]]
}

is_safe_relative_path() {
    local path="$1"
    local component
    local -a components

    [[ -n "$path" && "$path" != /* ]] || return 1
    [[ "$path" != */ ]] || return 1

    IFS='/' read -r -a components <<< "$path"

    for component in "${components[@]}"; do
        case "$component" in
            ""|"."|"..")
                return 1
                ;;
        esac
    done

    return 0
}

cleanup_new_stow_links() {
    local package source relative destination existing i file_list
    local expected_target actual_target
    local was_preexisting
    local failed=false
    local -a packages=("$@")

    file_list="$(mktemp)" || return 1

    for package in "${packages[@]}"; do
        if ! find "$PACKAGES_DIR/$package" \
            \( -type f -o -type l \) -print0 > "$file_list"; then
            echo "Error: Could not enumerate package during cleanup: $package" >&2
            failed=true
            continue
        fi

        while IFS= read -r -d '' source; do
            relative="${source#"$PACKAGES_DIR/$package/"}"
            destination="$TARGET_DIR/$relative"

            if ! is_safe_relative_path "$relative"; then
                echo "Error: Unsafe cleanup path: $relative" >&2
                failed=true
                continue
            fi

            if has_symlinked_parent "$relative"; then
                echo "Warning: Symlinked parent directory: $relative" >&2
                failed=true
                continue
            fi

            [[ -L "$destination" ]] || continue

            was_preexisting=false

            for ((i = 0; i < ${#PREEXISTING_LINKS[@]}; i += 2)); do
                existing="${PREEXISTING_LINKS[i]}"

                if [[ "$existing" == "$relative" ]]; then
                    was_preexisting=true
                    break
                fi
            done

            [[ "$was_preexisting" == true ]] && continue

            expected_target="$(realpath --relative-to="$(dirname -- "$destination")" "$source")"
            actual_target="$(readlink -- "$destination")"

            if [[ "$actual_target" == "$expected_target" ]]; then
                if ! command rm -- "$destination"; then
                    echo "Error: Could not remove $relative" >&2
                    failed=true
                else
                    printf 'Removed new symlink: %s\n' "$relative"
                fi
            else
                echo "Warning: Unexpected symlink preserved: $relative" >&2
                failed=true
            fi
        done < "$file_list"
    done

    if ! command rm -f -- "$file_list"; then
        echo "Warning: Could not remove temporary cleanup file: $file_list" >&2
        failed=true
    fi

    [[ "$failed" == false ]]
}

recover_failed_installation() {
    local cleanup_failed=false
    local restore_failed=false
    local -a packages=("$@")

    echo "Recovering from failed installation..." >&2

    if ! cleanup_new_stow_links "${packages[@]}"; then
        cleanup_failed=true
        echo "Warning: Symlink cleanup was incomplete." >&2
    fi

    if [[ -n "$BACKUP_DIR" ]]; then
        if ! restore_backup "$BACKUP_DIR"; then
            restore_failed=true
            echo "Warning: Some original files could not be restored." >&2
        fi
    fi

    if [[ "$cleanup_failed" == true || "$restore_failed" == true ]]; then
        echo "CRITICAL: Recovery incomplete. Manual intervention required." >&2
        [[ -n "$BACKUP_DIR" ]] &&
            printf 'Backup directory: %s\n' "$BACKUP_DIR" >&2
        return 1
    fi

    echo "Recovery completed successfully."
}

run_unstow() {
    local -a packages=("$@")
    local -a options=(
        --dir="$PACKAGES_DIR"
        --target="$TARGET_DIR"
        --no-folding
        --verbose=2
        --delete
    )

    if [[ "$DRY_RUN" == true ]]; then
        options+=(--simulate)
    else
        if [[ "$TARGET_DIR" == "$(cd -- "$HOME" && pwd -P)" ]]; then
            echo "Error: Uninstallation into your real HOME is disabled during development." >&2
            return 1
        fi
    fi

    printf '\nGNU Stow uninstallation:\n'

    if ! command stow "${options[@]}" -- "${packages[@]}"; then
        echo "Error: GNU Stow uninstallation failed." >&2
        return 1
    fi
}

main() {
    local distro desktop package
    local -a packages=(common terminal)

    parse_args "$@"

    if [[ "$ACTION" == "uninstall" && "$BACKUP" == true ]]; then
        echo "Error: --backup cannot be used with --uninstall." >&2
        return 1
    fi

    if [[ ! -d "$TARGET_DIR" ]]; then
        echo "Error: Target directory does not exist: $TARGET_DIR" >&2
        return 1
    fi

    TARGET_DIR="$(cd -- "$TARGET_DIR" && pwd -P)"

    if [[ -n "$CUSTOM_DISTRO" ]]; then
        distro="$CUSTOM_DISTRO"
    else
        distro="$(detect_distro)"
    fi

    if [[ -n "$CUSTOM_DESKTOP" ]]; then
        desktop="$CUSTOM_DESKTOP"
    else
        desktop="$(detect_desktop)"
    fi

    if ((${#CUSTOM_PACKAGES[@]})); then
        packages=("${CUSTOM_PACKAGES[@]}")
    else
        [[ "$INCLUDE_FONTS" == true ]] && packages+=(fonts)
        [[ "$INCLUDE_APPEARANCE" == true ]] && packages+=(appearance)

        if [[ "$distro" != "unknown" && "$distro" != "none" ]]; then
            packages+=("distro-$distro")
        fi

        if [[ "$desktop" != "unknown" && "$desktop" != "none" ]]; then
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

    case "$ACTION" in
        install)
            if ! run_stow "${packages[@]}"; then
                echo "GNU Stow installation failed." >&2
                return 1
            fi
            ;;
        uninstall)
            if ! run_unstow "${packages[@]}"; then
                echo "GNU Stow uninstallation failed." >&2
                return 1
            fi
            ;;
        *)
            echo "Error: Unknown action: $ACTION" >&2
            return 1
            ;;
    esac

    if [[ "$DRY_RUN" == true ]]; then
        printf '\nDry-run complete. No files have been changed.\n'
    else
        printf '\n%s complete.\n' \
            "$([[ "$ACTION" == "install" ]] && echo "Installation" || echo "Uninstallation")"
    fi
}

main "$@"
