/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020 Juan Pablo Lozano <libredeb@gmail.com>
 */

namespace LightPad.Frontend {

    public class Indicators : Gtk.HBox {

        // Animation constants
        const int FPS = 25;
        private int animation_duration;
        private int animation_frames; // total number of frames
        private int current_frame = 1;
        private uint animation_loop_id = 0;
        private bool animation_active = false;

        // Signals
        public signal void child_activated ();

        // Properties
        public new GLib.List<Gtk.Widget> children;
        public int active = -1;
        private int old_active = -1;
        private int skip_flag = 0;

        public Indicators () {
            this.homogeneous = false;
            this.spacing = 0;
        }

        public void append (string thelabel) {
            var indicator = new Gtk.EventBox ();
            indicator.set_visible_window (false);

            var label = new Gtk.Label (thelabel);
            label.get_style_context ().add_class ("indicator_label");

            // make sure the child widget is added with padding
            label.set_halign (Gtk.Align.CENTER);
            label.set_valign (Gtk.Align.CENTER);
            label.set_margin_top (0);
            label.set_margin_bottom (0);
            label.set_margin_start (15);
            label.set_margin_end (15);
            indicator.add (label);
            this.children.append (indicator);

            this.draw.connect (draw_background);
            indicator.button_release_event.connect ( () => {
                this.set_active (this.children.index (indicator));
                return true;
            });

            this.pack_start (indicator, false, false, 0);
        }

        public void set_active_no_signal (int index) {
            int pages_length = (int) this.children.length ();
            // make sure the requested active item is in the children list
            if (index <= (pages_length - 1)) {
                this.old_active = this.active;
                this.active = index;
                this.change_focus ();
            }

        }

        public void set_active (int index) {
            skip_flag++;
            this.set_active_no_signal (index);
            if (skip_flag > 1) { // avoid activating a page "0" that does not exist
                this.child_activated (); // send signal
            }
        }

        public void change_focus () {
            //make sure no other animation is running, if so kill it with fire
            if (animation_active) {
                GLib.Source.remove (animation_loop_id);
                end_animation ();
            }

            /* definie animation_duration, base is 250 millisecionds for which
               50 ms is added for each item to span */
            this.animation_duration = 240;
            int difference = (this.old_active - this.active).abs ();
            this.animation_duration += (int) (Math.pow (difference, 0.5) * 80);
            this.animation_frames = (int)((double) animation_duration / 1000 * FPS);

            // initial conditions for animation.
            this.current_frame = 0;
            this.animation_active = true;

            this.animation_loop_id = GLib.Timeout.add (((int)(1000 / FPS)), () => {
                if (this.current_frame >= this.animation_frames) {
                    end_animation ();
                    return false; // stop animation
                }

                this.current_frame++;
                this.queue_draw ();
                return true;
            });
        }

        private void end_animation () {
            animation_active = false;
            current_frame = 0;
        }

        protected bool draw_background (Gtk.Widget widget, Cairo.Context ctx) {
            Gtk.Allocation size; // Allocation of the pager widget itself (parent)
            widget.get_allocation (out size);
            var context = ctx;

            double d = (double) this.animation_frames;
            double t = (double) this.current_frame;

            // easeOutQuint algorithm - aka - start normal end slow
            double progress = ((t = t / d - 1) * t * t * t * t + 1);

            Gtk.Allocation size_old, size_new;

            // Ensure indices are valid to prevent crashes
            if (this.old_active < 0 || this.old_active >= this.get_children ().length () ||
                this.active < 0 || this.active >= this.get_children ().length ()) {
                // Fallback or just return if indices are out of bounds
                // Consider drawing a default state here or logging an error.
                return false;
            }

            // Get allocations of the old and new active child widgets (page indicators)
            // These allocations are relative to the parent of the pager widget.
            this.get_children ().nth_data (this.old_active).get_allocation (out size_old);
            this.get_children ().nth_data (this.active).get_allocation (out size_new);

            // Calculate child positions relative to the pager widget's own origin (0,0) for the Cairo context.
            // This removes the "global" offset from size_old.x/y and size_new.x/y.
            double x_old_relative = size_old.x - size.x;
            double y_old_relative = size_old.y - size.y;

            double x_new_relative = size_new.x - size.x;
            double y_new_relative = size_new.y - size.y;

            // Calculate the animated position and size of the indicator,
            // relative to the pager widget's drawing context.
            double x_animated_relative = x_old_relative + (x_new_relative - x_old_relative) * progress;
            double y_animated_relative = y_old_relative + (y_new_relative - y_old_relative); // Assuming Y doesn't animate or y_old_relative == y_new_relative
            double width_animated = size_old.width + (size_new.width - (double) size_old.width) * progress;
            double height_animated = size_old.height + (size_new.height - (double) size_old.height);

            double radius = 6.0;

            // Set the drawing color to white (fully opaque)
            context.set_source_rgba (1.0, 1.0, 1.0, 1.0);

            // Draw the animated circle (filled)
            // The center of the circle is calculated based on the animated allocation.
            context.arc (
                x_animated_relative + width_animated / 2.0,
                y_animated_relative + height_animated / 2.0,
                radius, 0, Math.PI * 2
            );
            context.fill ();

            return false;
        }
    }
}
