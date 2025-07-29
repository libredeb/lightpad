![LightPad](https://raw.githubusercontent.com/libredeb/lightpad/master/logo.png)

LightPad is a lightweight, simple and powerful application launcher. It is also Wayland compatible.

This project contributes to [Twister OS](https://twisteros.com/) and collaborates with Ubuntu Budgie (and its [BudgieLightpad Applet](https://github.com/ubuntubudgie/budgie-lightpad-applet) for the operating system) — special thanks to [@fossfreedom](https://github.com/fossfreedom)

## Screenshot
![Screenshot](https://raw.githubusercontent.com/libredeb/lightpad/master/screenshot.png)

## Installation via PPA
Only for Ubuntu based distros, open a terminal and run the next commands:
```sh
sudo add-apt-repository ppa:libredeb/lightpad
sudo apt-get update
sudo apt-get install io.github.libredeb.lightpad
```

## Compilation

   > **NOTE**: packaging files are now tracked in a separated [packaging](https://github.com/libredeb/lightpad/tree/packaging) branch.

   1. Install dependencies:
   * For Ubuntu:
      ```sh
      sudo apt-get install meson ninja-build libgee-0.8-dev libgnome-menu-3-dev cdbs gettext valac libvala-*-dev libglib2.0-dev libgtk-3-dev python3 python3-wheel python3-setuptools gnome-menus
      ```
   * For Fedora:
      ```sh
      sudo dnf install meson ninja-build libgee-devel gnome-menus-devel cdbs gettext vala libvala-devel glib2-devel gtk3-devel python3 python3-wheel python3-setuptools gnome-menus
      ```
   * For Arch Linux:
      ```sh
      sudo pacman -Sy meson ninja libgee gnome-menus gettext vala glib2 gdk-pixbuf2 gtk3 python python-wheel python-setuptools
      ```
   2. Clone this repository into your machine
      ```sh
      git clone https://github.com/libredeb/lightpad.git
      cd lightpad/
      ```
   3. Create a build folder:
      ```sh
      meson setup build --prefix=/usr
      ```
   4. Compile LightPad:
      ```sh
      cd build
      ninja
      ```
   5. Install LightPad in the system:
      ```sh
      sudo ninja install
      ```
   6. (OPTIONAL) Uninstall LightPad:
      ```sh
      sudo ninja uninstall
      ```

## Post Install

Once installed set shortcut key to access LightPad.

  * `System -> Preferences -> Hardware -> Keyboard Shortcuts` then click on `Add` button
  * **Name:** LightPad
  * **Command:** io.github.libredeb.lightpad

Now assign it a shortcut key, such as `CTRL`+`SPACE`.

> **NOTE:** if you want to use another keyboard shortcut like the `SUPER` key to activate LightPad in Desktop Environments in which the `SUPER` key is used, maybe you want to try to disable it first. For example in GNOME Shell you can run next command `gsettings set org.gnome.mutter overlay-key ''` (and if you want to restorte the original behavior, so run next command `gsettings reset org.gnome.mutter overlay-key`).

## Optional Features

Explore LightPad's optional features to personalize your experience! For a full list of available options and their descriptions, run `io.github.libredeb.lightpad --help` in your terminal. Or refer to the binary manual page by using the following command `man io.github.libredeb.lightpad`.

---

### Custom Configuration Support 

- **Generate a template file (-s, --save-config)**

   LightPad supports customization through a simple configuration file.  
   You can adjust visual aspects such as font size, icon size, and the application grid layout.

   To get started, generate a configuration template so that you can edit the parameters later:

   ```sh
   io.github.libredeb.lightpad --save-config
   ```

- **Clear the configuration file (-c, --clear-config)**

   You can also clear the generated custom settings file so that LightPad uses the values that best fit your display by executing the command:

   ```sh
   io.github.libredeb.lightpad --clear-config
   ```

### Dynamic Background (-b, --background)

LightPad now supports using a custom background of your choice. You can use any wallpaper of your choice and LightPad will use them (prioritizing the JPG format):

```sh
io.github.libredeb.lightpad --background /path/to/image[.jpg|.png|.webp]
```

### Blocklist File

Another new functionality is the ability to hide applications using a blocklist file. In the file.

In the file:

> `$HOME/.lightpad/blocklist`

You must add line by line the full name of the binaries of the applications you want to hide in LightPad. For example:
```
nautilus
rhythmbox
gnome-screenshot
gnome-terminal
firefox
htop
/usr/bin/gparted
/usr/bin/vlc
```

These lines appear in the **.desktop** files located in `/usr/share/applications` as the value of the **Exec=** tag.

## Icon Cache

To improve startup performance, LightPad now implements a persistent icon cache.

- **Location:**  
  The cache is located in `$HOME/.lightpad/cache/`.

- **How it works:**  
  On first launch, LightPad loads and scales each application icon, saving a PNG version in the cache directory. On subsequent launches, icons are loaded directly from the cache, significantly reducing startup time.

- **Cache invalidation:**  
  If an application icon changes on the system, the cached version will not be updated automatically. To refresh the cache, simply delete the contents of `$HOME/.lightpad/cache/` and restart LightPad.

- **Troubleshooting:**  
  If you experience missing or outdated icons, try clearing the cache directory and relaunching LightPad.

## Debug LightPad

To show debug messages to see what's happening when LightPad run, you can execute next command:

```sh
pkill -f io.github.libredeb.lightpad; G_MESSAGES_DEBUG=all io.github.libredeb.lightpad
```

## Translations

To add more supported languages, please, edit [LINGUAS](./po/LINGUAS) file and update the translation template file (a.k.a. `pot`) running next command:
```sh
cd build
ninja io.github.libredeb.lightpad-pot
```

And for generate each LINGUA `po` file, run next command:
```sh
ninja io.github.libredeb.lightpad-update-po
```

## Changelog
**Version 0.1.0**
* New intermediate icon cache that improves LightPad startup speed by more than 4 times.
* Translations into Spanish, German, French and Portuguese.
* Fixed [issue #8](https://github.com/libredeb/lightpad/issues/8), Delay on startup
* Fixed [issue #68](https://github.com/libredeb/lightpad/issues/68), Keyboard shortcuts to not work in search bar
* Updated application id to match with binary name.
* Some small performance improvements.

**Version 0.0.10**
* Added more information required in [metainfo.xml](data/io.github.libredeb.lightpad.metainfo.xml.in) file needed by software stores
* Added command line flags to make using optional features easier (see `io.github.libredeb.lightpad --help`)
* Fixed [issue #51](https://github.com/libredeb/lightpad/issues/51), there is no man page for the binary
* Fixed [issue #55](https://github.com/libredeb/lightpad/issues/55), improve criteria for blocklist apps
* Fixed [issue #57](https://github.com/libredeb/lightpad/issues/57), lower case apps names are sorted at the end
* Removed unused `libwnck3` dependency
* Updated deprecated `cairo` code
* Updated the license in the source code headers

**Version 0.0.9**
* Fixed [issue #26](https://github.com/libredeb/lightpad/issues/26), opens in wrong monitor
* Fixed [issue #28](https://github.com/libredeb/lightpad/issues/28), can't run gnome apps
* Fixed [issue #23](https://github.com/libredeb/lightpad/issues/23), can't exit clicking on an empty area
* Fixed [issue #21](https://github.com/libredeb/lightpad/issues/21), items overflow when doubling pixels
* Fixed [issue #5](https://github.com/libredeb/lightpad/issues/5), there are no cursor blinking in the searchbar
* Fixed [issue #9](https://github.com/libredeb/lightpad/issues/9), can't toggle lightpad via keyboard shortcut
* Fixed [issue #16](https://github.com/libredeb/lightpad/issues/16), dependency xterm is no longer required
* Fixed [issue #29](https://github.com/libredeb/lightpad/issues/29), improve xdg application menu files detection

**Version 0.0.8**
* Templates added to make packages for Arch Linux (PKG) and Fedora (RPM)
* Config files are introduced for project constants, replacing the hardcoded paths
* Clean CSS code, some vars and unused functionality
* New feature added: hide apps using a blocklist file.
* The paths of background files are moved to `$HOME/.lightpad/`

**Version 0.0.7**
* Change indicator pages text for dots without animations
* Fixed the CSS design of the searchbar that made it look cut on some screens
* Implemented a new feature, you can use a image as background (dynamically detected if it's exists)
* Added a new feature, now the apps are ordered alphabetically
* Add SPEC and PKGBUILD files to make packages for Fedora and Arch Linux
* Some bug fixing

**Version 0.0.5**
* Implemented the exact and standard way to open terminal apps
* Improved meson postinstall script
* Removed desktop environments detection to use the appropiate terminal
* Added xterm as dependency for opening terminal apps ([deprecated](https://github.com/GNOME/glib/blob/cd1eba043c90da3aee8f5cd51b205b2e2c16f08e/gio/gdesktopappinfo.c#L2467-L2494))

**Version 0.0.4**
* Fix an important bug in the page indicators causing the wrong size obtained
* Background color brightness of page indicators increased
* Improved the visual appearance of the searchbar
* Increased space between top edge of display and searchbar

**Version 0.0.3**
* Fix bug 003, where obtain a negative one causing error obtaining array index for indicator pages
* Add suport for LXQT, LXDE and XFCE environments to open terminal apps
* Improve searchbar design, use CSS instead of cairo

**Version 0.0.2**
* Add dependencies versioning
* Fix a bug with gee assertion index
* Fix bug that cause that terminal apps won't open
* Improve screen recognition for detect netbooks small display

**Version 0.0.1**
* Clean all code from the fork
* New improved searchbar design
* New revamped icon in different resolutions
* Fix bug for some applications that left their icon in /usr/share/pixmaps
* Support for terminal apps
