/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020 Juan Pablo Lozano <libredeb@gmail.com>
 */

public class LightPadWindow : Widgets.CompositedWindow {

    public static string user_home = GLib.Environment.get_variable ("HOME");
    public static string[] terminal_emulator = LightPadWindow.resolve_terminal_emulator ();
    public Gee.ArrayList<Gee.HashMap<string, string>> apps = new Gee.ArrayList<Gee.HashMap<string, string>> ();
    public Gee.HashMap<string, Gdk.Pixbuf> icons = new Gee.HashMap<string, Gdk.Pixbuf> ();
    public Gee.ArrayList<Gee.HashMap<string, string>> filtered = new Gee.ArrayList<Gee.HashMap<string, string>> ();
    public LightPad.Frontend.Indicators pages;
    public Gtk.Box container;
    public Gtk.Label loading_label;

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

    private GLib.Thread<int> joystick_thread;
    private bool is_joystick_thread_active = true;

    // Variables to monitor the launched process
    private GLib.Subprocess? monitored_subprocess = null;
    private bool is_monitoring_process = false;
    private Gtk.Widget? last_focused_widget = null;

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

        // Disable mouse events completely
        this.set_events (Gdk.EventMask.KEY_PRESS_MASK | Gdk.EventMask.SCROLL_MASK);

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
        this.container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        wrapper.add (this.container);

        // Add pagess_wrapper container
        var bottom = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        bottom.show.connect (() => {
            this.present_all_apps ();
        });

        // Upstairs (padding is the space between search bar and the grid)
        this.container.pack_start (bottom, true, true, 14);

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

        this.container.pack_start (this.grid, true, true, 0);

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

        this.loading_label = new Gtk.Label ("");
        this.loading_label.set_markup ("<span size='xx-large' foreground='white'><b>Loading…</b></span>");
        this.loading_label.visible = false;
        this.loading_label.no_show_all = true;
        this.loading_label.set_halign (Gtk.Align.CENTER);
        this.loading_label.set_valign (Gtk.Align.CENTER);
        this.container.pack_start (this.loading_label, true, true, 0);

        // Hide mouse cursor completely
        this.show.connect (() => {
            if (this.get_window () != null) {
                this.get_window ().set_cursor (
                    new Gdk.Cursor.for_display (display, Gdk.CursorType.BLANK_CURSOR)
                );
            }
        });

        // Signals and callbacks
        this.add_events (Gdk.EventMask.SCROLL_MASK);

        this.draw.connect (this.draw_background);

