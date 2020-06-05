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

using Gdk;

namespace LightPad.Frontend {

    public struct Color {
        public double R;
        public double G;
        public double B;
        public double A;

        public Color (double R, double G, double B, double A) {
            this.R = R;
            this.G = G;
            this.B = B;
            this.A = A;
        }
        
        public Color set_val (double val) requires (val >= 0 && val <= 1) {
            double h, s, v;
            rgb_to_hsv (R, G, B, out h, out s, out v);
            v = val;
            hsv_to_rgb (h, s, v, out R, out G, out B);

            return this;
        }

        public Color multiply_sat (double amount) requires (amount >= 0) {
            double h, s, v;
            rgb_to_hsv (R, G, B, out h, out s, out v);
            s = Math.fmin (1, s * amount);
            hsv_to_rgb (h, s, v, out R, out G, out B);

            return this;
        }

        void rgb_to_hsv (double r, double g, double b, out double h, out double s, out double v)
            requires (r >= 0 && r <= 1)
            requires (g >= 0 && g <= 1)
            requires (b >= 0 && b <= 1)
        {
            double min = Math.fmin (r, Math.fmin (g, b));
            double max = Math.fmax (r, Math.fmax (g, b));

            v = max;
            if (v == 0) {
                h = 0;
                s = 0;
                return;
            }

            // Normalize value to 1
            r /= v;
            g /= v;
            b /= v;
            
            min = Math.fmin (r, Math.fmin (g, b));
            max = Math.fmax (r, Math.fmax (g, b));

            double delta = max - min;
            s = delta;
            if (s == 0) {
                h = 0;
                return;
            }

            // Normalize saturation to 1
            r = (r - min) / delta;
            g = (g - min) / delta;
            b = (b - min) / delta;

            if (max == r) {
                h = 0 + 60 * (g - b);
                if (h < 0) {
                    h += 360;
                }
            } else if (max == g) {
                h = 120 + 60 * (b - r);
            } else {
                h = 240 + 60 * (r - g);
            }
        }

        void hsv_to_rgb (double h, double s, double v, out double r, out double g, out double b)
            requires (h >= 0 && h <= 360)
            requires (s >= 0 && s <= 1)
            requires (v >= 0 && v <= 1)
        {
            r = 0;
            g = 0;
            b = 0;

            if (s == 0) {
                r = v;
                g = v;
                b = v;
            } else {
                int secNum;
                double fracSec;
                double p, q, t;

                secNum = (int) Math.floor (h / 60);
                fracSec = h / 60 - secNum;

                p = v * (1 - s);
                q = v * (1 - s * fracSec);
                t = v * (1 - s * (1 - fracSec));

                switch (secNum) {
                    case 0:
                        r = v;
                        g = t;
                        b = p;
                        break;
                    case 1:
                        r = q;
                        g = v;
                        b = p;
                        break;
                    case 2:
                        r = p;
                        g = v;
                        b = t;
                        break;
                    case 3:
                        r = p;
                        g = q;
                        b = v;
                        break;
                    case 4:
                        r = t;
                        g = p;
                        b = v;
                        break;
                    case 5:
                        r = v;
                        g = p;
                        b = q;
                        break;
                } // End Switch
            } // End If
        }
        
    }

}
