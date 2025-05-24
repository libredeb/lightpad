# Packaging Files

This branch contains packaging-related files for building and distributing the project on various GNU/Linux distributions.

## Included Directories

- `archlinux` - Build script for Arch Linux packages.
- `debian` – Packaging scripts and metadata for building `.deb` packages (Debian, Ubuntu).
- `fedora` – RPM spec file for building `.rpm` packages (Fedora, openSUSE, etc.).
- `ubuntu` – Notes and instructions for maintaining a Personal Package Archive (PPA).

## Usage

These files are not intended to be used standalone. To build packages, clone the full project repository and switch to this branch:

```bash
git clone https://github.com/libredeb/lightpad.git
cd lightpad/
git checkout origin/packaging -- debian
```

You may then use the appropriate tools for your target distribution to build the package, for example:

  - `debuild` for Debian-based systems
  - `rpmbuild` for RPM-based systems
  - `makepkg` for Arch Linux