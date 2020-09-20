![LightPad](https://raw.githubusercontent.com/libredeb/lightpad/feature/launcher-piboy/logo.png)

This version of LightPad is a variation of the launcher designed for the PiBoy screen keeping in mind the limitations of lack of keyboard and screen resolution of 640x480 pixels.

This branch will keep the development of this version in parallel with master.

## Screenshot
![Screenshot](https://raw.githubusercontent.com/libredeb/lightpad/feature/launcher-piboy/screenshot.png)

## Mapped Keys
Now LightPad can be controlled using the W, A, S and D keys mapped to the different directions of the **D-pad**. When LightPad runs and opens, the focus of the app items is automatically placed for you on the 1st element.

## Compilation

   1. Install dependencies:
   * For Debian:
   ```
      $ sudo apt-get install meson ninja-build libgee-0.8-dev libgnome-menu-3-dev cdbs valac libvala-0.42-dev libglib2.0-dev libwnck-3-dev libgtk-3-dev xterm python3 python3-wheel python3-setuptools gnome-menus
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

## Dynamic Background (optional feature)

LighPad added a new feature, now you can use a custom background of your choice. You can add any wallpaper or image strictly under some of the following path/files and lightpad will use them (prioritizing the JPG format):
> `$HOME/.lightpad/background.jpg`

> `$HOME/.lightpad/background.png`

## Blacklist File (optional feature)

Another new added functionality, is the ability to hide applications using a blacklist file. In the file:
> `$HOME/.lightpad/blacklist`

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


## Changelog
**Version 0.0.11**
* Added support for screens with resolution of 640x480 pixels (like PiBoy)
* Fixed the grab focus event in the 1st element of the 1st page when LightPad runs and opens.
* Added the ability to control the movement of the focus with the W, S, A and D keys (D-pad mapped).
* Hide the Searchbar to take advantage of screen space.

**Version 0.0.8**
* Templates added to make packages for Arch Linux (PKG) and Fedora (RPM)
* Config files are introduced for project constants, replacing the hardcoded paths
* Clean CSS code, some vars and unused functionality
* New feature added: hide apps using a blacklist file.
* The paths of background files are moved to `$HOME/.lightpad/`

**Version 0.0.7**
* Change indicator pages text for dots without animations
* Fixed the CSS design of the searchbar that made it look cut on some screens
* Implemented a new feature, now the black background is dynamic using an image if there exists
* Added a new feature, now the apps are ordered alphabetically
* Add SPEC and PKGBUILD files to make packages for Fedora and Arch Linux
* Some bug fixing

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
