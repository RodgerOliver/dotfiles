#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
INSTALLER="$REPO_DIR/scripts/install.sh"

TEST_ROOT="$(mktemp -d)"
trap 'rm -rf -- "$TEST_ROOT"' EXIT

TARGET="$TEST_ROOT/home"
mkdir -p "$TARGET"

echo "Running dotfiles installer tests..."

output="$(
    "$INSTALLER" \
        --dry-run \
        --distro none \
        --desktop none \
        --no-fonts \
        --no-appearance \
        --target "$TARGET" 2>&1
)"

if [[ "$output" != *"Selected packages:"* ]] ||
   [[ "$output" != *"  common"* ]] ||
   [[ "$output" != *"  terminal"* ]]; then
    echo "FAIL: Default package selection"
    exit 1
fi

if [[ -e "$TARGET/.bashrc" || -L "$TARGET/.bashrc" ]]; then
    echo "FAIL: Dry-run modified the target"
    exit 1
fi

echo "PASS: Default package selection and dry-run safety"

echo "Testing distribution and desktop selection..."

for distro in pop-os fedora bazzite cachyos; do
    output="$(
        "$INSTALLER" \
            --dry-run \
            --distro "$distro" \
            --desktop none \
            --no-fonts \
            --no-appearance \
            --target "$TARGET" 2>&1
    )"

    if [[ "$output" != *"  distro-$distro"* ]]; then
        echo "FAIL: Distribution selection ($distro)"
        exit 1
    fi

    echo "PASS: Distribution selection ($distro)"
done

for desktop in cosmic gnome kde; do
    output="$(
        "$INSTALLER" \
            --dry-run \
            --distro none \
            --desktop "$desktop" \
            --no-fonts \
            --no-appearance \
            --target "$TARGET" 2>&1
    )"

    if [[ "$output" != *"  desktop-$desktop"* ]]; then
        echo "FAIL: Desktop selection ($desktop)"
        exit 1
    fi

    echo "PASS: Desktop selection ($desktop)"
done

echo "Testing explicit package selection..."

output="$(
    "$INSTALLER" \
        --dry-run \
        --package terminal \
        --distro none \
        --desktop none \
        --target "$TARGET" 2>&1
)"

selected_packages="${output#*Selected packages:}"

if [[ "$selected_packages" != *"  terminal"* ]] ||
   [[ "$selected_packages" == *"  common"* ]] ||
   [[ "$selected_packages" == *"  fonts"* ]]; then
    echo "FAIL: Explicit package selection"
    exit 1
fi

echo "PASS: Explicit package selection"

echo "Testing invalid arguments..."

assert_failure() {
    local description="$1"
    shift

    local output

    if output="$("$INSTALLER" "$@" 2>&1)"; then
        echo "FAIL: $description (unexpected success)"
        exit 1
    fi

    echo "PASS: $description"
}

assert_failure "Invalid distribution" \
    --distro invalid-distro \
    --target "$TARGET"

assert_failure "Invalid desktop" \
    --desktop invalid-desktop \
    --target "$TARGET"

assert_failure "Unknown package" \
    --package nonexistent-package \
    --target "$TARGET"

assert_failure "Missing distribution value" \
    --distro

assert_failure "Missing desktop value" \
    --desktop

assert_failure "Missing package value" \
    --package

assert_failure "Unknown option" \
    --unknown-option

assert_failure "Backup with uninstall" \
    --uninstall \
    --backup \
    --target "$TARGET"

if [[ -e "$TARGET/.bashrc" || -L "$TARGET/.bashrc" ]]; then
    echo "FAIL: Invalid arguments modified the target"
    exit 1
fi

echo "PASS: Invalid arguments did not modify the target"

echo "Testing installation and uninstallation lifecycle..."

LIFECYCLE_TARGET="$TEST_ROOT/lifecycle"
mkdir -p "$LIFECYCLE_TARGET"

printf 'unrelated content\n' > "$LIFECYCLE_TARGET/unrelated.txt"

lifecycle_args=(
    --package common
    --target "$LIFECYCLE_TARGET"
)

# Install the common package.
if ! "$INSTALLER" --install "${lifecycle_args[@]}" > /dev/null 2>&1; then
    echo "FAIL: Installation"
    exit 1
fi

if [[ ! -L "$LIFECYCLE_TARGET/.bashrc" ]]; then
    echo "FAIL: Installation did not create .bashrc symlink"
    exit 1
fi

