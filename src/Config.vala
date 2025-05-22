/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020 Juan Pablo Lozano <libredeb@gmail.com>
 */

class BaseConfig {

    // Grid
    public int grid_y;
    public int grid_x;
    public int grid_row_spacing;
    public int grid_col_spacing;

    // AppItem
    public double item_font_size;
    public int item_icon_size;
    public int item_box_width;
    public int item_box_height;

    // SearchBar
    public int sb_width = -1;
    public int sb_height = -1;

    public int screen_w;
    public int screen_h;

    public BaseConfig (int screen_width, int screen_height, bool init_default = true) {
        screen_w = screen_width;
        screen_h = screen_height;
        if (init_default) {
            default_icon_size ();
            default_grid_size ();

            item_font_size = 11.5;

            item_box_width = item_icon_size * 3;
            item_box_height = item_icon_size + 30;

            grid_row_spacing = 30;
            grid_col_spacing = 0;
        }
    }

    private void default_icon_size () {
        double scale_factor = (1.0 / 3.0);
        double suggested_size = Math.pow (screen_w * screen_w, scale_factor);
        suggested_size = suggested_size / 1.7;
        if (suggested_size < 27) {
            this.item_icon_size = 24;
        } else if (suggested_size >= 27 && suggested_size < 40) {
            this.item_icon_size = 32;
        } else if ((suggested_size >= 40 && suggested_size < 56) || (screen_h == 720)) {
            this.item_icon_size = 48;
        } else if (suggested_size >= 56) {
            this.item_icon_size = 64;
        }
    }

    private void default_grid_size () {
        // For Monitor 5:4 and 4:3
        if ((screen_w / (double) screen_h) < 1.4) {
            grid_x = 5;
            grid_y = 5;
        } else if (screen_h == 600) { // Netbook 1024x600px
            grid_y = 6;
            grid_x = 4;
        } else if (screen_h == 720) { // HD 1280x720px
            grid_y = 7;
            grid_x = 5;
        } else if (screen_h == 1080) { // Full HD 1920x1080px
            grid_y = 9;
            grid_x = 7;
        } else { // Monitor 16:9
            grid_y = 6;
            grid_x = 5;
        }
    }
}

class FileConfig : BaseConfig {

    private GLib.KeyFile config_f;
    private ConfigField[] config_fields;
    private const string[] GROUPS = {"Grid", "AppItem", "SearchBar"};

    public FileConfig (int screen_width, int screen_height, string file) {
        base (screen_width, screen_height);

        config_fields = {
            { GROUPS[0], "Y", ConfigType.INT, &grid_y },
            { GROUPS[0], "X", ConfigType.INT, &grid_x },
            { GROUPS[0], "RowSpacing", ConfigType.INT, &grid_row_spacing },
            { GROUPS[0], "ColumnSpacing", ConfigType.INT, &grid_col_spacing },

            { GROUPS[1], "FontSize", ConfigType.DOUBLE, &item_font_size },
            { GROUPS[1], "IconSize", ConfigType.INT, &item_icon_size },
            { GROUPS[1], "BoxWidth", ConfigType.INT, &item_box_width },
            { GROUPS[1], "BoxHeight", ConfigType.INT, &item_box_height },

            { GROUPS[2], "Width", ConfigType.INT, &sb_width },
            { GROUPS[2], "Height", ConfigType.INT, &sb_height },
        };

        config_f = new GLib.KeyFile ();
        try {
            config_f.load_from_file (file, KeyFileFlags.KEEP_COMMENTS);
            load_config_fields ();
        } catch {
            debug ("Config file not found. Using default values");
        }
    }

    private void load_config_fields () {
        foreach (var field in config_fields) {
            try {
                switch (field.type) {
                    case ConfigType.INT:
                        int val_i = config_f.get_integer (field.group, field.key);
                        if (val_i > -1)
                            * ((int*) field.pointer) = val_i;
                        break;
                    case ConfigType.DOUBLE:
                        double val_d = config_f.get_double (field.group, field.key);
                        if (val_d > -1.0)
                            * ((double*) field.pointer) = val_d;
                        break;
                }
            } catch (GLib.Error e) {
                message ("Missing config key: [%s] %s".printf (field.group, field.key));
            }
        }
    }

    public GLib.KeyFile get_key_file () {
        var keyfile = new GLib.KeyFile ();
        foreach (var field in config_fields) {
            switch (field.type) {
                case ConfigType.INT:
                    keyfile.set_integer (field.group, field.key, * ((int*) field.pointer));
                    break;
                case ConfigType.DOUBLE:
                    keyfile.set_double (field.group, field.key, * ((double*) field.pointer));
                    break;
            }
        }
        return keyfile;
    }
}
