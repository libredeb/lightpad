/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020 Juan Pablo Lozano <libredeb@gmail.com>
 */

namespace Widgets {

    public class CompositedWindow : Gtk.Window {

        construct {
            // Window properties
            this.set_skip_taskbar_hint (true); // Not display the window in the task bar
            this.set_decorated (false); // No window decoration
            this.set_app_paintable (true); // Suppress default themed drawing of the widget's background
            this.set_name ("mainwindow");
            this.set_visual (this.get_screen ().get_rgba_visual ());

            // Events
            this.draw.connect (clear_background);
        }

        public bool clear_background (Gtk.Widget widget, Cairo.Context ctx) {
            ctx.set_operator (Cairo.Operator.CLEAR);
            ctx.paint ();

            return false;
        }

    }

}
