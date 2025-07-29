/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020 Juan Pablo Lozano <libredeb@gmail.com>
 */

namespace LightPad.Frontend {

    public class Searchbar : Gtk.Box {

        // Constants
        const int WIDTH = 240;
        const int HEIGHT = 26;

        // Properties
        private Gtk.TextBuffer buffer;
        public Gtk.Entry entry;
        public Gtk.Image search_icon;
        private Gtk.Image clear_icon;
        /* protects against bug where get_text() will return ""
           if the user happens to type in the hint string */
        private bool is_hinted = true;
        public string hint_string;

        // Signals
        public signal void changed ();

        public string text {
            owned get {
                string current_text = this.buffer.text;
                return (current_text == this.hint_string && this.is_hinted) ? "" : current_text;
            }
            set {
                this.buffer.text = value;
                if (this.buffer.text == "") {
                    this.hint ();
                } else {
                    this.reset_font ();
                    this.entry.set_text (this.buffer.text);
                    this.clear_icon.visible = true;
                }
            }
        }

        public Searchbar () {
            this.hint_string = _("Search");
            this.buffer = new Gtk.TextBuffer (null);
            this.buffer.text = this.hint_string;

            // HBox properties
            this.set_homogeneous (false);
            this.set_can_focus (false);
            this.set_size_request (WIDTH, HEIGHT);

            // Wrapper
            // Space between the icon and the phrase search
            var wrapper = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
            this.add (wrapper);

            // Pack edit-find-symbolic icon
            var search_icon_wrapper = new Gtk.EventBox ();
            this.search_icon = new Gtk.Image.from_icon_name ("edit-find-symbolic", Gtk.IconSize.MENU);
            search_icon_wrapper.set_visible_window (false);
            search_icon_wrapper.add (this.search_icon);
            search_icon_wrapper.border_width = 4;
            search_icon_wrapper.button_release_event.connect ( () => { return true; } );
            wrapper.pack_start (search_icon_wrapper, false, true, 3);

            // Label properties
            this.entry = new Gtk.Entry ();
            this.entry.set_text (this.buffer.text);
            this.entry.set_has_frame (false);
            this.entry.set_alignment (0.0f);
            // We will manage the placeholder text through direct text manipulation and CSS
            this.entry.set_placeholder_text (this.hint_string);
            this.entry.set_hexpand (true);
            this.entry.set_halign (Gtk.Align.START);
            wrapper.pack_start (this.entry, true, true, 0);

            // Clear icon
            var clear_icon_wrapper = new Gtk.EventBox ();
            clear_icon_wrapper.set_visible_window (false);
            clear_icon_wrapper.border_width = 4;
            this.clear_icon = new Gtk.Image.from_icon_name ("edit-clear-symbolic", Gtk.IconSize.MENU);

            clear_icon_wrapper.add (this.clear_icon);
            clear_icon_wrapper.button_release_event.connect ( () => { this.hint (); return true; });
            clear_icon_wrapper.set_hexpand (true);
            clear_icon_wrapper.set_halign (Gtk.Align.END);
            wrapper.pack_end (clear_icon_wrapper, false, true, 3);

            // Connect signals and callbacks
            this.buffer.changed.connect (on_changed);
            this.draw.connect (this.draw_background);
            this.realize.connect (() => {
                this.hint (); // hint it
            });

            // Connect focus-in and focus-out signals to manage hint state
            this.entry.focus_in_event.connect ((event) => {
                if (this.is_hinted) {
                    this.entry.set_text(""); // Clear the hint text when focused
                    this.is_hinted = false;
                }
                return false;
            });
        }

        public void hint () {
            this.buffer.text = "";
            this.entry.set_text (this.hint_string);
            this.entry.get_style_context ().remove_class ("search_normal");
            this.entry.get_style_context ().add_class ("search_greyout");
            this.is_hinted = true;
            this.clear_icon.visible = false;
        }

        public void unhint () {
            this.text = "";
            this.reset_font ();
        }

        private void reset_font () {
            this.entry.get_style_context ().remove_class ("search_greyout");
            this.entry.get_style_context ().add_class ("search_normal");
            this.is_hinted = false;
        }

        private void on_changed () {
            // Send changed signal
            this.changed ();
        }

        private bool draw_background (Gtk.Widget widget, Cairo.Context ctx) {
            widget.get_style_context ().add_class ("search_bg");
            return false;
        }

    }

}
