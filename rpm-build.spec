Name:        	lightpad   
Version:        0.0.7
Release:        1
Summary:        LightPad Launcher
License:        GPL
Group:		Utilities/System

URL:            https://github.com/libredeb/lightpad
Source0:        lightpad-0.0.7.tar.gz
BuildRoot:	%{_tmppath}/%{name}-%{version}-build

BuildRequires:  meson
BuildRequires:  ninja-build
BuildRequires:  libgee-devel
BuildRequires:  gnome-menus-devel
BuildRequires:  cdbs
BuildRequires:  vala
BuildRequires:  vala-devel
BuildRequires:  glib-devel
BuildRequires:  libwnck-devel
BuildRequires:  gtk3-devel
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
Requires:	libwnck3
Requires:   	xterm 

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

%files
%defattr(-,root,root)
%{_bindir}/com.github.libredeb.lightpad
%{_datadir}/applications/com.github.libredeb.lightpad.desktop
%{_datadir}/icons/hicolor/128x128/apps/lightpad.svg
%{_datadir}/icons/hicolor/24x24/apps/lightpad.svg
%{_datadir}/icons/hicolor/32x32/apps/lightpad.svg
%{_datadir}/icons/hicolor/48x48/apps/lightpad.svg
%{_datadir}/icons/hicolor/64x64/apps/lightpad.svg
%{_datadir}/lightpad/application.css
%{_datadir}/metainfo/com.github.libredeb.lightpad.appdata.xml

%changelog
