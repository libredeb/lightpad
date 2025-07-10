/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020 Juan Pablo Lozano <libredeb@gmail.com>
 */

 namespace LightPad.Frontend {

    public class AppItem : Gtk.EventBox {

        private Gdk.Pixbuf icon;
        private LightPad.Frontend.Color prominent;
        private string label;
        private Gtk.Box wrapper;
        private double font_size;
        private int icon_size;

        const int FPS = 24;
        const int DURATION = 200;
        const int RUN_LENGTH = (int)(DURATION / FPS); // Total number of frames
        private int current_frame = 1; // Run length, in frames

        public AppItem (int size, double font_size, int box_width, int box_height) {
            this.icon_size = size;
            this.font_size = font_size;

            // EventBox Properties, a box that show up on hover
            this.set_visible_window (false);
            this.can_focus = true;
            // Height is also the padding between icon and label's height
            this.set_size_request (box_width, box_height);

            // VBox properties
            this.wrapper = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            this.wrapper.draw.connect (this.draw_icon);
            this.add (this.wrapper);

            // Focused signals
            this.draw.connect (this.draw_background);
            this.focus_in_event.connect ( () => { this.focus_in (); return true; } );
            this.focus_out_event.connect ( () => { this.focus_out (); return true; } );
        }

        public void change_app (Gdk.Pixbuf new_icon, string new_name, string new_tooltip) {
            this.current_frame = 1;

            // Icon
            this.icon = new_icon;
            this.prominent = LightPad.Frontend.Utilities.average_color (this.icon);

            // Label
            this.label = new_name;

            // Tooltip
            this.set_tooltip_text (new_tooltip);

            // Redraw
            this.wrapper.queue_draw ();
        }

        public new void focus_in () {
            GLib.Timeout.add (((int)(1000 / FPS)), () => {
                if (this.current_frame >= RUN_LENGTH || !this.has_focus) {
                    current_frame = 1;
                    return false; // Stop animation
                }

                queue_draw ();
                this.current_frame++;
                return true;
            });
        }

        public new void focus_out () {
            GLib.Timeout.add (((int)(1000 / FPS)), () => {
                if (this.current_frame >= RUN_LENGTH || this.has_focus) {
                    current_frame = 1;
                    return false; // Stop animation
                }

                queue_draw ();
                this.current_frame++;
                return true;
            });
        }

        private bool draw_icon (Gtk.Widget widget, Cairo.Context ctx) {
            Gtk.Allocation size;
            widget.get_allocation (out size);
            var context = ctx;

            /* 
             * The context is already set so that (0,0) is the top left corner of the widget.
             * Calculate the horizontal center for the icon.
             * The Y position of the icon is 0 (above the widget).
             */
            double icon_x = (size.width - this.icon.width) / 2.0;
            double icon_y = 0.0;

            // Draw the icon
            // The coordinates are relative to the widget origin (0,0).
            Gdk.cairo_set_source_pixbuf (context, this.icon, icon_x, icon_y);
            context.paint ();

            Cairo.TextExtents extents;
            context.select_font_face ("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
            context.set_font_size (this.font_size);
            LightPad.Frontend.Utilities.truncate_text (context, size, 10, this.label, out this.label, out extents);

            /*
             * Calculate the coordinates for the text.
             * Here, (size.width / 2 - extents.width / 2) is already the horizontal center relative to the widget.
             * For the Y position, if we want it to be 10px from the bottom edge, it would be size.height - 10.
             */
            double text_x_center = size.width / 2 - extents.width / 2;
            double text_y_base = size.height - 10; // 10px desde el borde inferior

            // Draw the shadow of the text
            // Add 1 to X and Y for a slight shadow offset.
            context.move_to (text_x_center + 1, text_y_base + 1);
            context.set_source_rgba (0.0, 0.0, 0.0, 0.8);
            context.show_text (this.label);

            // Draw normal text
            context.set_source_rgba (1.0, 1.0, 1.0, 1.0);
            context.move_to (text_x_center, text_y_base);
            context.show_text (this.label);

            return false;
        }

        private bool draw_background (Gtk.Widget widget, Cairo.Context ctx) {
            Gtk.Allocation size;
            widget.get_allocation (out size);
            var context = ctx;

            double progress;
            if (this.current_frame > 1) {
                progress = (double)RUN_LENGTH / (double)this.current_frame;
            } else {
                progress = 1;
            }

            if (this.has_focus) {
                double dark = 0.32;
                var gradient = new Cairo.Pattern.rgba (
                    this.prominent.r * dark, this.prominent.g * dark, this.prominent.b * dark, 0.8
                );
                context.set_source (gradient);
                LightPad.Frontend.Utilities.draw_rounded_rectangle (context, 10, 0.5, size);
                context.fill ();
            } else {
                if (this.current_frame > 1) {
                    var gradient = new Cairo.Pattern.rgba (0.0, 0.0, 0.0, 0.0);

                    context.set_source (gradient);
                    LightPad.Frontend.Utilities.draw_rounded_rectangle (context, 10, 0.5, size);
                    context.fill ();
                }
            }

            return false;
        }

    }

}