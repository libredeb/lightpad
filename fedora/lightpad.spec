Name:        	lightpad   
Version:        0.0.9
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
file %{_bindir}/com.github.libredeb.lightpad

%files
%defattr(-,root,root)
%{_bindir}/com.github.libredeb.lightpad
%{_datadir}/applications/com.github.libredeb.lightpad.desktop
%{_datadir}/icons/hicolor/128x128/apps/lightpad.svg
%{_datadir}/icons/hicolor/24x24/apps/lightpad.svg
%{_datadir}/icons/hicolor/32x32/apps/lightpad.svg
%{_datadir}/icons/hicolor/48x48/apps/lightpad.svg
%{_datadir}/icons/hicolor/64x64/apps/lightpad.svg
%{_datadir}/icons/hicolor/scalable/apps/application-default-icon.svg
%{_datadir}/lightpad/application.css
%{_datadir}/metainfo/com.github.libredeb.lightpad.appdata.xml
%{_datadir}/man/man1/com.github.libredeb.lightpad.1.gz

%changelog
* Sun May  04 2025 Juan Pablo Lozano <libredeb@gmail.com> - 0.0.9
- A bunch of resolved issues (#5, #9, #16, #21, #23, #26, #28, #29)
- Performance improved
