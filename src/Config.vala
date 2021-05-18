class Config {
    // Grid
    public int grid_y;
    public int grid_x;
    public int grid_cell_spacing_w;
    public int grid_cell_spacing_h;
    // AppItem
    public double item_font_size;
    public int item_icon_size;
    public int item_box_width;
    public int item_box_height;
    // SearchBar
    public int sb_width;
    public int sb_height;

    private int screen_w;
    private int screen_h;
    private KeyFile config_f;

    public Config(int screen_width, int screen_height) {
        screen_w = screen_width;
        screen_w = screen_height;
        config_f = new KeyFile();
        // This could throw if file not found => app would crash
        config_f.load_from_file(Resources.CONFIG_FILE, KeyFileFlags.KEEP_COMMENTS);
        
        const string[] group = {"Grid", "AppItem", "SearchBar"};
        
        grid_y              = config_f.get_integer(group[0], "Y");
        grid_x              = config_f.get_integer(group[0], "X");
        grid_cell_spacing_w = config_f.get_integer(group[0], "CellSpacingWidth");
        grid_cell_spacing_h = config_f.get_integer(group[0], "CellSpacingHeight");

        item_font_size      = config_f.get_double(group[1], "FontSize");
        item_icon_size      = config_f.get_integer(group[1], "IconSize");
        item_box_width      = config_f.get_integer(group[1], "BoxWidth");
        item_box_height     = config_f.get_integer(group[1], "BoxHeight");

        sb_width            = config_f.get_integer(group[2], "Width");
        sb_height           = config_f.get_integer(group[2], "Height");
        
    }

    private void set_config_values() {
        if (item_icon_size != -1) {
            set_based_on_icon_size();
        }
    }

    private void set_based_on_icon_size() {
        if (item_box_width == -1 && item_box_height == -1) {

        }
    }

    private void set_default_icon_size() {
        double scale_factor = (1.0/3.0);
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

    private void set_default_grid_size() {
        int x, y;
        // For Monitor 5:4 and 4:3
        if ((screen_w / (double) screen_h) < 1.4) {
            x = 5;
            y = 5;
        } else if (screen_h == 600) { // Netbook 1024x600px
            y = 6;
            x = 4;
        } else if (screen_h == 720) { // HD 1280x720px
            y = 7;
            x = 5;
        } else if (screen_h == 1080) { // Full HD 1920x1080px
            y = 9;
            x = 7;
        } else { // Monitor 16:9
            y = 6;
            x = 5;
        }

        if (grid_x == -1)
            grid_x = x;
        if (grid_y == -1)
            grid_y = y;
    }

    private void set_default_box_size() {
        if (item_icon_size == -1)
            set_default_icon_size();
        if (item_box_width == -1)
            item_box_width = item_icon_size * 3;
        if (item_box_height == -1)
            item_box_height = item_icon_size + 30;
    }

    private void set_default_font_size() {
        item_font_size = 11.5;
    }
}