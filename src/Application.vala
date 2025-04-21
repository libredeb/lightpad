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

public class LightPadWindow : Widgets.CompositedWindow {

    public static string user_home = GLib.Environment.get_variable ("HOME");
    public Gee.ArrayList<Gee.HashMap<string, string>> apps = new Gee.ArrayList<Gee.HashMap<string, string>> ();
    public Gee.HashMap<string, Gdk.Pixbuf> icons = new Gee.HashMap<string, Gdk.Pixbuf>();
    public Gee.ArrayList<Gee.HashMap<string, string>> filtered = new Gee.ArrayList<Gee.HashMap<string, string>> ();
    public LightPad.Frontend.Indicators pages;

    public double font_size;
    public int icon_size;
    public int item_box_width;
    public int item_box_height;

    public int total_pages;
    public int scroll_times = 0;
    public int SCROLL_SENSITIVITY = 12;

    public Gdk.Rectangle monitor_dimensions;
    public Gtk.Box top_spacer;
    public GLib.List<LightPad.Frontend.AppItem> children = new GLib.List<LightPad.Frontend.AppItem> ();
    public Gtk.Grid grid;

    private int grid_x;
    private int grid_y;

    public bool dynamic_background = false;

    public LightPadWindow () {
        // There isn't always a primary monitor.
        Gdk.Monitor monitor = get_display ().get_primary_monitor () ?? get_display ().get_monitor (0);
        
        monitor_dimensions.width = 720;
        monitor_dimensions.height = 720;

        this.icon_size = 128;
        this.font_size = 0;
        this.item_box_width = 128;
        this.item_box_height = 128;
        this.grid_y = 3;
        this.grid_x = 3;

        // Window properties
        this.set_title ("LightPad");
        /* Skip that a workspace switcher and taskbars displays a
           thumbnail representation of the window in the screen */
        this.set_skip_pager_hint (true);
        this.set_skip_taskbar_hint (true);
        this.set_type_hint (Gdk.WindowTypeHint.NORMAL);
        //this.fullscreen (); <-- old method used
        var display = Gdk.Display.get_default();
        
        int primary_monitor_number = 0;
        for (int i = 0; i < display.get_n_monitors (); i++) {
            if (get_display ().get_monitor (i).is_primary ()) {
                primary_monitor_number = i;
            }
        }
        this.fullscreen_on_monitor (monitor.get_display ().get_default_screen (), primary_monitor_number);
        this.set_default_size (monitor_dimensions.width,  monitor_dimensions.height);


        // Get all apps
        LightPad.Backend.DesktopEntries.enumerate_apps (this.icons, this.icon_size, user_home, out this.apps);

        // Add container wrapper
        var wrapper = new Gtk.EventBox (); // Used for the scrolling and button press events
        wrapper.set_visible_window (false);
        this.add (wrapper);

        // Add container
        var container = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        wrapper.add (container);

        // Add top bar
        var bottom = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        bottom.state_changed.connect (() => {
            this.present_all_apps();
        });

        // Upstairs (padding is the space between search bar and the grid)
        container.pack_start (bottom, true, true, 32);

        this.grid = new Gtk.Grid();
        this.grid.set_row_spacing (42);
        this.grid.set_column_spacing (42);
        this.grid.set_halign (Gtk.Align.CENTER);

        // Initialize the grid
        for (int c = 0; c < this.grid_y; c++) {
            this.grid.insert_column (c);
        }

        for (int r = 0; r < this.grid_x; r++) {
            this.grid.insert_row (r);
        }

        container.pack_start (this.grid, true, true, 0);

        this.populate_grid ();

        // Add pages
        this.pages = new LightPad.Frontend.Indicators ();
        this.pages.child_activated.connect ( () => { this.update_grid (this.filtered); } );

        var pages_wrapper = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        pages_wrapper.set_size_request (-1, 30);
        bottom.pack_start (pages_wrapper, true, true, 15);

        // Find number of pages and populate
        // First order the apps alphabetically
        this.apps.sort ((a, b) => GLib.strcmp (a["name"], b["name"]));
        this.update_pages (this.apps);
        if (this.total_pages > 1) {
            pages_wrapper.pack_start (this.pages, true, false, 0);
            for (int p = 1; p <= this.total_pages; p++) {
                // Add the number of pages as text
                //this.pages.append (p.to_string ());
                this.pages.append ("⬤");
            }
        }
        this.pages.set_active (0);

        // Signals and callbacks
        this.add_events (Gdk.EventMask.SCROLL_MASK);

        this.draw.connect (this.draw_background);
        // close Lightpad when the window loses focus
        this.focus_out_event.connect ( () => {
            this.hide();
            GLib.Timeout.add_seconds (1, () => {
                this.destroy ();
                return GLib.Source.REMOVE;
            });
            return true;
        } );
        // close Lightpad when we clic on empty area
        this.button_release_event.connect ( () => { this.destroy(); return false; });
        
    }

