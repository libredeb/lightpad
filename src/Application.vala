/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020 Juan Pablo Lozano <libredeb@gmail.com>
 */

public class LightPadWindow : Widgets.CompositedWindow {

    public static string user_home = GLib.Environment.get_variable ("HOME");
    public Gee.ArrayList<Gee.HashMap<string, string>> apps = new Gee.ArrayList<Gee.HashMap<string, string>> ();
    public Gee.HashMap<string, Gdk.Pixbuf> icons = new Gee.HashMap<string, Gdk.Pixbuf> ();
    public Gee.ArrayList<Gee.HashMap<string, string>> filtered = new Gee.ArrayList<Gee.HashMap<string, string>> ();
    public LightPad.Frontend.Indicators pages;

    public double font_size;
    public int icon_size;
    public int item_box_width;
    public int item_box_height;

    public int total_pages;
    public int scroll_times = 0;
    public const int SCROLL_SENSITIVITY = 12;

    public Gdk.Rectangle monitor_dimensions;
    public Gtk.Box top_spacer;
    public GLib.List<LightPad.Frontend.AppItem> children = new GLib.List<LightPad.Frontend.AppItem> ();
    public Gtk.Grid grid;

    private int grid_x;
    private int grid_y;

    private GLib.Thread<int> thread;

    // Variables to monitor the launched process
    private uint child_watch_id = 0;
    private bool is_monitoring_process = false;

    public LightPadWindow () {
        const int ICON_SIZE = 182;
        const int GRID_SPACING = 34;
        const int GRID_X = 3;
        const int GRID_Y = 3;

        monitor_dimensions.width = 720;
        monitor_dimensions.height = 720;

        this.icon_size = ICON_SIZE;
        this.font_size = 0;
        this.item_box_width = ICON_SIZE + 8;
        this.item_box_height = ICON_SIZE + 8;
        this.grid_y = GRID_Y;
        this.grid_x = GRID_X;

        // Window properties
        this.set_title ("LightPad");
        /* Skip that a workspace switcher and taskbars displays a
           thumbnail representation of the window in the screen */
        this.set_skip_pager_hint (true);
        this.set_skip_taskbar_hint (true);
        this.set_type_hint (Gdk.WindowTypeHint.NORMAL);

        // There isn't always a primary monitor.
        Gdk.Monitor monitor = get_display ().get_primary_monitor () ?? get_display ().get_monitor (0);
        var display = Gdk.Display.get_default ();

        int primary_monitor_number = 0;
        for (int i = 0; i < display.get_n_monitors (); i++) {
            if (get_display ().get_monitor (i).is_primary ()) {
                primary_monitor_number = i;
            }
        }

        this.fullscreen_on_monitor (monitor.get_display ().get_default_screen (), primary_monitor_number);
        this.set_default_size (monitor_dimensions.width, monitor_dimensions.height);

        // Get all apps
        LightPad.Backend.DesktopEntries.enumerate_apps (this.icons, this.icon_size, user_home, out this.apps);

        // Add container wrapper
        var wrapper = new Gtk.EventBox (); // Used for the scrolling and button press events
        wrapper.set_visible_window (false);
        this.add (wrapper);

        // Add container
        var container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        wrapper.add (container);

        // Add pagess_wrapper container
        var bottom = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        bottom.show.connect (() => {
            this.present_all_apps ();
        });

        // Upstairs (padding is the space between search bar and the grid)
        container.pack_start (bottom, true, true, 14);

        this.grid = new Gtk.Grid ();
        this.grid.set_row_spacing (GRID_SPACING);
        this.grid.set_column_spacing (GRID_SPACING);
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
        //pages_wrapper.set_size_request (-1, 30);
        bottom.pack_start (pages_wrapper, true, true, 0);

        // Find number of pages and populate
        // First order the apps alphabetically
        this.apps.sort ((a, b) => GLib.strcmp (a["id"], b["id"]));
        this.update_pages (this.apps);
        if (this.total_pages > 1) {
            pages_wrapper.pack_start (this.pages, true, false, 0);
            for (int p = 1; p <= this.total_pages; p++) {
                // Add the number of pages as text
                this.pages.append ("⬤");
            }
        }
        this.pages.set_active (0);

        // Signals and callbacks
        this.add_events (Gdk.EventMask.SCROLL_MASK);

        this.draw.connect (this.draw_background);

        thread = new GLib.Thread<int> ("JoystickThread", () => {
            if (SDL.init (SDL.InitFlag.JOYSTICK) != 0) {
                warning ("SDL init Error: %s", SDL.get_error ());
                return 0;
            }

            if (SDL.Input.Joystick.count () < 1) {
                warning ("No joysticks detected");
                SDL.quit ();
                return 0;
            }

            var joystick = new SDL.Input.Joystick (0); // Index 0
            if (joystick == null) {
                warning ("Unable to open joystick: %s", SDL.get_error ());
                SDL.quit ();
                return 0;
            }

            SDL.Event event;
            while (true) {
                while (SDL.Event.poll (out event) != 0) {
                    switch (event.type) {
                        case SDL.EventType.JOYBUTTONDOWN:
                            if ((event.jbutton.button == 10) || (event.jbutton.button == 18)) {
                                if (this.filtered.size >= 1) {
                                    this.get_focus ().button_release_event (
                                        (Gdk.EventButton) new Gdk.Event (Gdk.EventType.BUTTON_PRESS)
                                    );
                                }
                                SDL.quit ();
                            }

                            if (event.jbutton.button == 6) {
                                this.do_up ();
                            }
                            if (event.jbutton.button == 7) {
                                this.do_down ();
                            }

                            if (event.jbutton.button == 8) {
                                this.do_left ();
                            }
                            if (event.jbutton.button == 9) {
                                this.do_right ();
                            }
                            break;
                        default:
                            break;
                    }
                }
                SDL.Timer.delay (10); // Avoid 100% CPU usage
            }
        });
    }

