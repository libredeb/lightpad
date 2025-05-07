# How to create RPM package

RPM stands for Red Hat Package Manager. An RPM package uses the .rpm extension and is a bundle (a collection) of different files. It can contain the following:

  - Binary files, also known as executables.
  - Configuration files.
  - Documentation files.

The name of an RPM package follows this format: `<name>-<version>-<release>.<arch>.rpm`. An example: `lightpad-0.0.9-1fc42.x86_64.rpm`.

## Installing the required software

The following packages need to be installed to build the RPM package:

```sh
sudo dnf install -y rpmdevtools rpmlint
```

After installing `rpmdevtools` package, the first time you need to create the file tree required to build RPM packages:

```sh
rpmdev-setuptree
```

> **NOTE:** You build RPM packages as a normal user (not root), so your build environment is placed into your home directory. It contains this directory structure:
>
>```sh
>rpmbuild/
>├── BUILD
>├── RPMS
>├── SOURCES
>├── SPECS
>└── SRPMS
>```
>
> - **BUILD directory:** is used during the build process of the RPM package. This is where the temporary files are stored, moved around, etc.
> - **RPMS directory:** holds RPM packages built for different architectures and noarch if specified in .spec file or during the build.
> - **SOURCES directory:** as the name implies, holds the source code. Usually, the sources are compressed as .tar.gz or .tgz files.
> - **SPEC directory:** contains the .spec files. The .spec file defines how a package is built.
> - **SRPMS directory:** holds the .src.rpm packages.

## Place the source code in the designated directory

Move the tarball of LightPad to the `SOURCES` directory:

```sh
mv v0.0.9.tar.gz ~/rpmbuild/SOURCES/0.0.9.tar.gz
```

## Move the specification file

You must move the `.spec` file to the `SPECS` directory:

```sh
mv fedora/lightpad.spec ~/rpmbuild/SPECS/
```

## Checking the specification file on error

The `rpmlint` command can find errors in `.spec` files:

```sh
rpmlint ~/rpmbuild/SPECS/lightpad.spec
```

## Building the package

To build the RPM package, use the `rpmbuild` command:

```sh
rpmbuild -bb ~/rpmbuild/SPECS/lightpad.spec
```

> **NOTE:** the `-bb` flag have the following meanings "build binary".