    private void present_all_apps() {
        this.filtered.clear ();

        foreach (Gee.HashMap<string, string> app in this.apps) {
            this.filtered.add (app);
        }

        this.pages.set_active (0);
        this.queue_draw ();
    }

    private void populate_grid () {
        for (int r = 0; r < this.grid_x; r++) {
            for (int c = 0; c < this.grid_y; c++) {
                var item = new LightPad.Frontend.AppItem (
                    this.icon_size, this.font_size, 
                    this.item_box_width, this.item_box_height
                );
                this.children.append (item);

                item.button_press_event.connect ( () => { item.grab_focus (); return true; } );
                item.enter_notify_event.connect ( () => { item.grab_focus (); return true; } );
                item.button_release_event.connect ( () => {
                    try {
                        int child_index = this.children.index (item);
                        int page_active = this.pages.active;
                        /* Prevent indicators pages to get a negative one (-1)
                           and fix with this the bug 003 where a negative result
                           is obtained and that index does not exist */
                        if (page_active < 0) {
                            page_active = 0;
                        }
                        int app_index = (int) (child_index + (page_active * this.grid_y * this.grid_x));

                        /* GTK+ implements open apps in terminal in this way:
                         * https://github.com/GNOME/glib/blob/cd1eba043c90da3aee8f5cd51b205b2e2c16f08e/gio/gdesktopappinfo.c#L2467-L2494
                         * So, if the desktop environment is not GNOME we need xterm as dependency
                         * and the way to open apps in terminal is with the following code:
                         */
                        if (this.filtered.get (app_index)["terminal"] == "true") {
                            GLib.AppInfo.create_from_commandline (this.filtered.get (app_index)["command"], null, GLib.AppInfoCreateFlags.NEEDS_TERMINAL).launch (null, null);
                        } else {
                            var context = new AppLaunchContext ();
                            new GLib.DesktopAppInfo.from_filename (this.filtered.get(app_index)["desktop_file"]).launch (null, context);
                        }
                        this.hide();
                        GLib.Timeout.add_seconds (1, () => {
                            // allow some time before quitting to allow dbusactivatable apps to be launched
                            this.destroy ();
                            return GLib.Source.REMOVE;
                        });
                    } catch (GLib.Error e) {
                        warning ("Error! Load application: " + e.message);
                    }

                    return true;
                });

                this.grid.attach (item, c, r, 1, 1);
            }
        }
    }

    private void update_grid (Gee.ArrayList<Gee.HashMap<string, string>> apps) {
        int item_iter = (int)(this.pages.active * this.grid_y * this.grid_x);
        /* Fix for bug 001 with message:
        arraylist.c:1181:gee_array_list_real_get: assertion failed: (index >= 0) */
        if (item_iter < 0) {
            item_iter = 0;
        }

        for (int r = 0; r < this.grid_x; r++) {
            for (int c = 0; c < this.grid_y; c++) {
                int table_pos = c + (r * (int)this.grid_y); // position in table right now

                var item = this.children.nth_data (table_pos);
                if (item_iter < apps.size) {
                    var current_item = apps.get(item_iter);

                    // Update app
                    if (current_item["description"] == null || current_item["description"] == "") {
                        item.change_app (icons[current_item["command"]], current_item["name"], current_item["name"]);
                    } else {
                        item.change_app (icons[current_item["command"]], current_item["name"], current_item["name"] + ":\n" + current_item["description"]);
                    }
                    item.visible = true;
                } else { // fill with a blank one
                    item.visible = false;
                }

                item_iter++;

            }
        }

        // Update number of pages
        this.update_pages (apps);

        // Grab first one's focus
        this.children.nth_data (0).grab_focus ();
    }

