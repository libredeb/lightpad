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
     public const string CONFIG_FILE = LIGHTPAD_CONFIG_DIR + "/config";
     public const string XDG_FALLBACK_MENU = "applications.menu";
     public const string LIGHTPAD_BACKGROUND = LIGHTPAD_CONFIG_DIR + "/background.jpg";
     public const GLib.OptionEntry[] LIGHTPAD_OPTIONS = {
          // long flag, short flag, flag behavior, flag args, bind variable, message, value
          {
               "version",
               'v',
               OptionFlags.NONE,
               OptionArg.NONE,
               null,
               "Display version number",
               null
          },
          {
               "save-config",
               's',
               OptionFlags.NONE,
               OptionArg.NONE,
               null,
               "Store default configuration values in ~/.lightpad/config",
               null
          },
          {
               "clear-config",
               'c',
               OptionFlags.NONE,
               OptionArg.NONE,
               null,
               "Clear the stored configuration to restore the default state",
               null
          },
          {
               "background IMAGE_FILE_PATH",
               'b',
               OptionFlags.NONE,
               OptionArg.FILENAME,
               null,
               "Use an image as launcher background",
               null
          },

          // list terminator
          { null }
     };
}
