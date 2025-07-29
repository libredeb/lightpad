Name:        	lightpad   
Version:        0.1.0
Release:        1%{?dist}
Summary:        LightPad Launcher
License:        GPL
Group:		    Utilities/System

URL:            https://github.com/libredeb/lightpad
Source0:        https://github.com/libredeb/%{name}/archive/refs/tags/%{version}.tar.gz
BuildRoot:	    %{_tmppath}/%{name}-%{version}-build

BuildRequires:  meson
BuildRequires:  ninja-build
BuildRequires:  cdbs
BuildRequires:  gettext
BuildRequires:  vala >= 0.56.0
BuildRequires:  libvala-devel >= 0.56.0
BuildRequires:  libgee-devel >= 0.18.0
BuildRequires:  gnome-menus-devel >= 3.13.0
BuildRequires:  glib2-devel >= 2.76.0
BuildRequires:  gtk3-devel >= 3.22.0
BuildRequires:  python3
BuildRequires:  python3-wheel
BuildRequires:  python3-setuptools

Requires:	glibc
Requires:	cairo
Requires:	gdk-pixbuf2
Requires:	libgee
Requires:	glib2
Requires:	gnome-menus
Requires:	gtk3

%description
LightPad is a lightweight, simple and powerful application launcher.
Written in GTK+ 3.0. It is also Wayland compatible.

%prep
%setup -q

%build
%{meson}
%{meson_build}

%install
%{meson_install}

%check
file %{_bindir}/io.github.libredeb.lightpad

%files
%defattr(-,root,root)
%{_bindir}/io.github.libredeb.lightpad
%{_datadir}/applications/io.github.libredeb.lightpad.desktop
%{_datadir}/icons/hicolor/128x128/apps/lightpad.svg
%{_datadir}/icons/hicolor/24x24/apps/lightpad.svg
%{_datadir}/icons/hicolor/32x32/apps/lightpad.svg
%{_datadir}/icons/hicolor/48x48/apps/lightpad.svg
%{_datadir}/icons/hicolor/64x64/apps/lightpad.svg
%{_datadir}/icons/hicolor/scalable/apps/application-default-icon.svg
%{_datadir}/lightpad/application.css
%{_datadir}/metainfo/io.github.libredeb.lightpad.metainfo.xml
%{_datadir}/man/man1/io.github.libredeb.lightpad.1.gz
%{_datadir}/locale/es/LC_MESSAGES/io.github.libredeb.lightpad.mo
%{_datadir}/locale/de/LC_MESSAGES/io.github.libredeb.lightpad.mo
%{_datadir}/locale/fr/LC_MESSAGES/io.github.libredeb.lightpad.mo
%{_datadir}/locale/pt/LC_MESSAGES/io.github.libredeb.lightpad.mo

%changelog
* Sun Jul  20 2025 Juan Pablo Lozano <libredeb@gmail.com> - 0.1.0
- New intermediate icon cache that improves LightPad startup speed by more than 4 times.
- Translations into Spanish, German, French and Portuguese.
- Some resolved issues (#8, #68)
- Some small performance improvements.
* Sat May  24 2025 Juan Pablo Lozano <libredeb@gmail.com> - 0.0.10
- This release brings significant improvements
- Some resolved issues (#51, #55, #57)
- Removal of unused dependencies
* Sun May  04 2025 Juan Pablo Lozano <libredeb@gmail.com> - 0.0.9
- A bunch of resolved issues (#5, #9, #16, #21, #23, #26, #28, #29)
- Performance improved