    private void update_pages (Gee.ArrayList<Gee.HashMap<string, string>> apps) {
        // Find current number of pages and update count
        var num_pages = (int) (apps.size / (this.grid_y * this.grid_x));
        (double) apps.size % (double) (this.grid_y * this.grid_x) > 0 ? this.total_pages = num_pages + 1 : this.total_pages = num_pages;

        // Update pages
        if (this.total_pages > 1) {
            this.pages.visible = true;
            for (int p = 1; p <= this.pages.children.length (); p++) {
                p > this.total_pages ? this.pages.children.nth_data (p - 1).visible = false : this.pages.children.nth_data (p - 1).visible = true;
            }
        } else {
            this.pages.visible = false;
        }
    }

    private void page_left () {
        if (this.pages.active >= 1) {
            this.pages.set_active (this.pages.active - 1);
        }
    }

    private void page_right () {
        if ((this.pages.active + 1) < this.total_pages) {
            this.pages.set_active (this.pages.active + 1);
        }
    }

    private bool draw_background (Gtk.Widget widget, Cairo.Context ctx) {
        var context = Gdk.cairo_create (widget.get_window ());

        // Semi-dark background
        Gtk.Allocation size;
        widget.get_allocation (out size);
        
        var linear_gradient = new Cairo.Pattern.linear (size.x, size.y, size.x, size.y + size.height);
        linear_gradient.add_color_stop_rgba (0.0, 0.0, 0.0, 0.0, 1);

        context.set_source (linear_gradient);
        context.paint ();

        return false;
    }

    // Keyboard shortcuts
    public override bool key_press_event (Gdk.EventKey event) {
        switch (Gdk.keyval_name (event.keyval)) {
            case "Escape":
                this.destroy ();
                return true;
            case "ISO_Left_Tab":
                this.page_left ();
                return true;
            case "Shift_L":
            case "Shift_R":
                return true;
            case "Tab":
                this.page_right ();
                return true;
            case "Return":
                if (this.filtered.size >= 1) {
                    this.get_focus ().button_release_event ((Gdk.EventButton) new Gdk.Event (Gdk.EventType.BUTTON_PRESS));
                }
                return true;
            case "Left":
                var current_item = this.grid.get_children ().index (this.get_focus ());
                if (current_item % this.grid_y == this.grid_y - 1) {
                    this.page_left ();
                    return true;
                }
                break;
            case "Right":
                var current_item = this.grid.get_children ().index (this.get_focus ());
                if (current_item % this.grid_y == 0) {
                    this.page_right ();
                    return true;
                }
                break;
            case "Down":
            case "Up":
                break; // used to stop refreshing the grid on arrow key press
        }

        base.key_press_event (event);
        return false;
    }

    // Scrolling left/right for pages
    public override bool scroll_event (Gdk.EventScroll event) {
        scroll_times += 1;
        var direction = event.direction.to_string ();
        if ((direction == "GDK_SCROLL_UP" || direction == "GDK_SCROLL_LEFT")
                                    && (scroll_times >= SCROLL_SENSITIVITY)) {
            this.page_left ();
        } else if ((direction == "GDK_SCROLL_DOWN" || direction == "GDK_SCROLL_RIGHT")
                                    && (scroll_times >= SCROLL_SENSITIVITY)) {
            this.page_right ();
        }
        // If the direction is GDK_SCROLL_SMOOTH skip it

        return false;
    }

    // Override destroy for fade out and stuff
    public new void destroy () {
        base.destroy();
        Gtk.main_quit();
    }

}

static int main (string[] args) {

    Gtk.init (ref args);
    Gtk.Application app = new Gtk.Application ("org.libredeb.lightpad", GLib.ApplicationFlags.FLAGS_NONE);

    // CSS Style Provider
    // Path where takes the CSS file
    string css_file = Config.PACKAGE_SHAREDIR +
        "/" + Config.PROJECT_NAME +
        "/" + "application.css";
    var css_provider = new Gtk.CssProvider ();

    try {
        css_provider.load_from_path (css_file);
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default(), css_provider,
                                                        Gtk.STYLE_PROVIDER_PRIORITY_USER);
    } catch (GLib.Error e) {
        warning ("Could not load CSS file: %s",css_file);
    }

    app.activate.connect( () => {
        if (app.get_windows ().length () == 0) {
            var main_window = new LightPadWindow ();
            main_window.set_application (app);
            main_window.show_all ();
            Gtk.main ();
        }
    });
    app.run (args);
    return 1;

}