if [[ "$(
    realpath -- "$LIFECYCLE_TARGET/.bashrc"
)" != "$REPO_DIR/packages/common/.bashrc" ]]; then
    echo "FAIL: Installation created an incorrect symlink"
    exit 1
fi

echo "PASS: Installation creates correct symlinks"

# Installing again should not fail.
if ! "$INSTALLER" --install "${lifecycle_args[@]}" > /dev/null 2>&1; then
    echo "FAIL: Repeated installation"
    exit 1
fi

echo "PASS: Repeated installation"

# Uninstall the same package.
if ! "$INSTALLER" --uninstall "${lifecycle_args[@]}" > /dev/null 2>&1; then
    echo "FAIL: Uninstallation"
    exit 1
fi

if [[ -e "$LIFECYCLE_TARGET/.bashrc" ||
      -L "$LIFECYCLE_TARGET/.bashrc" ]]; then
    echo "FAIL: Uninstallation left the managed symlink"
    exit 1
fi

echo "PASS: Uninstallation removes managed symlinks"

# Unrelated files must survive installation and uninstallation.
if [[ "$(cat "$LIFECYCLE_TARGET/unrelated.txt")" != "unrelated content" ]]; then
    echo "FAIL: Unrelated file was modified"
    exit 1
fi

echo "PASS: Unrelated files are preserved"

echo "Testing conflicting files and backups..."

BACKUP_TARGET="$TEST_ROOT/backup"
mkdir -p "$BACKUP_TARGET"

printf 'original bash configuration\n' > "$BACKUP_TARGET/.bashrc"

backup_args=(
    --package common
    --target "$BACKUP_TARGET"
)

# Installation must reject conflicting files without --backup.
if "$INSTALLER" --install "${backup_args[@]}" > /dev/null 2>&1; then
    echo "FAIL: Installation accepted a conflicting file"
    exit 1
fi

if [[ -L "$BACKUP_TARGET/.bashrc" ]] ||
   [[ "$(cat "$BACKUP_TARGET/.bashrc")" != "original bash configuration" ]]; then
    echo "FAIL: Conflicting file was modified"
    exit 1
fi

echo "PASS: Conflicting file is protected"

# Installation with --backup should preserve the original.
if ! "$INSTALLER" --install --backup "${backup_args[@]}" > /dev/null 2>&1; then
    echo "FAIL: Installation with backup"
    exit 1
fi

if [[ ! -L "$BACKUP_TARGET/.bashrc" ]] ||
   [[ "$(realpath -- "$BACKUP_TARGET/.bashrc")" != "$REPO_DIR/packages/common/.bashrc" ]]; then
    echo "FAIL: Installation with backup did not create the correct symlink"
    exit 1
fi

echo "PASS: Installation with backup creates symlinks"

# Locate the backed-up original.
mapfile -d '' -t backup_files < <(
    find "$BACKUP_TARGET/.dotfiles-backups" \
        -type f \
        -name .bashrc \
        -print0
)

if ((${#backup_files[@]} != 1)) ||
   [[ "$(cat "${backup_files[0]}")" != "original bash configuration" ]]; then
    echo "FAIL: Original configuration was not backed up correctly"
    exit 1
fi

echo "PASS: Original configuration is backed up"

# Uninstall and confirm the backup remains available.
if ! "$INSTALLER" --uninstall "${backup_args[@]}" > /dev/null 2>&1; then
    echo "FAIL: Uninstallation after backup"
    exit 1
fi

if [[ -e "$BACKUP_TARGET/.bashrc" || -L "$BACKUP_TARGET/.bashrc" ]]; then
    echo "FAIL: Uninstallation unexpectedly restored the original file"
    exit 1
fi

if [[ ! -f "${backup_files[0]}" ]] ||
   [[ "$(cat "${backup_files[0]}")" != "original bash configuration" ]]; then
    echo "FAIL: Backup was lost during uninstallation"
    exit 1
fi

echo "PASS: Uninstallation preserves the backup"

echo "Testing failed-installation recovery..."

RECOVERY_TARGET="$TEST_ROOT/recovery"
mkdir -p "$RECOVERY_TARGET"

printf 'original recovery configuration\n' > "$RECOVERY_TARGET/.bashrc"
printf 'unrelated recovery data\n' > "$RECOVERY_TARGET/unrelated.txt"

# Install with backup to create a realistic recovery scenario.
if ! "$INSTALLER" \
    --install \
    --backup \
    --package common \
    --target "$RECOVERY_TARGET" > /dev/null 2>&1; then
    echo "FAIL: Recovery fixture installation"
    exit 1
fi

mapfile -d '' -t recovery_backups < <(
    find "$RECOVERY_TARGET/.dotfiles-backups" \
        -type f -name .bashrc -print0
)

if ((${#recovery_backups[@]} != 1)) ||
   [[ ! -L "$RECOVERY_TARGET/.bashrc" ]]; then
    echo "FAIL: Recovery fixture setup"
    exit 1
fi

# Load the installer functions without executing main().
# The installer must use a guarded main entry point for this test.
if ! (
    export DOTFILES_TEST_SOURCE_ONLY=1
    source "$INSTALLER"

    TARGET_DIR="$RECOVERY_TARGET"
    PACKAGES_DIR="$REPO_DIR/packages"
    BACKUP_DIR="$(dirname -- "${recovery_backups[0]}")"
    PREEXISTING_LINKS=()

    recover_failed_installation common
) > /dev/null 2>&1; then
    echo "FAIL: Automatic recovery"
    exit 1
fi

if [[ -L "$RECOVERY_TARGET/.bashrc" ]] ||
   [[ ! -f "$RECOVERY_TARGET/.bashrc" ]] ||
   [[ "$(cat "$RECOVERY_TARGET/.bashrc")" != "original recovery configuration" ]]; then
    echo "FAIL: Original configuration was not restored"
    exit 1
fi

echo "PASS: Recovery restores original configuration"

if [[ "$(cat "$RECOVERY_TARGET/unrelated.txt")" != "unrelated recovery data" ]]; then
    echo "FAIL: Recovery modified unrelated files"
    exit 1
fi

echo "PASS: Recovery preserves unrelated files"

echo "Testing incomplete recovery handling..."

FAILED_RECOVERY_TARGET="$TEST_ROOT/failed-recovery"
FAILED_RECOVERY_BACKUP="$FAILED_RECOVERY_TARGET/.dotfiles-backups/test"

mkdir -p "$FAILED_RECOVERY_BACKUP"

printf 'original configuration\n' > "$FAILED_RECOVERY_BACKUP/.bashrc"
printf 'newer configuration\n' > "$FAILED_RECOVERY_TARGET/.bashrc"

# Recovery must refuse to overwrite an existing destination.
if (
    export DOTFILES_TEST_SOURCE_ONLY=1
    source "$INSTALLER"

    TARGET_DIR="$FAILED_RECOVERY_TARGET"
    PACKAGES_DIR="$REPO_DIR/packages"
    BACKUP_DIR="$FAILED_RECOVERY_BACKUP"
    PREEXISTING_LINKS=()

    recover_failed_installation common
) > "$TEST_ROOT/recovery-error.log" 2>&1; then
    echo "FAIL: Recovery unexpectedly succeeded"
    exit 1
fi

if [[ "$(cat "$FAILED_RECOVERY_TARGET/.bashrc")" != "newer configuration" ]]; then
    echo "FAIL: Recovery overwrote an existing configuration"
    exit 1
fi

echo "PASS: Recovery refuses to overwrite existing files"

if [[ "$(cat "$FAILED_RECOVERY_BACKUP/.bashrc")" != "original configuration" ]]; then
    echo "FAIL: Recovery destroyed the original backup"
    exit 1
fi

echo "PASS: Failed recovery preserves backups"

if ! grep -q "Recovery incomplete" "$TEST_ROOT/recovery-error.log"; then
    echo "FAIL: Incomplete recovery was not reported"
    exit 1
fi

echo "PASS: Incomplete recovery reports an error"

echo "Testing end-to-end installation failure recovery..."

E2E_TARGET="$TEST_ROOT/e2e-recovery"
MOCK_BIN="$TEST_ROOT/mock-bin"

mkdir -p "$E2E_TARGET" "$MOCK_BIN"

printf 'original e2e configuration\n' > "$E2E_TARGET/.bashrc"
printf 'unrelated e2e data\n' > "$E2E_TARGET/unrelated.txt"

REAL_STOW="$(command -v stow)"

cat > "$MOCK_BIN/stow" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail

# Forward simulation calls to real GNU Stow.
for arg in "$@"; do
    if [[ "$arg" == "--simulate" ]]; then
        exec "$REAL_STOW_FOR_TEST" "$@"
    fi
done

# Simulate a partially completed installation.
relative_source="$(realpath --relative-to="$MOCK_TARGET" "$EXPECTED_SOURCE")"
ln -s -- "$relative_source" "$MOCK_TARGET/.bashrc"

echo "Simulated GNU Stow failure" >&2
exit 1
MOCK

chmod +x "$MOCK_BIN/stow"

if output="$(
    PATH="$MOCK_BIN:$PATH" \
    REAL_STOW_FOR_TEST="$REAL_STOW" \
    MOCK_TARGET="$E2E_TARGET" \
    EXPECTED_SOURCE="$REPO_DIR/packages/common/.bashrc" \
    "$INSTALLER" \
        --install \
        --backup \
        --package common \
        --target "$E2E_TARGET" 2>&1
)"; then
    echo "FAIL: Simulated installation unexpectedly succeeded"
    exit 1
fi

if [[ "$output" != *"Recovering from failed installation"* ]] ||
   [[ "$output" != *"Recovery completed successfully"* ]]; then
    echo "FAIL: Installer did not complete automatic recovery"
    printf '%s\n' "$output"
    exit 1
fi

echo "PASS: Failed installation triggers automatic recovery"

if [[ -L "$E2E_TARGET/.bashrc" ]] ||
   [[ ! -f "$E2E_TARGET/.bashrc" ]] ||
   [[ "$(cat "$E2E_TARGET/.bashrc")" != "original e2e configuration" ]]; then
    echo "FAIL: Automatic recovery did not restore the original configuration"
    exit 1
fi

echo "PASS: Automatic recovery restores original configuration"

if [[ "$(cat "$E2E_TARGET/unrelated.txt")" != "unrelated e2e data" ]]; then
    echo "FAIL: Automatic recovery modified unrelated files"
    exit 1
fi

echo "PASS: Automatic recovery preserves unrelated files"

echo "All tests passed."
