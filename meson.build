# Project name and programming language
project(
    'io.github.libredeb.lightpad',
    'vala', 'c',
    version: '0.1.0',
    meson_version: '>=0.56.0'
)

# Include the translations module
i18n = import('i18n')
# Set our translation domain
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

PROJECT_NAME = 'lightpad'
prefix = get_option('prefix')
libdir = join_paths(prefix, get_option('libdir'))
datadir = join_paths(prefix, get_option('datadir'))

VAPI_DIR = join_paths(meson.project_source_root(), 'vapi')
vala = meson.get_compiler('vala')

# Global configuration data - matches vapi/config.vapi strings
conf = configuration_data()
conf.set_quoted('PROJECT_NAME', PROJECT_NAME)
conf.set_quoted('PACKAGE_LIBDIR', libdir)
conf.set_quoted('PACKAGE_SHAREDIR', datadir)
conf.set_quoted('PACKAGE_VERSION', meson.project_version())

config_h = configure_file(
	output: 'config.h',
	configuration: conf
)

config_dep = declare_dependency(
	dependencies: vala.find_library('config', dirs: VAPI_DIR),
	sources: config_h
)

config_inc_dir = include_directories('.')

LightpadValaArgs = [
    '--pkg=config',
    '--vapidir=' + VAPI_DIR,
    '--target-glib=2.76',
]

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    meson.project_name(),
    'src/Application.vala',
    'src/DesktopEntries.vala',
    'src/Utilities.vala',
    'src/Color.vala',
    'src/Resources.vala',
    'src/Config.vala',
    'src/ConfigTypes.vala',
    'src/Widgets/CompositedWindow.vala',
    'src/Widgets/Searchbar.vala',
    'src/Widgets/Indicators.vala',
    'src/Widgets/AppItem.vala',
    dependencies: [
        dependency('gio-unix-2.0', version: '>=2.56.0'),
        dependency('glib-2.0', version: '>=2.76.0'),
        dependency('gtk+-3.0', version: '>=3.22'),
        dependency('gdk-3.0', version: '>=3.22.0'),
        dependency('cairo', version: '>=1.15.0'),
        dependency('pango', version: '>=1.40.0'),
        dependency('gee-0.8', version: '>=0.20.0'),
        dependency('libgnome-menu-3.0', version: '>=3.13.0'),
        # Similar to add options "-X -lm" in cmake to use Math.pow()
        meson.get_compiler('c').find_library('m', required: false)
    ],
    c_args: [
        '-DGMENU_I_KNOW_THIS_IS_UNSTABLE', '-w'
    ],
    vala_args: LightpadValaArgs,
    include_directories: config_inc_dir,
    install: true
)

# Install CSS file
install_data(
    join_paths('data', 'application.css'),
    install_dir: join_paths(datadir, PROJECT_NAME)
)

# Install app icons
icon_sizes = ['24', '32', '48', '64', '128']
foreach i : icon_sizes
    install_data(
        join_paths('data', 'icons', i, 'lightpad.svg'),
        install_dir: join_paths(datadir, 'icons', 'hicolor', i + 'x' + i, 'apps')
    )
endforeach

# Install application-default-icon for applications without icons
install_data(
    join_paths('data', 'icons', 'application-default-icon.svg'),
    install_dir: join_paths(datadir, 'icons', 'hicolor', 'scalable', 'apps')
)

#Translate and install our .desktop file
i18n.merge_file(
    input: 'data' / meson.project_name() + '.desktop.in',
    output: meson.project_name() + '.desktop',
    po_dir: meson.project_source_root() / 'po',
    type: 'desktop',
    install: true,
    install_dir: get_option('datadir') / 'applications'
)

#Translate and install our .metainfo file
i18n.merge_file(
    input: 'data' / meson.project_name() + '.metainfo.xml.in',
    output: meson.project_name() + '.metainfo.xml',
    po_dir: meson.project_source_root() / 'po',
    install: true,
    install_dir: get_option('datadir') / 'metainfo'
)

# Install manual page
run_command('gzip', '-fk', join_paths('data', meson.project_name() + '.1'), check: true)

install_data(
    join_paths('data', meson.project_name() + '.1.gz'),
    install_dir: join_paths(datadir, 'man', 'man1')
)

meson.add_install_script('post_install.py')

subdir('po')
