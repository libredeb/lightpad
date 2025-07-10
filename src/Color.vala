/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020 Juan Pablo Lozano <libredeb@gmail.com>
 */

 using Gdk;

 namespace LightPad.Frontend {
 
     public struct Color {
         public double r;
         public double g;
         public double b;
         public double a;
 
         public Color (double r, double g, double b, double a) {
             this.r = r;
             this.g = g;
             this.b = b;
             this.a = a;
         }
 
         public Color set_val (double val) requires (val >= 0 && val <= 1) {
             double h, s, v;
             rgb_to_hsv (this.r, this.g, this.b, out h, out s, out v);
             v = val;
             hsv_to_rgb (h, s, v, out this.r, out this.g, out this.b);
 
             return this;
         }
 
         public Color multiply_sat (double amount) requires (amount >= 0) {
             double h, s, v;
             rgb_to_hsv (this.r, this.g, this.b, out h, out s, out v);
             s = Math.fmin (1, s * amount);
             hsv_to_rgb (h, s, v, out this.r, out this.g, out this.b);
 
             return this;
         }
 
         void rgb_to_hsv (
             double r, double g, double b, out double h, out double s, out double v
         )
             requires (r >= 0 && r <= 1)
             requires (g >= 0 && g <= 1)
             requires (b >= 0 && b <= 1) {
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
 
         void hsv_to_rgb (
             double h, double s, double v, out double r, out double g, out double b
         )
             requires (h >= 0 && h <= 360)
             requires (s >= 0 && s <= 1)
             requires (v >= 0 && v <= 1) {
             r = 0;
             g = 0;
             b = 0;
 
             if (s == 0) {
                 r = v;
                 g = v;
                 b = v;
             } else {
                 int sec_num;
                 double frac_sec;
                 double p, q, t;
 
                 sec_num = (int) Math.floor (h / 60);
                 frac_sec = h / 60 - sec_num;
 
                 p = v * (1 - s);
                 q = v * (1 - s * frac_sec);
                 t = v * (1 - s * (1 - frac_sec));
 
                 switch (sec_num) {
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
                 }
             }
         }
     }
 }