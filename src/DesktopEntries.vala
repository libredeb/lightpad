/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020 Juan Pablo Lozano <libredeb@gmail.com>
 */

namespace LightPad.Backend {

    public class DesktopEntries : GLib.Object {

        public static string? try_resolve (string? value, Gee.HashMap<string, string> map) {
            if (value == null) {
                return null;
            }

            foreach (var part in value.down ().split (":")) {
                var trimmed = part.strip ();
                if (map.has_key (trimmed)) {
                    return map.get (trimmed);
                }
            }

            return null;
        }

        private static string resolve_menu_filename () {
            var desktop_menus_map = new Gee.HashMap<string, string> ();

            desktop_menus_map.set ("gnome", "gnome-applications.menu");
            desktop_menus_map.set ("unity", "gnome-applications.menu");
            desktop_menus_map.set ("kde", "kf5-applications.menu");
            desktop_menus_map.set ("plasma", "plasma-applications.menu");
            desktop_menus_map.set ("xfce", "xfce-applications.menu");
            desktop_menus_map.set ("x-cinnamon", "cinnamon-applications.menu");
            desktop_menus_map.set ("cinnamon", "cinnamon-applications.menu");
            desktop_menus_map.set ("mate", "mate-applications.menu");
            desktop_menus_map.set ("lxde", "lxde-applications.menu");
            desktop_menus_map.set ("lxqt", "lxqt-applications.menu");
            desktop_menus_map.set ("sway", "lxqt-applications.menu");
            desktop_menus_map.set ("budgie", "gnome-applications.menu");
            desktop_menus_map.set ("budgie-desktop", "gnome-applications.menu");
            desktop_menus_map.set ("pantheon", "gnome-applications.menu");

            string? current_desktop = GLib.Environment.get_variable ("XDG_CURRENT_DESKTOP");
            string? resolved = try_resolve (current_desktop, desktop_menus_map);
            if (resolved != null) {
                return resolved;
            }

            string? session_desktop = GLib.Environment.get_variable ("XDG_SESSION_DESKTOP");
            resolved = try_resolve (session_desktop, desktop_menus_map);
            if (resolved != null) {
                return resolved;
            }

            return Resources.XDG_FALLBACK_MENU;
        }

        private static Gee.ArrayList<GMenu.TreeDirectory> get_categories () {
            var tree = new GMenu.Tree (resolve_menu_filename (), GMenu.TreeFlags.INCLUDE_EXCLUDED);
            try {
                // Initialize the tree
                tree.load_sync ();
            } catch (GLib.Error e) {
                error ("Initialization of the GMenu.Tree failed: %s", e.message);
            }
            var root = tree.get_root_directory ();
            var main_directory_entries = new Gee.ArrayList<GMenu.TreeDirectory> ();
            var iter = root.iter ();
            var item = iter.next ();
            while (item != GMenu.TreeItemType.INVALID) {
                if (item == GMenu.TreeItemType.DIRECTORY) {
                    main_directory_entries.add ((GMenu.TreeDirectory) iter.get_directory ());
                }
                item = iter.next ();
            }
            debug ("Number of categories: %d", main_directory_entries.size);
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
                    case GMenu.TreeItemType.INVALID:
                        // We ignore these types as they are not relevant to our application.
                        break;
                }
                item = iter.next ();
            }
            debug ("Category [%s] has [%d] apps", category.get_name (), entries.size);
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
            string cache_path = user_home + Resources.CACHE_DIR;
            try {
                var cache_dir = GLib.File.new_for_path (cache_path);
                if (!cache_dir.query_exists ()) {
                    cache_dir.make_directory_with_parents ();
                }
            } catch (GLib.Error e) {
                warning ("Icons cache directory could not be created: %s", e.message);
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
                        string icon_cached_path = cache_path + "/" + icon_theme_name + "_"
                                                + app_icon.replace ("/", "_") + "_" + icon_size.to_string () + ".png";

                        try {
                            // Trying to load from cache
                            if (GLib.File.new_for_path (icon_cached_path).query_exists ()) {
                                icons[app_to_add["command"]] = new Gdk.Pixbuf.from_file (icon_cached_path);
                            } else if (icon_theme.has_icon (app_icon)) {
                                /*
                                 * Attention: the icons inside the icon_theme can tell lies about
                                 * their icon_size, so we need always to scale them
                                 */
                                var pixbuf = icon_theme.load_icon (app_icon, icon_size, 0)
                                                .scale_simple (icon_size, icon_size, Gdk.InterpType.BILINEAR);
                                icons[app_to_add["command"]] = pixbuf;
                                pixbuf.savev (icon_cached_path, "png", null, null);
                            } else if (GLib.File.new_for_path (app_icon).query_exists ()) {
                                var pixbuf = new Gdk.Pixbuf.from_file_at_scale (
                                    app_icon.to_string (), -1, icon_size, true
                                );
                                icons[app_to_add["command"]] = pixbuf;
                                pixbuf.savev (icon_cached_path, "png", null, null);
                            } else if (GLib.File.new_for_path (icon_prefix + app_icon + ".png").query_exists ()) {
                                var pixbuf = new Gdk.Pixbuf.from_file_at_scale (
                                    icon_prefix + app_icon + ".png", -1, icon_size, true
                                );
                                icons[app_to_add["command"]] = pixbuf;
                                pixbuf.savev (icon_cached_path, "png", null, null);
                            } else if (GLib.File.new_for_path (icon_prefix + app_icon + ".svg").query_exists ()) {
                                var pixbuf = new Gdk.Pixbuf.from_file_at_scale (
                                    icon_prefix + app_icon + ".svg", -1, icon_size, true
                                );
                                icons[app_to_add["command"]] = pixbuf;
                                pixbuf.savev (icon_cached_path, "png", null, null);
                            } else if (GLib.File.new_for_path (icon_prefix + app_icon + ".xpm").query_exists ()) {
                                var pixbuf = new Gdk.Pixbuf.from_file_at_scale (
                                    icon_prefix + app_icon + ".xpm", -1, icon_size, true
                                );
                                icons[app_to_add["command"]] = pixbuf;
                                pixbuf.savev (icon_cached_path, "png", null, null);
                            } else {
                                var pixbuf = icon_theme.load_icon (
                                    "application-default-icon", icon_size, 0
                                );
                                icons[app_to_add["command"]] = pixbuf;
                                pixbuf.savev (icon_cached_path, "png", null, null);
                            }
                        } catch (GLib.Error e) {
                            warning ("No icon found for %s.\n", app_to_add["name"]);
                            continue;
                        }
                    }
                    list.add (app_to_add);
                }
            }
        }
    }
}