        joystick_thread = new GLib.Thread<int> ("JoystickThread", () => {
            if (SDL.init (SDL.InitFlag.GAMECONTROLLER) != 0) {
                warning ("SDL init Error: %s", SDL.get_error ());
                return 0;
            }

            if (SDL.Input.GameController.load_mapping_file ("/usr/share/lightpad/gamecontrollerdb.txt") == -1) {
                warning ("Unable to load game controller database file");
            }
            int num_controllers = SDL.Input.GameController.count ();

            if (
                (num_controllers < 1) ||
                (!SDL.Input.GameController.is_game_controller (0))
            ) {
                warning (num_controllers < 1
                    ? "No game controller detected"
                    : "Game controller is not compatible"
                );
                SDL.quit ();
                return 0;
            }

            var controller = new SDL.Input.GameController (0);
            if (controller == null) {
                warning ("Unable to open game controller: %s", SDL.get_error ());
                SDL.quit ();
                return 0;
            }

            // For performance control on axis
            const int AXIS_DEAD_ZONE = 8000; // Threshold for ignoring stick noise
            const uint AXIS_THROTTLE_MS = 150; // Milliseconds of delay between focus movements
            uint64 last_axis_h_move = 0;
            uint64 last_axis_v_move = 0;

            SDL.Event event;
            while (true) {
                while (SDL.Event.poll (out event) != 0) {
                    if (this.is_joystick_thread_active) {
                        switch (event.type) {
                            case SDL.EventType.CONTROLLERBUTTONDOWN:
                                var button = (SDL.Input.GameController.Button) event.cbutton.button;
                                switch (button) {
                                    case SDL.Input.GameController.Button.A:
                                    case SDL.Input.GameController.Button.B:
                                        if (this.filtered.size >= 1) {
                                            var focused_widget = this.get_focus ();
                                            if (focused_widget != null) {
                                                focused_widget.button_release_event (
                                                    (Gdk.EventButton) new Gdk.Event (Gdk.EventType.BUTTON_PRESS)
                                                );
                                            }
                                        }
                                        break;
                                    case SDL.Input.GameController.Button.DPAD_UP:
                                        this.do_up ();
                                        break;
                                    case SDL.Input.GameController.Button.DPAD_DOWN:
                                        this.do_down ();
                                        break;
                                    case SDL.Input.GameController.Button.DPAD_LEFT:
                                        this.do_left ();
                                        break;
                                    case SDL.Input.GameController.Button.DPAD_RIGHT:
                                        this.do_right ();
                                        break;
                                    default:
                                        break;
                                }
                                break;
                            case SDL.EventType.CONTROLLERAXISMOTION:
                                var axis = (SDL.Input.GameController.Axis) event.caxis.axis;
                                var value = event.caxis.value;
                                var now = GLib.get_monotonic_time () / 1000; // to milliseconds

                                // Horizontal axis (left stick)
                                if (axis == SDL.Input.GameController.Axis.LEFTX) {
                                    if (value < -AXIS_DEAD_ZONE && (now - last_axis_h_move > AXIS_THROTTLE_MS)) {
                                        this.do_left ();
                                        last_axis_h_move = now;
                                    } else if (value > AXIS_DEAD_ZONE && (now - last_axis_h_move > AXIS_THROTTLE_MS)) {
                                        this.do_right ();
                                        last_axis_h_move = now;
                                    }
                                }
                                // Vertical axis (left stick)
                                if (axis == SDL.Input.GameController.Axis.LEFTY) {
                                    if (value < -AXIS_DEAD_ZONE && (now - last_axis_v_move > AXIS_THROTTLE_MS)) {
                                        this.do_up ();
                                        last_axis_v_move = now;
                                    } else if (value > AXIS_DEAD_ZONE && (now - last_axis_v_move > AXIS_THROTTLE_MS)) {
                                        this.do_down ();
                                        last_axis_v_move = now;
                                    }
                                }
                                break;
                            default:
                                break;
                        }
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
                item.button_release_event.connect ( () => {
                    this.last_focused_widget = item;
                    int child_index = this.children.index (item);
                    int page_active = this.pages.active;
                    /* Prevent indicators pages to get a negative one (-1)
                        and fix with this the bug 003 where a negative result
                        is obtained and that index does not exist */
                    if (page_active < 0) {
                        page_active = 0;
                    }
                    int app_index = (int) (child_index + (page_active * this.grid_y * this.grid_x));

                    // Hide the apps grid and show loading label
                    this.pages.visible = false;
                    this.pages.no_show_all = true;
                    this.grid.visible = false;
                    this.grid.no_show_all = true;
                    this.loading_label.no_show_all = false;
                    this.loading_label.visible = true;

                    // Force a redraw to ensure the label is visible
                    this.queue_draw ();
                    this.show_all ();

                    // Add a small delay to ensure the label is visible on slower devices
                    GLib.Timeout.add (300, () => {
                        this.launch_and_monitor_application (app_index);
                        return false; // Don't repeat
                    });

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
        var focused_widget = this.get_focus ();
        if (focused_widget == null) return;

        var current_item = this.grid.get_children ().index (focused_widget);

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
        var focused_widget = this.get_focus ();
        if (focused_widget == null) return;

        var current_item = this.grid.get_children ().index (focused_widget);
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
        var focused_widget = this.get_focus ();
        if (focused_widget == null) return false;

        var current_item = this.grid.get_children ().index (focused_widget);
        int pos_x = - ((current_item % this.grid_y) - (this.grid_y - 1));
        int pos_y = - ((current_item / this.grid_y) - (this.grid_x - 1));

        if (pos_y - 1 >= 0) {
            this.grid.get_child_at (pos_x, pos_y - 1).grab_focus ();
        }
        return true;
    }

    private bool do_down () {
        var focused_widget = this.get_focus ();
        if (focused_widget == null) return false;

        var current_item = this.grid.get_children ().index (focused_widget);
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
                var focused_widget = this.get_focus ();
                if (focused_widget != null) {
                    var current_item = this.grid.get_children ().index (focused_widget);
                    if (current_item % this.grid_y == this.grid_y - 1) {
                        this.page_left ();
                        return true;
                    }
                }
                break;
            case "d":
            case "Right":
                var focused_widget = this.get_focus ();
                if (focused_widget != null) {
                    var current_item = this.grid.get_children ().index (focused_widget);
                    if (current_item % this.grid_y == 0) {
                        this.page_right ();
                        return true;
                    }
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
                    var focused_widget = this.get_focus ();
                    if (focused_widget != null) {
                        focused_widget.button_release_event (
                            (Gdk.EventButton) new Gdk.Event (Gdk.EventType.BUTTON_PRESS)
                        );
                    }
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
        // Detiene el procesamiento de eventos del joystick
        this.is_joystick_thread_active = false;

        // Limpia los recursos de SDL
        SDL.quit ();

        // Stop process monitoring if it is active
        if (this.is_monitoring_process && this.monitored_subprocess != null) {
            this.is_monitoring_process = false;
            this.monitored_subprocess = null;
        }

        base.destroy ();
        Gtk.main_quit ();
    }

    // Method to launch and monitor applications using GLib.Subprocess
    private void launch_and_monitor_application (int app_index) {
        // Check if this is the exit application
        string app_id = this.filtered.get (app_index)["id"];
        if (app_id == Resources.LIGHTPAD_EXIT_ID) {
            // Close LightPad instead of launching an application
            this.destroy ();
            return;
        }

        this.is_joystick_thread_active = false;
        if (this.is_monitoring_process && this.monitored_subprocess != null) {
            // If we are already monitoring a process, stop the previous monitoring
            this.is_monitoring_process = false;
            this.monitored_subprocess = null;
        }

        this.is_monitoring_process = true;

        try {
            string command = sanitize_command (this.filtered.get (app_index)["command"]);
            string[] args = {};

            // Parse the command into arguments
            GLib.Shell.parse_argv (command, out args);

            // Create subprocess flags
            GLib.SubprocessFlags flags = GLib.SubprocessFlags.STDIN_INHERIT |
                                       GLib.SubprocessFlags.STDOUT_PIPE |
                                       GLib.SubprocessFlags.STDERR_PIPE;

            // Handle terminal applications
            if (this.filtered.get (app_index)["terminal"] == "true") {
                // For terminal applications, we need to use a terminal emulator
                string[] terminal_args = {terminal_emulator[0], terminal_emulator[1], command};
                this.monitored_subprocess = new GLib.Subprocess.newv (terminal_args, flags);
            } else {
                // For regular applications, launch directly
                this.monitored_subprocess = new GLib.Subprocess.newv (args, flags);
            }

            // Set up the callback for when the subprocess exits
            this.monitored_subprocess.wait_async.begin (null, (obj, res) => {
                try {
                    this.monitored_subprocess.wait_async.end (res);

                    // Process has finished, show lightpad again
                    this.is_monitoring_process = false;
                    this.monitored_subprocess = null;

                    GLib.Idle.add (this.restore_ui_and_focus);
                } catch (GLib.Error e) {
                    warning ("Error waiting for subprocess: " + e.message);
                    // Show lightpad anyway in case of error
                    this.is_monitoring_process = false;
                    this.monitored_subprocess = null;

                    GLib.Idle.add (this.restore_ui_and_focus);
                }
            });

        } catch (GLib.Error e) {
            warning ("Error launching application: " + e.message);
            // Show lightpad if we couldn't launch the application
            this.is_monitoring_process = false;
            this.monitored_subprocess = null;

            GLib.Idle.add (this.restore_ui_and_focus);
        }
    }

    private bool restore_ui_and_focus () {
        // Restore the interface
        this.pages.visible = true;
        this.pages.no_show_all = false;
        this.grid.visible = true;
        this.grid.no_show_all = false;
        this.loading_label.visible = false;
        this.loading_label.no_show_all = true;
        this.is_joystick_thread_active = true;
        this.show_all ();

        if (this.last_focused_widget != null) {
            this.last_focused_widget.grab_focus ();
        }
        return false;
    }

    /*
     * @param command_line The command string to sanitize.
     * @return The cleaned command string without any placeholders.
     */
    public static string sanitize_command (string command_line) {
        string cleaned_command = command_line;

        try {
            // Pattern for flatpak placeholders (e.g., "@@u %U @@" or "@@ %f @@").
            // This regex is optimized to capture any content between the "@@" delimiters,
            // ensuring it works for various flatpak placeholder formats.
            Regex flatpak_regex = new Regex ("(\\s@@.*@@)", RegexCompileFlags.OPTIMIZE);
            cleaned_command = flatpak_regex.replace (cleaned_command, -1, 0, "", 0);

            // Pattern for standard placeholders (e.g., "%u", "%f").
            // This regex efficiently handles one or more placeholders at the end of the string.
            Regex normal_regex = new Regex ("(\\s%[a-zA-Z])+|(\\s%[a-zA-Z]+)", RegexCompileFlags.OPTIMIZE);
            cleaned_command = normal_regex.replace (cleaned_command, -1, 0, "", 0);
        } catch (GLib.RegexError e) {
            warning ("Regex Error: %s", e.message);
        }

        return cleaned_command.strip ();
    }

    /*
     * Resolves the terminal emulator available on the system.
     * Runs once when the class is loaded.
     * @return the name of the available terminal emulator and its flag to run terminal applications
     */
    private static string[] resolve_terminal_emulator () {
        // Dictionary of emulators and their flags
        var terminal_emulators = new GLib.HashTable<string, string> (GLib.str_hash, GLib.str_equal);
        terminal_emulators["xdg-terminal-exec"] = "";
        terminal_emulators["lxterminal"] = "-e";
        terminal_emulators["kgx"] = "-e";
        terminal_emulators["gnome-terminal"] = "--";
        terminal_emulators["ptyxis"] = "-x";
        terminal_emulators["mate-terminal"] = "-x";
        terminal_emulators["xfce4-terminal"] = "-x";
        terminal_emulators["tilix"] = "-e";
        terminal_emulators["konsole"] = "-e";
        terminal_emulators["nxterm"] = "-e";
        terminal_emulators["color-xterm"] = "-e";
        terminal_emulators["rxvt"] = "-e";
        terminal_emulators["dtterm"] = "-e";

        string? terminal_emulator_command = null;
        string? terminal_flag = null;

        // Search for the first available terminal emulator
        foreach (var terminal_name in terminal_emulators.get_keys ()) {
            if (GLib.Environment.find_program_in_path (terminal_name) != null) {
                terminal_emulator_command = terminal_name;
                terminal_flag = terminal_emulators[terminal_name];
                break;
            }
        }

        if (terminal_emulator_command == null) {
            warning ("No terminal emulator found, trying xterm instead");
            return new string[] { "xterm", "-e" };
        }

        return new string[] { terminal_emulator_command, terminal_flag };
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
