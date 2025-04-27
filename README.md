![LightPad](https://raw.githubusercontent.com/libredeb/lightpad/master/logo.png)

LightPad is a lightweight, simple and powerful application launcher. It is also Wayland compatible.

It is being developed for [Twister OS](https://twisteros.com/) and in collaboration with Ubuntu Budgie (and its [BudgieLightpad Applet](https://github.com/ubuntubudgie/budgie-lightpad-applet) for the system), a big thanks to [@fossfreedom](https://github.com/fossfreedom)

This project was originally forked from Slingshot from the elementary team:

  * [https://launchpad.net/slingshot](https://launchpad.net/slingshot)

## Screenshot
![Screenshot](https://raw.githubusercontent.com/libredeb/lightpad/master/screenshot.png)

## Installation via PPA
Only for Ubuntu based distros, open a terminal and run the next commands:
```
$ sudo add-apt-repository ppa:libredeb/lightpad
$ sudo apt-get update
$ sudo apt-get install com.github.libredeb.lightpad
```

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
   * For Arch Linux:
   ```
      $ sudo pacman -Sy meson ninja libgee gnome-menus vala glib2 gdk-pixbuf2 libwnck3 gtk3 xterm python python-wheel python-setuptools
   ```
   2. Clone this repository into your machine
   ```
     $ git clone https://github.com/libredeb/lightpad.git
     $ cd lightpad/
   ```
   3. Create a build folder:
   ```
      $ meson setup build --prefix=/usr
   ```
   4. Compile LightPad:
   ```
      $ cd build
      $ ninja
   ```
   5. Install LightPad in the system:
   ```
      $ sudo ninja install
   ```
   6. (OPTIONAL) Uninstall LightPad:
   ```
      $ sudo ninja uninstall
   ```

## Post Install

Once installed set shortcut key to access LightPad.

  * System -> Preferences -> Hardware -> Keyboard Shortcuts > click Add
  * Name: LightPad
  * Command: com.github.libredeb.lightpad

Now assign it a shortcut key, such as `CTRL`+`SPACE`.

> **NOTE:** if you want to use another keyboard shortcut like the `SUPER` key to activate LightPad in Desktop Environments in which the `SUPER` key is used, maybe you want to try to disable the it first. For example in GNOME Shell you can run next command `gsettings set org.gnome.mutter overlay-key ''` (and if you want to restorte the original behavior, so run next command `gsettings reset org.gnome.mutter overlay-key`).

**Note:** Some themes don't have the 'application-default-icon'. LightPad needs to have this icon, so please download it from the [elementary_os/icons](https://github.com/elementary/icons/blob/master/apps/128/application-default-icon.svg) pack and execute the following commands:
```
# cp application-default-icon.svg /usr/share/icons/hicolor/scalable/apps/
# gtk-update-icon-cache /usr/share/icons/hicolor
```

## Dynamic Background (optional feature)

LighPad added a new feature, now you can use a custom background of your choice. You can add any wallpaper or image strictly under some of the following path/files and lightpad will use them (prioritizing the JPG format):
> `$HOME/.lightpad/background.jpg`

> `$HOME/.lightpad/background.png`

## Blocklist File (optional feature)

Another new added functionality, is the ability to hide applications using a blocklist file. In the file:
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


## Changelog
**Version 0.0.9**
* Fixed [issue #26](https://github.com/libredeb/lightpad/issues/26), opens in wrong monitor
* Fixed [issue #28](https://github.com/libredeb/lightpad/issues/28), can't run gnome apps
* Fixed [issue #23](https://github.com/libredeb/lightpad/issues/23), can't exit clicking on an empty area
* Fixed [issue #5](https://github.com/libredeb/lightpad/issues/5), there are no cursor blinking in the searchbar
* Fixed [issue #9](https://github.com/libredeb/lightpad/issues/9), can't toggle lightpad via keyboard shortcut
* Release in progress... 

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