    private void present_all_apps () {
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

                        /* GLib implements open apps in terminal in this way:
                         * https://github.com/GNOME/glib/blob/2.76.0/gio/gdesktopappinfo.c#L2685
                         * There's a major change in last versions of glib (from version 2.76.0 upwards)
                         * So, xterm dependency it's no longer needed.
                         * The way to open apps in terminal is with the following code:
                         */
                        if (this.filtered.get (app_index)["terminal"] == "true") {
                            GLib.AppInfo.create_from_commandline (
                                this.filtered.get (app_index)["command"],
                                null,
                                GLib.AppInfoCreateFlags.NEEDS_TERMINAL
                            ).launch (null, null);
                        } else {
                            var context = new AppLaunchContext ();
                            new GLib.DesktopAppInfo.from_filename (
                                this.filtered.get (app_index)["desktop_file"]
                            ).launch (null, context);
                        }

                        // Hide the window instead of closing it
                        this.hide ();

                        /*
                         * Attempt to obtain the PID of the launched process
                         * Use a more robust approach to detect when the application closes
                         */
                        string command = this.filtered.get (app_index)["command"];

                        // Start application monitoring
                        this.start_application_monitoring (command);

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
                    var current_item = apps.get (item_iter);

                    // Get the icon, use a default one if it doesn't exist
                    Gdk.Pixbuf? icon = null;
                    if (icons.has_key (current_item["command"])) {
                        icon = icons[current_item["command"]];
                    } else if (icons.has_key ("application-default-icon")) {
                        icon = icons["application-default-icon"];
                    }

                    // Ensure that texts are not null
                    string name = current_item["name"] ?? "";
                    string description = current_item["description"] ?? "";

                    if (description == "") {
                        item.change_app (
                            icon,
                            name,
                            name
                        );
                    } else {
                        item.change_app (
                            icon,
                            name,
                            name + ":\n" + description
                        );
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
        if ((double) apps.size % (double) (this.grid_y * this.grid_x) > 0) {
            this.total_pages = num_pages + 1;
        } else {
            this.total_pages = num_pages;
        }

        // Update pages
        if (this.total_pages > 1) {
            this.pages.visible = true;
            for (int p = 1; p <= this.pages.children.length (); p++) {
                if (p > this.total_pages) {
                    this.pages.children.nth_data (p - 1).visible = false;
                } else {
                    this.pages.children.nth_data (p - 1).visible = true;
                }
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
        // Use the Cairo context provided by GTK
        var context = ctx;

        // Semi-dark background
        Gtk.Allocation size;
        widget.get_allocation (out size);

        var linear_gradient = new Cairo.Pattern.linear (size.x, size.y, size.x, size.y + size.height);
        linear_gradient.add_color_stop_rgba (0.0, 0.0, 0.0, 0.0, 1);

        context.set_source (linear_gradient);
        context.paint ();

        return false;
    }

    private void do_left () {
        var current_item = this.grid.get_children ().index (this.get_focus ());

        int pos_x = - ((current_item % this.grid_y) - (this.grid_y - 1));
        int pos_y = - ((current_item / this.grid_y) - (this.grid_x - 1));

        if (pos_x - 1 >= 0) {
            this.grid.get_child_at (pos_x - 1, pos_y).grab_focus ();
        }

        if (current_item % this.grid_y == this.grid_y - 1) {
            this.page_left ();
        }
    }

    private void do_right () {
        var current_item = this.grid.get_children ().index (this.get_focus ());
        int pos_x = - ((current_item % this.grid_y) - (this.grid_y - 1));
        int pos_y = - ((current_item / this.grid_y) - (this.grid_x - 1));

        if (pos_x + 1 < this.grid_x) {
            this.grid.get_child_at (pos_x + 1, pos_y).grab_focus ();
        }

        if (current_item % this.grid_y == 0) {
            this.page_right ();
        }
    }

    private bool do_up () {
        var current_item = this.grid.get_children ().index (this.get_focus ());
        int pos_x = - ((current_item % this.grid_y) - (this.grid_y - 1));
        int pos_y = - ((current_item / this.grid_y) - (this.grid_x - 1));

        if (pos_y - 1 >= 0) {
            this.grid.get_child_at (pos_x, pos_y - 1).grab_focus ();
        }
        return true;
    }

    private bool do_down () {
        var current_item = this.grid.get_children ().index (this.get_focus ());
        int pos_x = - ((current_item % this.grid_y) - (this.grid_y - 1));
        int pos_y = - ((current_item / this.grid_y) - (this.grid_x - 1));

        if (pos_y + 1 < this.grid_y) {
            this.grid.get_child_at (pos_x, pos_y + 1).grab_focus ();
        }

        return true;
    }

    // Keyboard shortcuts
    public override bool key_press_event (Gdk.EventKey event) {
        switch (Gdk.keyval_name (event.keyval)) {
            case "Escape":
                this.destroy ();
                return true;
            case "a":
            case "Left":
                var current_item = this.grid.get_children ().index (this.get_focus ());
                if (current_item % this.grid_y == this.grid_y - 1) {
                    this.page_left ();
                    return true;
                }
                break;
            case "d":
            case "Right":
                var current_item = this.grid.get_children ().index (this.get_focus ());
                if (current_item % this.grid_y == 0) {
                    this.page_right ();
                    return true;
                }
                break;
            case "s":
            case "Down":
                return this.do_down ();
            case "w":
            case "Up":
                return this.do_up ();
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
                    this.get_focus ().button_release_event (
                        (Gdk.EventButton) new Gdk.Event (Gdk.EventType.BUTTON_PRESS)
                    );
                }
                return true;
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
        // Stop process monitoring if it is active
        if (this.is_monitoring_process) {
            this.is_monitoring_process = false;
            if (this.child_watch_id != 0) {
                GLib.Source.remove (this.child_watch_id);
                this.child_watch_id = 0;
            }
        }

        base.destroy ();
        Gtk.main_quit ();
    }

    // Method for monitoring applications
    private void start_application_monitoring (string command) {
        if (this.is_monitoring_process) {
            // If we are already monitoring a process, stop the previous monitoring.
            if (this.child_watch_id != 0) {
                GLib.Source.remove (this.child_watch_id);
                this.child_watch_id = 0;
            }
        }

        this.is_monitoring_process = true;

        // Start a thread that periodically monitors whether the application is still running.
        this.child_watch_id = GLib.Timeout.add_seconds (2, () => {
            if (!this.is_monitoring_process) {
                return false;
            }

            try {
                // Search for processes that match the command
                string[] spawn_args = {"pgrep", "-f", command};
                string output;
                int exit_status;

                GLib.Process.spawn_sync (null, spawn_args, null,
                    GLib.SpawnFlags.SEARCH_PATH, null, out output, null, out exit_status);

                // If we cannot find the process, the application has been closed.
                if (exit_status != 0 || output == null || output.strip () == "") {
                    this.is_monitoring_process = false;
                    this.child_watch_id = 0;

                    // Show the window again
                    GLib.Idle.add (() => {
                        this.show_all ();
                        return false;
                    });

                    return false; // Stop monitoring
                }

                return true; // Continue monitoring
            } catch (GLib.Error e) {
                warning ("Error while monitoring application: " + e.message);
                return true; // Continue monitoring
            }
        });
    }
}

static int main (string[] args) {
    /*
     * This is a workaround for libgnome-menu-3.0, for now doesn't have support to include .desktop entries
     * with the property OnlyShowIn set up. If the value of your XDG_CURRENT_DESKTOP environment variable 
     * its not present in OnlyShowIn property array, that .desktop entry isn't listed as part of the 
     * category tree.
     *
     * For more information see: https://gitlab.gnome.org/GNOME/gnome-menus/-/issues/23
     */
    var current_desktop = GLib.Environment.get_variable ("XDG_CURRENT_DESKTOP");
    if (current_desktop.up () != "GNOME") {
        current_desktop = current_desktop + ":GNOME";
        GLib.Environment.set_variable ("XDG_CURRENT_DESKTOP", current_desktop, true);
    }

    Gtk.init (ref args);
    Gtk.Application app = new Gtk.Application ("com.github.libredeb.lightpad", GLib.ApplicationFlags.FLAGS_NONE);

    // CSS Style Provider
    // Path where takes the CSS file
    string css_file = Config.PACKAGE_SHAREDIR +
        "/" + Config.PROJECT_NAME +
        "/" + "application.css";
    var css_provider = new Gtk.CssProvider ();

    try {
        css_provider.load_from_path (css_file);
        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default (), css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_USER
        );
    } catch (GLib.Error e) {
        warning ("Could not load CSS file: %s", css_file);
    }

    app.activate.connect ( () => {
        if (app.get_windows ().length () == 0) {
            var main_window = new LightPadWindow ();
            main_window.set_application (app);
            main_window.show_all ();
            Gtk.main ();
        }
    });

    if (args.length > 1) {
        switch (args[1]) {
            case "-v":
            case "--version":
                stdout.printf ("%s v%s (handheld)\n", Config.PROJECT_NAME, Config.PACKAGE_VERSION);
                return 0;
        }
    }

    app.run (args);
    return 0;

}
