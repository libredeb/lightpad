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

    public Gee.ArrayList<Gee.HashMap<string, string>> apps = new Gee.ArrayList<Gee.HashMap<string, string>> ();
    public Gee.HashMap<string, Gdk.Pixbuf> icons = new Gee.HashMap<string, Gdk.Pixbuf>();
    public Gee.ArrayList<Gee.HashMap<string, string>> filtered = new Gee.ArrayList<Gee.HashMap<string, string>> ();
    public LightPad.Frontend.Indicators pages;
    
    public int icon_size;
    public int total_pages;
    
    public Gtk.Box top_spacer;
    public GLib.List<LightPad.Frontend.AppItem> children = new GLib.List<LightPad.Frontend.AppItem> ();
    public LightPad.Frontend.Searchbar searchbar;
    public Gtk.Grid grid;
    
    private int grid_x;
    private int grid_y;

    public LightPadWindow () {
        Gdk.Rectangle monitor_dimensions;
        Gdk.Screen default_screen = Gdk.Screen.get_default ();
        monitor_dimensions = default_screen.get_display ().get_primary_monitor ().get_geometry ();

        // Window properties
        this.set_title ("LightPad");
        /* Skip that a workspace switcher and taskbars displays a 
           thumbnail representation of the window in the screen */
        this.set_skip_pager_hint (true);
        this.set_skip_taskbar_hint (true);
        this.set_type_hint (Gdk.WindowTypeHint.NORMAL);
        this.fullscreen ();
        message ("The monitor dimensions are: %dx%d", monitor_dimensions.width,  monitor_dimensions.height);
        this.set_default_size (monitor_dimensions.width,  monitor_dimensions.height);
        
        // Set apps icon size
        double scale_factor = (1.0/3.0);
        double suggested_size = Math.pow (monitor_dimensions.width * monitor_dimensions.height, scale_factor);
        suggested_size = suggested_size / 1.7;
        if (suggested_size < 27) {
            this.icon_size = 24;
        } else if (suggested_size >= 27 && suggested_size < 40) {
            this.icon_size = 32;
        } else if (suggested_size >= 40 && suggested_size < 56) {
            this.icon_size = 48;
        } else if (suggested_size >= 56) {
            this.icon_size = 64;
        }
        message ("The apps icon size is: %d", this.icon_size);
        
        // Get all apps
        LightPad.Backend.DesktopEntries.enumerate_apps (this.icons, this.icon_size, out this.apps);
        
        // Add container wrapper
        var wrapper = new Gtk.EventBox (); // Used for the scrolling and button press events
        wrapper.set_visible_window (false);
        this.add (wrapper);

        // Add container
        var container = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        wrapper.add (container);

        // Add top bar
        var bottom = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        this.top_spacer = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 20);
        this.top_spacer.realize.connect ( () => { this.top_spacer.visible = true; } );
        this.top_spacer.can_focus = true;
        bottom.pack_start (this.top_spacer, false, false, 0);

        // Searchbar
        this.searchbar = new LightPad.Frontend.Searchbar ("...");
        message ("Searchbar created!");
        this.searchbar.changed.connect (this.search);

        // Lateral distance (120 are the pixels of the searchbar width)
        int screen_half = (monitor_dimensions.width / 2) - 120;
        bottom.pack_start (this.searchbar, false, true, screen_half);
        
        // Upstairs
        container.pack_start (bottom, false, true, 20);
        
        this.grid = new Gtk.Grid();
        this.grid.set_row_spacing (70);
        this.grid.set_column_spacing (30);
        this.grid.set_halign (Gtk.Align.CENTER);

        // Make icon grid and populate
        // For Monitor 5:4 and 4:3
        if ((monitor_dimensions.width / (double) monitor_dimensions.height) < 1.4) {
            this.grid_x = 5;
            this.grid_y = 5;
        } else { // Monitor 16:9
            this.grid_y = 6;
            this.grid_x = 4;
        }

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
                this.pages.append (p.to_string ());
            }
        }
        this.pages.set_active (0);

        // Signals and callbacks
        this.add_events (Gdk.EventMask.SCROLL_MASK);
        //this.button_release_event.connect ( () => { this.destroy(); return false; });
        this.draw.connect (this.draw_background);
        //this.focus_out_event.connect ( () => { this.destroy(); return true; } ); // close Slingscold when the window loses focus

    }
    
    private void search() {
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
                var item = new LightPad.Frontend.AppItem (this.icon_size);
                this.children.append (item);

                item.button_press_event.connect ( () => { item.grab_focus (); return true; } );
                item.enter_notify_event.connect ( () => { item.grab_focus (); return true; } );
                item.leave_notify_event.connect ( () => { this.top_spacer.grab_focus (); return true; } );
                item.button_release_event.connect ( () => {
                    try {
                        new GLib.DesktopAppInfo.from_filename (this.filtered.get((int) (this.children.index (item) + (this.pages.active * this.grid_y * this.grid_x)))["desktop_file"]).launch (null, null);
                        this.destroy ();
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
        Gtk.Allocation size;
        widget.get_allocation (out size);
        var context = Gdk.cairo_create (widget.get_window ());

        // Semi-dark background
        var linear_gradient = new Cairo.Pattern.linear (size.x, size.y, size.x, size.y + size.height);
        linear_gradient.add_color_stop_rgba (0.0, 0.0, 0.0, 0.0, 1);
        linear_gradient.add_color_stop_rgba (0.50, 0.0, 0.0, 0.0, 0.90);
        linear_gradient.add_color_stop_rgba (0.99, 0.0, 0.0, 0.0, 0.80);

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
            case "BackSpace":
                this.searchbar.text = this.searchbar.text.slice (0, (int) this.searchbar.text.length - 1);
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
        switch (event.direction.to_string()) {
            case "GDK_SCROLL_UP":
            case "GDK_SCROLL_LEFT":
                this.page_left ();
                break;
            case "GDK_SCROLL_DOWN":
            case "GDK_SCROLL_RIGHT":
                this.page_right ();
                break;
        }

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
    string css_file = "/usr/share/lightpad/application.css";
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
