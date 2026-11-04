# Rodger's Dotfiles

Personal Linux configuration files, managed with [GNU Stow](https://www.gnu.org/software/stow/).

This repository provides a modular configuration setup designed to work across multiple Linux distributions and desktop environments.

## Supported Environments

### Linux distributions

- PopOS
- Fedora Workstation
- Bazzite
- CachyOS

### Desktop environments

- COSMIC
- GNOME
- KDE Plasma

The installer automatically detects the current Linux distribution and desktop environment. Both can also be selected manually.

## Repository Structure

```text
dotfiles/
├── packages/
│   ├── common/          # Shared configuration files
│   ├── terminal/        # Terminal emulator configuration
│   ├── fonts/           # Custom fonts
│   ├── appearance/      # Icons and appearance assets
│   ├── desktop-cosmic/  # COSMIC-specific configuration
│   ├── desktop-gnome/   # GNOME-specific configuration
│   ├── desktop-kde/     # KDE-specific configuration
│   ├── distro-pop-os/   # Pop!_OS-specific configuration
│   ├── distro-fedora/   # Fedora-specific configuration
│   ├── distro-bazzite/  # Bazzite-specific configuration
│   └── distro-cachyos/  # CachyOS-specific configuration
├── distros/             # Distribution-specific setup resources
├── machines/            # Machine-specific resources
├── scripts/
│   └── install.sh       # Installation and uninstallation script
├── docs/                # Detailed documentation
└── README.md
```

Some desktop and distribution packages are currently placeholders and will be populated as needed.

## Requirements

- Bash
- GNU Stow
- Git

## Installation

**Development status:** The installer currently restricts actual installation and uninstallation to isolated target directories. Direct deployment into the real home directory is not yet enabled.

Clone the repository:

```bash
git clone https://github.com/RodgerOliver/dotfiles.git
cd dotfiles
```

While the modernization work is in progress, use the `modernize` branch:

```bash
git switch modernize
```

### Preview an installation

Dry-run is the default behavior:

```bash
./scripts/install.sh --dry-run
```

To preview installation into a temporary directory:

```bash
mkdir -p /tmp/dotfiles-test

./scripts/install.sh \
    --dry-run \
    --target /tmp/dotfiles-test
```

### Install into an isolated directory

```bash
./scripts/install.sh \
    --install \
    --target /tmp/dotfiles-test
```

GNU Stow creates symbolic links to the files in this repository.

### Select a distribution and desktop

```bash
./scripts/install.sh \
    --dry-run \
    --distro fedora \
    --desktop gnome \
    --target /tmp/dotfiles-test
```

Supported distribution values: `pop-os`, `fedora`, `bazzite`, `cachyos`, `none`.

Supported desktop values: `cosmic`, `gnome`, `kde`, `none`.

Using `none` disables automatic selection of that category.

### Select specific packages

```bash
./scripts/install.sh \
    --dry-run \
    --package common \
    --package terminal \
    --target /tmp/dotfiles-test
```

Explicit package selection replaces automatic package selection.

### Exclude optional assets

```bash
./scripts/install.sh \
    --dry-run \
    --no-fonts \
    --no-appearance \
    --target /tmp/dotfiles-test
```

## Backups and Recovery

The installer supports `--backup` for handling conflicting files during installation.

```bash
./scripts/install.sh \
    --install \
    --backup \
    --target /tmp/dotfiles-test
```

It also includes recovery logic for failed installations.

Backups are not automatically restored when packages are uninstalled.

## Uninstallation

To remove managed symbolic links from an isolated target:

```bash
./scripts/install.sh \
    --uninstall \
    --target /tmp/dotfiles-test
```

GNU Stow removes links belonging to the selected packages without intentionally deleting unrelated files.

The `--backup` option cannot be combined with `--uninstall`.

## Documentation

- [Installer, Backups, and Recovery](docs/installer.md)

## Development

Check script syntax:

```bash
bash -n scripts/install.sh
```

Check patch formatting:

```bash
git diff --check
```

All installation and uninstallation tests should use isolated directories under `/tmp` until direct home-directory deployment has been reviewed and enabled.

### Automated Tests

Run the installer test suite:

```bash
./tests/test_install.sh
```

The test suite covers:

- Distribution and desktop selection
- Explicit package selection
- Invalid arguments
- Dry-run safety
- Installation and uninstallation
- Conflicting files and backups
- Successful and incomplete recovery
- End-to-end installation failure recovery

All filesystem-changing tests use isolated temporary directories.

## License

No license has been specified for this repository.
