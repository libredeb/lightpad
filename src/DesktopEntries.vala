/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020 Juan Pablo Lozano <libredeb@gmail.com>
 */

namespace LightPad.Backend {

    public class DesktopEntries : GLib.Object {

        private static Gee.ArrayList<GMenu.TreeDirectory> get_categories () {
            var tree = new GMenu.Tree ("applications.menu", GMenu.TreeFlags.INCLUDE_EXCLUDED);
            try {
                // Initialize the tree
                tree.load_sync ();
            } catch (GLib.Error e) {
                error ("Initialization of the GMenu.Tree failed: %s", e.message);
            }
            var root = tree.get_root_directory ();
            var main_directory_entries = new Gee.ArrayList<GMenu.TreeDirectory> ();
            string? included_categories = GLib.Environment.get_variable ("LIGHTPAD_CATEGORIES");
            Gee.HashSet<string>? allowed = null;
            if (included_categories != null) {
                allowed = new Gee.HashSet<string> ();
                foreach (var cat in included_categories.split (",")) {
                    allowed.add (cat.strip ().down ());
                }
            }
            var iter = root.iter ();
            var item = iter.next ();
            while (item != GMenu.TreeItemType.INVALID) {
                if (item == GMenu.TreeItemType.DIRECTORY) {
                    var category = (GMenu.TreeDirectory) iter.get_directory ();
                    var name = category.get_name ().down ();
                    if (allowed == null || allowed.contains (name)) {
                        main_directory_entries.add (category);
                    }
                }
                item = iter.next ();
            }
            return main_directory_entries;
        }

        private static Gee.HashSet<GMenu.TreeEntry> get_applications_for_category (
            GMenu.TreeDirectory category) {

            var entries = new Gee.HashSet<GMenu.TreeEntry> (
                (x) => ((GMenu.TreeEntry) x).get_desktop_file_path ().hash (),
                (x, y) => ((GMenu.TreeEntry) x).get_desktop_file_path ().hash () ==
                    ((GMenu.TreeEntry) y).get_desktop_file_path ().hash ()
            );

            var iter = category.iter ();
            var item = iter.next ();
            while ( item != GMenu.TreeItemType.INVALID) {
                switch (item) {
                    case GMenu.TreeItemType.DIRECTORY:
                        entries.add_all (get_applications_for_category ((GMenu.TreeDirectory) iter.get_directory ()));
                        break;
                    case GMenu.TreeItemType.ENTRY:
                        entries.add ((GMenu.TreeEntry) iter.get_entry ());
                        break;
                    case GMenu.TreeItemType.HEADER:
                    case GMenu.TreeItemType.SEPARATOR:
                    case GMenu.TreeItemType.ALIAS:
                        // These types don't contain applications, so we can skip them
                        break;
                    case GMenu.TreeItemType.INVALID:
                        // This case should never be reached due to the while condition
                        break;
                }
                item = iter.next ();
            }

            return entries;
        }

