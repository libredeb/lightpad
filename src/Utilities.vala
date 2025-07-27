/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020 Juan Pablo Lozano <libredeb@gmail.com>
 */

using GLib;
using Gtk;
using Cairo;

namespace LightPad.Frontend {

    class Utilities : GLib.Object {

        public static void draw_rounded_rectangle (
            Cairo.Context context, double radius, double offset, Gtk.Allocation size
        ) {
            // The coordinates are now relative to the top-left corner of the widget.
            // Defines the drawing limits adjusted by the offset
            double x_start = offset;
            double y_start = offset;
            double width = size.width - (2 * offset);
            double height = size.height - (2 * offset);

            double max_possible_radius_h = width / 2.0;
            double max_possible_radius_v = height / 2.0;
            double max_possible_radius =
                (max_possible_radius_h < max_possible_radius_v) ?
                max_possible_radius_h : max_possible_radius_v;

            // Make sure the radius is no greater than half the width or height
            // to avoid irregular shapes
            radius = (radius < max_possible_radius) ? radius : max_possible_radius;

            // Move to the starting point for the first arc
            context.move_to (x_start + radius, y_start);

            // Upper right edge
            context.arc (
                x_start + width - radius,
                y_start + radius,
                radius, Math.PI * 1.5, Math.PI * 2
            );

            // Lower right corner
            context.arc (
                x_start + width - radius,
                y_start + height - radius,
                radius, 0, Math.PI * 0.5
            );

            // Lower left arc
            context.arc (
                x_start + radius,
                y_start + height - radius,
                radius, Math.PI * 0.5, Math.PI
            );

            // Upper left curve
            context.arc (
                x_start + radius,
                y_start + radius,
                radius, Math.PI, Math.PI * 1.5
            );

            // Close the path to form the complete rounded rectangle.
            context.close_path ();
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
