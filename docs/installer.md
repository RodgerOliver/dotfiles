# Installer, Backups, and Recovery

This document describes the dotfiles installer and its backup, recovery, and uninstallation behavior.

## Development Status

The installer is currently under development. Actual installation and uninstallation are restricted to isolated target directories.

Do not deploy directly to your real `$HOME` until the installer has completed testing and the restriction has been deliberately removed.

## Installation Modes

The installer supports three primary operations:

| Option | Behavior |
|---|---|
| `--dry-run` | Preview changes without modifying files (default) |
| `--install` | Create GNU Stow symlinks |
| `--uninstall` | Remove GNU Stow-managed symlinks |

Use an isolated directory for testing:

```bash
mkdir -p /tmp/dotfiles-test
./scripts/install.sh --install --target /tmp/dotfiles-test
```


## Copy installation method

The installer supports two methods:

- `stow` (default): Creates symbolic links using GNU Stow.
- `copy`: Copies configuration files using rsync.

### Preview a copy installation

```bash
./scripts/install.sh --dry-run --method copy
```

### Install using copies

```bash
./scripts/install.sh --install --method copy --backup --allow-home
```

### Install into a custom directory

```bash
./scripts/install.sh --install --method copy --backup --target /path/to/target
```

### Copy mode behavior

- Requires rsync.
- Requires `--backup` for actual installations.
- Stores backups in `.dotfiles-backups/` inside the target directory.
- Preserves relative symbolic links from packages.
- Rejects conflicting package destinations.
- Rejects symlinked destination paths.
- Does not delete unrelated files.
- Does not support `--uninstall`.

### Limitations

Copy mode does not currently support automatic rollback.

If installation fails or is interrupted, original files must be
restored manually from the backup directory.

Newly created files are not backed up.

Use `--allow-home` when installing into your actual home directory.

## Configuration Selection

By default, the installer selects shared packages and applicable distribution and desktop packages.

Use `--distro` and `--desktop` to override automatic detection.

Use repeated `--package` options to select specific packages instead of the automatic selection.

Use `--no-fonts` and `--no-appearance` to exclude optional assets during automatic selection.

## Backup Behavior

By default, conflicting files are not automatically overwritten.

The `--backup` option allows the installer to move detected conflicting files into a backup directory before creating symlinks.

Example:

```bash
./scripts/install.sh \
    --install \
    --backup \
    --target /tmp/dotfiles-test
```

### Backup location

Backups are created under:

```text
<TARGET>/.dotfiles-backups/YYYYMMDD-HHMMSS-XXXXXX/
```

Each backup directory receives a unique suffix to prevent collisions.

For example, a conflict involving `.bashrc` may produce:

```text
/tmp/dotfiles-test/
├── .bashrc -> /path/to/dotfiles/packages/common/.bashrc
└── .dotfiles-backups/
    └── 20261104-145000-AbCdEf/
        └── .bashrc
```

The timestamp and suffix shown above are illustrative.

The installer prints the backup directory path when backups are created.

### Backup safety

The installer checks paths before moving conflicting files. It rejects unsafe relative paths and paths with symlinked parent directories.

If moving a conflicting file fails, it attempts to roll back earlier backup moves.

If rollback is incomplete, the installer reports an error and warns that manual recovery may be required.

## Failed Installation Recovery

When an installation fails, the installer attempts to:

1. Remove newly created symlinks belonging to the attempted installation.
2. Preserve pre-existing symlinks.
3. Restore files moved into the backup directory.
4. Report whether recovery completed successfully.

Recovery is designed to avoid overwriting existing files or following unsafe destination paths.

**Recovery is best-effort.** Filesystem errors, unexpected modifications, or other failures can prevent complete restoration.

If the installer reports `CRITICAL: Recovery incomplete`, inspect the target and backup directory before making further changes.

## Uninstallation

Preview removal:

```bash
./scripts/install.sh \
    --uninstall \
    --dry-run \
    --target /tmp/dotfiles-test
```

Remove managed symlinks:

```bash
./scripts/install.sh \
    --uninstall \
    --target /tmp/dotfiles-test
```

Uninstallation uses GNU Stow's delete operation.

It does not intentionally delete unrelated files and does not automatically restore backed-up configurations.

The installer rejects `--backup` when combined with `--uninstall`.

Use the same package selection when uninstalling that was used during installation, particularly if explicit `--package`, `--distro`, or `--desktop` overrides were used.

## Manual Backup Restoration

After uninstalling, backed-up files can be restored manually.

First, inspect the backup directory:

```bash
find /tmp/dotfiles-test/.dotfiles-backups -mindepth 1 -print
```

Then restore individual files only after confirming the destination does not already exist.

For example:

```bash
backup="/tmp/dotfiles-test/.dotfiles-backups/REPLACE_WITH_BACKUP_DIRECTORY"

if [[ ! -e /tmp/dotfiles-test/.bashrc &&
      ! -L /tmp/dotfiles-test/.bashrc ]]; then
    cp -a -- "$backup/.bashrc" /tmp/dotfiles-test/.bashrc
fi
```

Replace the placeholder with the actual backup directory name printed by the installer.

Never blindly copy backups over existing files or symlinks.

## Troubleshooting

### GNU Stow reports conflicts

Inspect the conflicting paths. Use `--backup` if you want the installer to preserve the existing files before installing symlinks.

### Installation recovery is incomplete

Review the reported backup directory and the target filesystem. Preserve the remaining backup files until recovery is complete.

### Uninstallation reports conflicts

Check whether managed symlinks have been replaced, modified, or redirected. GNU Stow may refuse to remove links that no longer match its expected ownership.

### Previous configuration is missing after uninstall

Check `.dotfiles-backups` under the installation target. Backups are intentionally not restored automatically during uninstallation.

## Development Validation

Check syntax and formatting:

```bash
bash -n scripts/install.sh
git diff --check
```

Use isolated temporary targets for all filesystem-changing tests.

Do not run installation or uninstallation against your real home directory during development.
