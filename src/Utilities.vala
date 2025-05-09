/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020 Juan Pablo Lozano <libredeb@gmail.com>
 */

using GLib;
using Gtk;
using Cairo;

namespace LightPad.Frontend {

    class Utilities : GLib.Object {

        public static void draw_rounded_rectangle (Cairo.Context context, double radius,
                                                  double offset, Gtk.Allocation size) {
            context.move_to (size.x + radius, size.y + offset);
            context.arc (
                size.x + size.width - radius - offset,
                size.y + radius + offset,
                radius, Math.PI * 1.5, Math.PI * 2
            );
            context.arc (
                size.x + size.width - radius - offset,
                size.y + size.height - radius - offset,
                radius, 0, Math.PI * 0.5
            );
            context.arc (
                size.x + radius + offset,
                size.y + size.height - radius - offset,
                radius, Math.PI * 0.5, Math.PI
            );
            context.arc (
                size.x + radius + offset,
                size.y + radius + offset,
                radius, Math.PI, Math.PI * 1.5
            );
        }

        public static LightPad.Frontend.Color average_color (Gdk.Pixbuf source) {
            double r_total = 0;
            double g_total = 0;
            double b_total = 0;

            uchar* data_ptr = source.get_pixels ();
            double pixels = source.height * source.rowstride / source.n_channels;

            for (int i = 0; i < pixels; i++) {
                uchar r = data_ptr [0];
                uchar g = data_ptr [1];
                uchar b = data_ptr [2];

                uchar max = (uchar) Math.fmax (r, Math.fmax (g, b));
                uchar min = (uchar) Math.fmin (r, Math.fmin (g, b));
                double delta = max - min;

                double sat = delta == 0 ? 0 : delta / max;
                double score = 0.2 + 0.8 * sat;

                r_total += r * score;
                g_total += g * score;
                b_total += b * score;

                data_ptr += source.n_channels;
            }

            return LightPad.Frontend.Color (r_total / uint8.MAX / pixels,
                        g_total / uint8.MAX / pixels,
                        b_total / uint8.MAX / pixels,
                        1).set_val (0.8).multiply_sat (1.15);
        }

        public static void truncate_text (
            Cairo.Context context, Gtk.Allocation size, uint padding, string input,
            out string truncated, out Cairo.TextExtents truncated_extents
        ) {
            Cairo.TextExtents extents;
            truncated = input;
            context.text_extents (input, out extents);

            if (extents.width > (size.width - padding)) {
                while (extents.width > (size.width - padding)) {
                    truncated = truncated.slice (0, (int)truncated.length - 1);
                    context.text_extents (truncated, out extents);
                }

                truncated = truncated.slice (0, (int)truncated.length - 3); // make room for ...
                truncated += ". . . ";
            }

            context.text_extents (truncated, out truncated_extents);
        }

    }

}
