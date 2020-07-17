/*
* Copyright (c) 2011-2020 LightPad
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Juan Pablo Lozano <libredeb@gmail.com>
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
            var iter = root.iter ();
            var item = iter.next ();
            while (item != GMenu.TreeItemType.INVALID) {
                if (item == GMenu.TreeItemType.DIRECTORY) {
                    main_directory_entries.add ((GMenu.TreeDirectory) iter.get_directory ());
                }
                item = iter.next ();
            }
            message ("Number of categories: %d", main_directory_entries.size);
            return main_directory_entries;
        }
        
        private static Gee.HashSet<GMenu.TreeEntry> get_applications_for_category (
            GMenu.TreeDirectory category) {
            
            var entries = new Gee.HashSet<GMenu.TreeEntry>  (
                (x) => ((GMenu.TreeEntry)x).get_desktop_file_path ().hash (),
                (x,y) => ((GMenu.TreeEntry)x).get_desktop_file_path ().hash () == ((GMenu.TreeEntry)y).get_desktop_file_path ().hash ());

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
                }
                item = iter.next ();
            }
            message ("Category [%s] has [%d] apps", category.get_name (), entries.size);
            return entries;
        }
        
        public static void enumerate_apps (Gee.HashMap<string, Gdk.Pixbuf> icons, 
                int icon_size,
                string user_home,
                out Gee.ArrayList<Gee.HashMap<string, string>> list) {
            
            var the_apps = new Gee.HashSet<GMenu.TreeEntry> (
                (x) => ((GMenu.TreeEntry)x).get_desktop_file_path ().hash (),
                (x,y) => ((GMenu.TreeEntry)x).get_desktop_file_path ().hash () == ((GMenu.TreeEntry)y).get_desktop_file_path ().hash ());
            var all_categories = get_categories ();

            foreach (GMenu.TreeDirectory directory in all_categories) {
                var this_category_apps = get_applications_for_category (directory);
                foreach(GMenu.TreeEntry this_app in this_category_apps){
                    the_apps.add(this_app);
                }
            }
            
            message ("Amount of apps: %d", the_apps.size);
            var icon_theme = Gtk.IconTheme.get_default();
            list = new Gee.ArrayList<Gee.HashMap<string, string>> ();
            
            var blacklist_file = GLib.File.new_for_path (user_home + Resources.BLACKLIST_FILE);
            var apps_hidden = new Gee.ArrayList<string> ();
            
            if (blacklist_file.query_exists ()) {
                try {
                    var dis = new DataInputStream (blacklist_file.read ());
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
                if (app.get_nodisplay () == false && 
                    app.get_is_hidden() == false && 
                    app.get_icon() != null &&
                    !(app.get_commandline ().split (" ")[0] in apps_hidden))
                {
                    var app_to_add = new Gee.HashMap<string, string> ();
                    app_to_add["name"] = app.get_display_name ();
                    app_to_add["description"] = app.get_description ();
                    
                    // Needed to check further later if terminal is open in terminal (like VIM, HTop, etc.)
                    if (app.get_string ("Terminal") == "true") {
                        app_to_add["terminal"] = "true";
                    }
                    app_to_add["command"] = app.get_commandline ();
                    app_to_add["desktop_file"] = entry.get_desktop_file_path ();

                    if (!icons.has_key (app_to_add["command"])) {
                        var app_icon = app.get_icon ().to_string ();
                        // This is not related to snap package... is related to the system itself
                        var icon_prefix = "/usr/share/pixmaps/";
                        try {
                            if (icon_theme.has_icon (app_icon)) {
                                /* Attention: the icons inside the icon_theme can tell lies about
                                   their icon_size, so we need always to scale them */
                                icons[app_to_add["command"]] = icon_theme.load_icon (app_icon, icon_size, 0)
                                                .scale_simple(icon_size, icon_size, Gdk.InterpType.BILINEAR);
                            } else if (GLib.File.new_for_path(app_icon).query_exists()) {
                                icons[app_to_add["command"]] = new Gdk.Pixbuf.from_file_at_scale (app_icon.to_string (), -1, icon_size, true);
                            } else if (GLib.File.new_for_path(icon_prefix + app_icon + ".png").query_exists()) {
                                icons[app_to_add["command"]] = new Gdk.Pixbuf.from_file_at_scale (icon_prefix + app_icon + ".png", -1, icon_size, true);
                            } else if (GLib.File.new_for_path(icon_prefix + app_icon + ".svg").query_exists()) {
                                icons[app_to_add["command"]] = new Gdk.Pixbuf.from_file_at_scale (icon_prefix + app_icon + ".svg", -1, icon_size, true);
                            } else if (GLib.File.new_for_path(icon_prefix + app_icon + ".xpm").query_exists()) {
                                icons[app_to_add["command"]] = new Gdk.Pixbuf.from_file_at_scale (icon_prefix + app_icon + ".xpm", -1, icon_size, true);
                            } else {
                                icons[app_to_add["command"]] = icon_theme.load_icon ("application-default-icon", icon_size, 0);
                            }
                        } catch  (GLib.Error e) {
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
