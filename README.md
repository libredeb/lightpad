![LightPad](https://raw.githubusercontent.com/libredeb/lightpad/master/logo.png)

LightPad is a lightweight, simple and powerful application launcher. It is also Wayland compatible.

This project was originally forked from Slingshot from the elementary team:

  * [https://launchpad.net/slingshot](https://launchpad.net/slingshot)

## Screenshot
![Screenshot](https://raw.githubusercontent.com/libredeb/lightpad/master/screenshot.png)

## Compilation

   1. Install dependencies:
   * For Ubuntu:
   ```
      $ sudo apt-get install meson ninja-build libgee-0.8-dev libgnome-menu-3-dev cdbs valac libvala-*-dev libglib2.0-dev libwnck-3-dev libgtk-3-dev xterm python3 python3-wheel python3-setuptools gnome-menus
   ```
   * For Fedora:
   ```
      $ sudo dnf install meson ninja-build libgee-devel gnome-menus-devel cdbs vala libvala-devel glib-devel libwnck-devel gtk3-devel xterm python3 python3-wheel python3-setuptools gnome-menus
   ```
   2. Create a build folder:
   ```
      $ meson build --prefix=/usr
   ```
   3. Compile LightPad:
   ```
      $ cd build
      $ ninja
   ```
   4. Install LightPad in the system:
   ```
      $ sudo ninja install
   ```
   5. (OPTIONAL) Uninstall LightPad:
   ```
      $ sudo ninja uninstall
   ```

## Post Install

Once installed set shortcut key to access LightPad.

  * System -> Preferences -> Hardware -> Keyboard Shortcuts > click Add
  * Name: LightPad
  * Command: com.github.libredeb.lightpad

Now assign it a shortcut key, such as CTRL+SPACE.

Note: Some themes don't have the 'application-default-icon'. LightPad needs to have this icon, so please download it from the [FlatWoken](https://github.com/alecive/FlatWoken) icon pack and execute the following commands:
```
# cp application-default-icon.svg /usr/share/icons/hicolor/scalable/apps/
# gtk-update-icon-cache /usr/share/icons/hicolor
```

## Changelog
**Version 0.0.5**
* Implemented the exact and standard way to open terminal apps
* Improved meson postinstall script
* Removed desktop environments detection to use the appropiate terminal
* Added xterm as dependency for opening terminal apps

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
