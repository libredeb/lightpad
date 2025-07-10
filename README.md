![LightPad](logo.png)
# Handheld Version

![handheld running LightPad](handheld.png)

LightPad is a lightweight, simple and powerful application launcher. It is also Wayland compatible.

## Compilation

   > **NOTE**: packaging files are now tracked in a separated [packaging](https://github.com/libredeb/lightpad/tree/packaging) branch.

   1. Install dependencies:
   * For Ubuntu:
   ```sh
      sudo apt-get install meson ninja-build libgee-0.8-dev libgnome-menu-3-dev cdbs valac libvala-*-dev libglib2.0-dev libgtk-3-dev python3 python3-wheel python3-setuptools gnome-menus
   ```
   * For Fedora:
   ```sh
      sudo dnf install meson ninja-build libgee-devel gnome-menus-devel cdbs vala libvala-devel glib-devel gtk3-devel python3 python3-wheel python3-setuptools gnome-menus
   ```
   * For Arch Linux:
   ```sh
      sudo pacman -Sy meson ninja libgee gnome-menus vala glib2 gdk-pixbuf2 gtk3 python python-wheel python-setuptools
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
  * **Command:** com.github.libredeb.lightpad

Now assign it a shortcut key, such as `CTRL`+`SPACE`.

**Note:** Some themes don't have the 'application-default-icon'. LightPad needs to have this icon, so please download it from the [elementary_os/icons](https://github.com/elementary/icons/blob/master/apps/128/application-default-icon.svg) pack and execute the following commands:
```
# cp application-default-icon.svg /usr/share/icons/hicolor/scalable/apps/
# gtk-update-icon-cache /usr/share/icons/hicolor
```

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

## Tested Devices

The handheld version of LightPad has been tested and works as expected on the following devices:

- **Raspberry Pi Zero 2 W**
- **Raspberry Pi 3 Model B+**

Please note that performance and appearance may vary slightly depending on the device's screen resolution.


## Changelog

**Handheld version release candidate 1:**
* Deleted searchbar
* Deleted dinamic background
* Adapted to squared screens
* 3x3 application grid