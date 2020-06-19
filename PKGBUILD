pkgname=lightpad
pkgver=0.0.7
pkgrel=3
pkgdesc="Lightweight, simple and powerful application launcher"
arch=('x86_64')
url="https://github.com/libredeb/lightpad"
license=('GPL3')
depends=('libgee>=0.18.0' 'gnome-menus>=3.13.0' 'libwnck3>=3.20.0' 'glib2>=2.50.0' 'glibc>=2.28.0' 'gtk3>=3.22.0' 'cairo>=1.15.0' 'gdk-pixbuf2>=2.36.0' 'xterm')
makedepends=('meson' 'ninja' 'vala>=0.28.0')
source=("https://github.com/libredeb/lightpad/archive/v$pkgver.tar.gz")
sha256sums=("SKIP")

prepare() {
  rm -rf build
}

build() {
  cd "$srcdir/$pkgname-$pkgver"
  meson . build --prefix /usr
  ninja -C build
}

package() {
  cd "$srcdir/$pkgname-$pkgver"
  DESTDIR="$pkgdir" ninja -C build install
}

