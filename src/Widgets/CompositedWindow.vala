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
            ctx.paint();

            return false;
        }
        
    }

}
