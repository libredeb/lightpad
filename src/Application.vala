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
    public int scroll_sensitivity = 12;

    public Gdk.Rectangle monitor_dimensions;
    public Gtk.Box top_spacer;
    public GLib.List<LightPad.Frontend.AppItem> children = new GLib.List<LightPad.Frontend.AppItem> ();
    public LightPad.Frontend.Searchbar searchbar;
    public Gtk.Grid grid;

    private int grid_x;
    private int grid_y;

    public bool dynamic_background = false;
    public double factor_scaling;
    public string file_jpg = user_home + Resources.LIGHTPAD_CONFIG_DIR +
        "/" + "background.jpg";
    public string file_png = user_home + Resources.LIGHTPAD_CONFIG_DIR +
        "/" + "background.png";
    public Gdk.Pixbuf image_pf;
    public Cairo.ImageSurface image_sf;
    public Cairo.Pattern pattern;

    public LightPadWindow () {
        // There isn't always a primary monitor.
        Gdk.Monitor monitor = get_display ().get_primary_monitor () ?? get_display ().get_monitor (0);
        Gdk.Rectangle pixel_geo = monitor.get_geometry ();
        // get_geometry() returns "device pixels", but we need "application pixels".
        monitor_dimensions.width = pixel_geo.width / monitor.get_scale_factor ();
        monitor_dimensions.height = pixel_geo.height / monitor.get_scale_factor ();

        FileConfig config = new FileConfig (
            monitor_dimensions.width,
            monitor_dimensions.height,
            user_home + Resources.CONFIG_FILE
        );
        // For compatibility, maybe add FileConfig to LightPadWindow someday
        this.icon_size = config.item_icon_size;
        this.font_size = config.item_font_size;
        this.item_box_width = config.item_box_width;
        this.item_box_height = config.item_box_height;
        this.grid_y = config.grid_y;
        this.grid_x = config.grid_x;

        debug ("The monitor dimensions are: %dx%d", monitor_dimensions.width, monitor_dimensions.height);
        debug ("The apps icon size is: %d", this.icon_size);
        debug ("The grid size are: %dx%d", this.grid_y, this.grid_x);

        // Window properties
        this.set_title ("LightPad");
        /* Skip that a workspace switcher and taskbars displays a
           thumbnail representation of the window in the screen */
        this.set_skip_pager_hint (true);
        this.set_skip_taskbar_hint (true);
        this.set_type_hint (Gdk.WindowTypeHint.NORMAL);

        var display = Gdk.Display.get_default ();
        debug ("Amount of Monitors: %d", display.get_n_monitors ());
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
        // First order the apps alphabetically
        this.apps.sort ((a, b) => GLib.strcmp (a["id"], b["id"]));

        // Add container wrapper
        var wrapper = new Gtk.EventBox (); // Used for the scrolling and button press events
        wrapper.set_visible_window (false);
        this.add (wrapper);

        // Add container
        var container = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        wrapper.add (container);

        // Add top bar
        var bottom = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        // Searchbar
        this.searchbar = new LightPad.Frontend.Searchbar ();
        debug ("Searchbar created!");
        this.searchbar.changed.connect (this.search);
        this.searchbar.button_release_event.connect ((sbar_widget, sbar_event) => {
            /*
             * This event handler is for clicks directly on the searchbar itself.
             * We want to consume this event so the parent window's handler doesn't see it.
             * This will prevent the Lightpad from closing when clicked on the searchbar.
             * You might want to add specific logic for the searchbar here (e.g., focus it).
             * For now, just consume the event.
             */
            // Return true to stop event propagation (consume the event)
            return true;
        });

        // Lateral distance (120 are the pixels of the searchbar width)
        int screen_half = (monitor_dimensions.width / 2) - 120;
        bottom.pack_start (this.searchbar, false, true, screen_half);

        // Upstairs (padding is the space between search bar and the grid)
        container.pack_start (bottom, false, true, 32);

        this.grid = new Gtk.Grid ();
        this.grid.set_row_spacing (config.grid_row_spacing);
        this.grid.set_column_spacing (config.grid_col_spacing);
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
        container.pack_end (pages_wrapper, false, true, 15);

        // Find number of pages and populate
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
        // Dynamic Background
        if (GLib.File.new_for_path (file_jpg).query_exists ()) {
            this.dynamic_background = true;
            try {
                image_pf = new Gdk.Pixbuf.from_file (file_jpg);
            } catch (GLib.Error e) {
                warning ("Cant create Pixbuf background!");
            }
        } else if (GLib.File.new_for_path (file_png).query_exists ()) {
            this.dynamic_background = true;
            image_sf = new Cairo.ImageSurface.from_png (file_png);
            pattern = new Cairo.Pattern.for_surface (image_sf);
            pattern.set_extend (Cairo.Extend.PAD);
            int w = image_sf.get_width ();
            factor_scaling = (double) ((double) ((monitor_dimensions.width * 100) / w) / 100);
        }

        this.draw.connect (this.draw_background);
        // close Lightpad when the window loses focus
        this.focus_out_event.connect ( () => {
            this.hide ();
            GLib.Timeout.add_seconds (1, () => {
                this.destroy ();
                return GLib.Source.REMOVE;
            });
            return true;
        } );

        // close Lightpad when we clic on empty area (original code block, slightly adjusted)
        this.button_release_event.connect ( (widget, event) => {
            double event_x = event.x;
            double event_y = event.y;

            Gtk.Allocation searchbar_allocation;
            this.searchbar.get_allocation (out searchbar_allocation);

            double x_relative_to_searchbar = event_x - searchbar_allocation.x;
            double y_relative_to_searchbar = event_y - searchbar_allocation.y;

            int searchbar_width = searchbar_allocation.width;
            int searchbar_height = searchbar_allocation.height;

            bool clicked_inside_searchbar =
                (x_relative_to_searchbar >= 0 && x_relative_to_searchbar <= searchbar_width) &&
                (y_relative_to_searchbar >= 0 && y_relative_to_searchbar <= searchbar_height);

            if (clicked_inside_searchbar) {
                /*
                 * If click was inside searchbar, do nothing here. The searchbar's own handler
                 * should have already consumed the event by returning 'true'.
                 * This 'false' here allows other potential parent handlers (unlikely in this case)
                 * to still see the event, but the searchbar itself already consumed it.
                 */
                 return false;
            } else {
                // If click was outside searchbar, hide Lightpad
                this.hide ();
                GLib.Timeout.add_seconds (1, () => {
                    this.destroy ();
                    return GLib.Source.REMOVE;
                });
                return true; // Consume the event here to prevent further propagation after hide
            }
        } );

    }

    private void search () {
        var current_text = this.searchbar.text.down ();
        this.filtered.clear ();

        foreach (Gee.HashMap<string, string> app in this.apps) {
            if ((app["name"] != null && current_text in app["name"].down ()) ||
                (app["description"] != null && current_text in app["description"].down ()) ||
                (app["command"] != null && current_text in app["command"].down ())) {
                this.filtered.add (app);
            }
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
                        /* 
                         * Prevent indicators pages to get a negative one (-1) and fix with this the bug 003
                         * where a negative result is obtained and that index does not exist
                         */
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
                        this.hide ();
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
        /* 
         * Fix for bug 001 with message:
         * arraylist.c:1181:gee_array_list_real_get: assertion failed: (index >= 0) 
         */
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
                    if (icons.has_key(current_item["command"])) {
                        icon = icons[current_item["command"]];
                    } else if (icons.has_key("application-default-icon")) {
                        icon = icons["application-default-icon"];
                    }

                    // Ensure that texts are not null
                    string name = current_item["name"] ?? "";
                    string description = current_item["description"] ?? "";

                    // Update app
                    if (current_item["description"] == null || current_item["description"] == "") {
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

        Gtk.Allocation widget_size;
        // Get the allocation (size and position) of the widget/window being drawn
        widget.get_allocation (out widget_size);

        if (this.dynamic_background) {
            if (image_pf != null) { // If JPG exist, prefer this
                double image_width = (double) image_pf.width;
                double image_height = (double) image_pf.height;

                // Calculate scaling factors to fill the widget area
                double scale_x = widget_size.width / image_width;
                double scale_y = widget_size.height / image_height;

                // Use the larger scale factor to ensure the image covers the entire widget (aspect fill)
                // Ternary expression for Math.Max
                double scale_factor = (scale_x > scale_y) ? scale_x : scale_y;

                // Calculate the dimensions of the scaled image
                double scaled_image_width = image_width * scale_factor;
                double scaled_image_height = image_height * scale_factor;

                // Calculate offsets to center the scaled image within the widget
                double offset_x = (widget_size.width - scaled_image_width) / 2.0;
                double offset_y = (widget_size.height - scaled_image_height) / 2.0;

                // Save the current state of the Cairo context before transformations
                context.save ();

                // Apply translation to center the image
                context.translate (offset_x, offset_y);

                // Apply scaling
                context.scale (scale_factor, scale_factor);

                // Set the pixbuf as the source and paint it
                Gdk.cairo_set_source_pixbuf (context, image_pf, 0, 0);
                context.paint ();

                // Restore the context to its original state (undo translate/scale)
                context.restore ();
            } else { // Is PNG image
                context.scale (factor_scaling, factor_scaling);
                context.set_source (pattern);
                context.paint (); // Paint the PNG here
            }
        } else {
            // Semi-dark background
            Gtk.Allocation size;
            widget.get_allocation (out size);

            var linear_gradient = new Cairo.Pattern.linear (size.x, size.y, size.x, size.y + size.height);
            linear_gradient.add_color_stop_rgba (0.0, 0.30, 0.30, 0.30, 1);

            context.set_source (linear_gradient);
            context.paint ();
        }

        return false;
    }

    // Keyboard shortcuts
    public override bool key_press_event (Gdk.EventKey event) {
        switch (Gdk.keyval_name (event.keyval)) {
            case "Escape":
                this.destroy ();
                return true;
            case "space":
                if (
                    (event.state == Gdk.ModifierType.CONTROL_MASK) ||
                    (event.state == Gdk.ModifierType.SUPER_MASK)
                ) {
                    this.destroy ();
                    return true;
                }
                this.searchbar.text = this.searchbar.text + event.str;
                break;
            case "Super_L":
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
                    this.get_focus ().button_release_event (
                        (Gdk.EventButton) new Gdk.Event (Gdk.EventType.BUTTON_PRESS)
                    );
                }
                return true;
            case "BackSpace":
                if (this.searchbar.text.length > 0) {
                    this.searchbar.text = this.searchbar.text.slice (0, (int) this.searchbar.text.length - 1);
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
            default:
                this.searchbar.text = this.searchbar.text + event.str;
                break;
        }

        base.key_press_event (event);
        return false;
    }

    // Scrolling left/right for pages
    public override bool scroll_event (Gdk.EventScroll event) {
        scroll_times += 1;
        var direction = event.direction.to_string ();
        if ((direction == "GDK_SCROLL_UP" || direction == "GDK_SCROLL_LEFT")
                                    && (scroll_times >= scroll_sensitivity)) {
            this.page_left ();
        } else if ((direction == "GDK_SCROLL_DOWN" || direction == "GDK_SCROLL_RIGHT")
                                    && (scroll_times >= scroll_sensitivity)) {
            this.page_right ();
        }
        // If the direction is GDK_SCROLL_SMOOTH skip it
        return false;
    }

    // Override destroy for fade out and stuff
    public new void destroy () {
        base.destroy ();
        Gtk.main_quit ();
    }

}

private bool setup_config_dir (string home) {
    var dir = GLib.File.new_for_path (home + Resources.LIGHTPAD_CONFIG_DIR);

    if (!dir.query_exists ()) {
        try {
            dir.make_directory_with_parents ();
            return true;
        } catch (GLib.Error e) {
            warning ("Could not create configuration directory: %s", e.message);
            return false;
        }
    }
    return true;
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
    Gtk.Application app = new Gtk.Application ("io.github.libredeb.lightpad", GLib.ApplicationFlags.FLAGS_NONE);
    app.add_main_option_entries (Resources.LIGHTPAD_OPTIONS);

    // CSS Styles, path where takes the CSS file
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

    app.activate.connect (() => {
        var main_window = app.active_window;

        if (main_window == null) {
            main_window = new LightPadWindow ();
            main_window.set_application (app);
            main_window.show_all ();
            Gtk.main ();
        } else {
            main_window.destroy ();
        }
    });

    if (args.length > 1) {
        string home = GLib.Environment.get_variable ("HOME");
        // Make sure the configuration directory exists
        if (!setup_config_dir (home)) {
            stderr.printf ("Could not create configuration directory.");
            return 1;
        }

        switch (args[1]) {
            case "-h":
            case "--help":
                app.run (args);
                return 0;
            case "-v":
            case "--version":
                stdout.printf ("%s v%s\n", Config.PROJECT_NAME, Config.PACKAGE_VERSION);
                return 0;
            case "-s":
            case "--save-config":
                FileConfig configfile = new FileConfig (0, 0, Resources.CONFIG_FILE);
                string configfile_path = home + Resources.CONFIG_FILE;

                var keyfile = configfile.get_key_file ();
                try {
                    FileUtils.set_contents (configfile_path, keyfile.to_data ());
                    print ("Configuration saved in: %s\n", configfile_path);
                } catch (Error e) {
                    stderr.printf ("Error saving configuration: %s\n", e.message);
                    return 1;
                }

                return 0;
            case "-c":
            case "--clear-config":
                string configfile_path = home + Resources.CONFIG_FILE;

                if (GLib.File.new_for_path (configfile_path).query_exists ()) {
                    if (GLib.FileUtils.remove (configfile_path) == 0) {
                        stdout.printf ("Configuration successfully cleared.\n");
                    } else {
                        stdout.printf ("Unable to clear configuration.\n");
                        return 1;
                    }
                } else {
                    stdout.printf ("No need to clear the configuration.\n");
                    return 1;
                }

                return 0;
            case "-b":
            case "--background":
                if (args.length != 3) {
                    stderr.printf ("Usage: %s [-b, --background] <image_path>\n", args[0]);
                    return 1;
                }

                string input_path = args[2];
                string output_path = GLib.Environment.get_variable ("HOME") + Resources.LIGHTPAD_BACKGROUND;

                try {
                    GLib.File input_file = GLib.File.new_for_path (input_path);
                    if (!input_file.query_exists (null)) {
                        stderr.printf ("Error! Input file does not exist: %s\n", input_path);
                        return 1;
                    }

                    Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file (input_path);
                    pixbuf.savev (output_path, "jpeg", {"quality"}, {"90"});
                    print ("Custom background successfully applied!\n");
                } catch (Error e) {
                    stderr.printf ("Error: %s\n", e.message);
                    return 1;
                }

                return 0;
            default:
                stdout.printf ("Unknown option '%s'. See 'man %s'.\n", args[1], args[0]);
                return 1;
        }
    }

    app.run (args);
    return 0;

}
