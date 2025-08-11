/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020 Juan Pablo Lozano <libredeb@gmail.com>
 */

/*
 * Here are declared constants and others resources
 */
namespace Resources {
     public const string LIGHTPAD_CONFIG_DIR = "/." + Config.PROJECT_NAME;
     public const string BLOCKLIST_FILE = LIGHTPAD_CONFIG_DIR + "/blocklist";
     public const string PIXMAPS_DIR = "/usr/share/pixmaps/";
     public const string CACHE_DIR = LIGHTPAD_CONFIG_DIR + "/cache";

     // Custom exit app
     public const string LIGHTPAD_EXIT_ID = ".lightpad-exit";
     public const string LIGHTPAD_EXIT_NAME = "Exit LightPad";
     public const string LIGHTPAD_EXIT_DESC = "Exit LightPad and return to the desktop";
     public const string LIGHTPAD_EXIT_CMD = "bash -c 'pkill -f com.github.libredeb.lightpad'";
}
