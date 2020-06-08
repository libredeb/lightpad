#!/usr/bin/env python3

import os
import subprocess

hicolor = os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share', 'icons', 'hicolor')
bin_dir = os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'bin')
texec_sh = os.path.join(os.environ['MESON_SOURCE_ROOT'], 'data', 'lightpad_texec')

if not os.environ.get('DESTDIR'):
    print('Updating icon cache...')
    subprocess.call(['gtk-update-icon-cache', '-q', '-t' ,'-f', hicolor])
    subprocess.call(['cp', texec_sh, bin_dir])