        public static void enumerate_apps (Gee.HashMap<string, Gdk.Pixbuf> icons,
                int icon_size,
                string user_home,
                out Gee.ArrayList<Gee.HashMap<string, string>> list) {

            var the_apps = new Gee.HashSet<GMenu.TreeEntry> (
                (x) => ((GMenu.TreeEntry) x).get_desktop_file_path ().hash (),
                (x, y) => ((GMenu.TreeEntry) x).get_desktop_file_path ().hash () ==
                    ((GMenu.TreeEntry) y).get_desktop_file_path ().hash ()
            );
            var all_categories = get_categories ();

            foreach (GMenu.TreeDirectory directory in all_categories) {
                var this_category_apps = get_applications_for_category (directory);
                foreach (GMenu.TreeEntry this_app in this_category_apps) {
                    the_apps.add (this_app);
                }
            }
            debug ("Amount of apps: %d", the_apps.size);

            var icon_theme = Gtk.IconTheme.get_default ();
            string icon_theme_name;
            Gtk.Settings.get_default ().get ("gtk-icon-theme-name", out icon_theme_name);
            icon_theme_name = icon_theme_name.replace (" ", "-");

            list = new Gee.ArrayList<Gee.HashMap<string, string>> ();

            // Create cache directory if it doesn't exist
            string cache_dir = user_home + Resources.CACHE_DIR;
            try {
                var cache_file = GLib.File.new_for_path (cache_dir);
                if (!cache_file.query_exists ()) {
                    cache_file.make_directory_with_parents ();
                }
            } catch (GLib.Error e) {
                warning ("Cache directory could not be created: %s", e.message);
            }

            var blocklist_file = GLib.File.new_for_path (user_home + Resources.BLOCKLIST_FILE);
            var apps_hidden = new Gee.ArrayList<string> ();

            if (blocklist_file.query_exists ()) {
                try {
                    var dis = new DataInputStream (blocklist_file.read ());
                    string line;

                    while ((line = dis.read_line (null)) != null) {
                        apps_hidden.add (line);
                    }
                } catch (GLib.Error e) {
                    warning ("Blacklist file could not be found, no hidden apps");
                }
            } else {
                apps_hidden.add ("");
            }

            // We add a custom app to exit Lightpad
            var exit_app = new Gee.HashMap<string, string> ();
            exit_app["name"] = Resources.LIGHTPAD_EXIT_NAME;
            exit_app["id"] = Resources.LIGHTPAD_EXIT_ID;
            exit_app["description"] = Resources.LIGHTPAD_EXIT_DESC;
            exit_app["command"] = Resources.LIGHTPAD_EXIT_ID;

            Gdk.Pixbuf? exit_pixbuf = null;
            try {
                exit_pixbuf = icon_theme.load_icon ("lightpad-exit", icon_size, 0)
                    .scale_simple (icon_size, icon_size, Gdk.InterpType.BILINEAR);
            } catch (GLib.Error e) {
                warning ("No LightPad exit icon found %s", e.message);
            }

            icons[exit_app["command"]] = exit_pixbuf;
            list.add (exit_app);

            foreach (GMenu.TreeEntry entry in the_apps) {
                var app = entry.get_app_info ();
                if (
                    app.get_nodisplay () == false &&
                    app.get_is_hidden () == false &&
                    app.get_icon () != null &&
                    !(
                        (app.get_commandline ().split (" ")[0] in apps_hidden) ||
                        (app.get_commandline () in apps_hidden)
                    ) &&
                    !app.get_commandline ().contains (Config.PROJECT_NAME)
                ) {
                    var app_to_add = new Gee.HashMap<string, string> ();
                    app_to_add["name"] = app.get_display_name ();
                    app_to_add["id"] = app_to_add["name"].down ();
                    app_to_add["description"] = app.get_description ();

                    // Needed to check further later if terminal is open in terminal (like VIM, HTop, etc.)
                    if (app.get_string ("Terminal") == "true") {
                        app_to_add["terminal"] = "true";
                    }

                    app_to_add["command"] = app.get_commandline ();
                    app_to_add["desktop_file"] = entry.get_desktop_file_path ();

                    if (!icons.has_key (app_to_add["command"])) {
                        var app_icon = app.get_icon ().to_string ();
                        var icon_prefix = Resources.PIXMAPS_DIR;
                        string cache_path = cache_dir + "/" + icon_theme_name
                                          + "_" + app_icon.replace ("/", "_") + ".png";
                        try {
                            // Trying to load from cache
                            if (GLib.File.new_for_path (cache_path).query_exists ()) {
                                icons[app_to_add["command"]] = new Gdk.Pixbuf.from_file (cache_path);
                            } else if (icon_theme.has_icon (app_icon)) {
                                /*
                                 * Attention: the icons inside the icon_theme can tell lies about
                                 * their icon_size, so we need always to scale them
                                 */
                                var pixbuf = icon_theme.load_icon (app_icon, icon_size, 0)
                                                .scale_simple (icon_size, icon_size, Gdk.InterpType.BILINEAR);
                                icons[app_to_add["command"]] = pixbuf;
                                pixbuf.savev (cache_path, "png", null, null);
                            } else if (GLib.File.new_for_path (app_icon).query_exists ()) {
                                var pixbuf = new Gdk.Pixbuf.from_file_at_scale (
                                    app_icon.to_string (), -1, icon_size, true
                                );
                                icons[app_to_add["command"]] = pixbuf;
                                pixbuf.savev (cache_path, "png", null, null);
                            } else if (GLib.File.new_for_path (icon_prefix + app_icon + ".png").query_exists ()) {
                                var pixbuf = new Gdk.Pixbuf.from_file_at_scale (
                                    icon_prefix + app_icon + ".png", -1, icon_size, true
                                );
                                icons[app_to_add["command"]] = pixbuf;
                                pixbuf.savev (cache_path, "png", null, null);
                            } else if (GLib.File.new_for_path (icon_prefix + app_icon + ".svg").query_exists ()) {
                                var pixbuf = new Gdk.Pixbuf.from_file_at_scale (
                                    icon_prefix + app_icon + ".svg", -1, icon_size, true
                                );
                                icons[app_to_add["command"]] = pixbuf;
                                pixbuf.savev (cache_path, "png", null, null);
                            } else if (GLib.File.new_for_path (icon_prefix + app_icon + ".xpm").query_exists ()) {
                                var pixbuf = new Gdk.Pixbuf.from_file_at_scale (
                                    icon_prefix + app_icon + ".xpm", -1, icon_size, true
                                );
                                icons[app_to_add["command"]] = pixbuf;
                                pixbuf.savev (cache_path, "png", null, null);
                            } else {
                                var pixbuf = icon_theme.load_icon (
                                    "application-default-icon", icon_size, 0
                                );
                                icons[app_to_add["command"]] = pixbuf;
                                pixbuf.savev (cache_path, "png", null, null);
                            }
                        } catch (GLib.Error e) {
                            warning ("No icon found for %s.", app_to_add["name"]);
                            continue;
                        }
                    }
                    list.add (app_to_add);
                }
            }

        }

    }

}
