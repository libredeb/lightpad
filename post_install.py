#!/usr/bin/env python3

import os
import subprocess

hicolor = os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share', 'icons', 'hicolor')

if not os.environ.get('DESTDIR'):
    print('Updating icon cache...')
    subprocess.call(['gtk-update-icon-cache', '-q', '-t' ,'-f', hicolor])
