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
    public int sb_width;
    public int sb_height;

    public int screen_w;
    public int screen_h;

    public BaseConfig(int screen_width, int screen_height, bool init_default = true) {
        screen_w = screen_width;
        screen_h = screen_height;
        if (init_default) {
            default_icon_size();
            default_grid_size();

            item_font_size = 11.5;

            item_box_width = item_icon_size * 3;
            item_box_height = item_icon_size + 30;

            grid_row_spacing = 30;
            grid_col_spacing = 0;
        }
    }

    private void default_icon_size() {
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

    private void default_grid_size() {
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

void merge_int(int* ptr, int val) {
    if (val > -1)
        *ptr = val;
}

void merge_double(double* ptr, double val) {
    if (val > -1.0)
        *ptr = val;
}

class FileConfig : BaseConfig {
    private KeyFile config_f;

    public FileConfig(int screen_width, int screen_height, string file) {
        base(screen_width, screen_height);

        config_f = new KeyFile();
        try {
            config_f.load_from_file(file, KeyFileFlags.KEEP_COMMENTS);
        } catch {
            message ("Config file not found. Using default values");
            return;
        }
        
        const string[] group = {"Grid", "AppItem", "SearchBar"};
        try {
            merge_int(&grid_y, config_f.get_integer(group[0], "Y"));
            merge_int(&grid_x, config_f.get_integer(group[0], "X"));
            merge_int(&grid_row_spacing, config_f.get_integer(group[0], "RowSpacing"));
            merge_int(&grid_col_spacing, config_f.get_integer(group[0], "ColumnSpacing"));

            merge_double(&item_font_size, config_f.get_double(group[1], "FontSize"));
            merge_int(&item_icon_size, config_f.get_integer(group[1], "IconSize"));
            merge_int(&item_box_width, config_f.get_integer(group[1], "BoxWidth"));
            merge_int(&item_box_height, config_f.get_integer(group[1], "BoxHeight"));

            merge_int(&sb_width, config_f.get_integer(group[2], "Width"));
            merge_int(&sb_height, config_f.get_integer(group[2], "Height"));
        }
        catch {
            message ("Key config missing");
        }
    }
}

        //  grid_y              = config_f.get_integer(group[0], "Y");
        //  grid_x              = config_f.get_integer(group[0], "X");
        //  grid_row_spacing = config_f.get_integer(group[0], "RowSpacing");
        //  grid_col_spacing = config_f.get_integer(group[0], "ColumnSpacing");
        //  item_font_size      = config_f.get_double(group[1], "FontSize");
        //  item_icon_size      = config_f.get_integer(group[1], "IconSize");
        //  item_box_width      = config_f.get_integer(group[1], "BoxWidth");
        //  item_box_height     = config_f.get_integer(group[1], "BoxHeight");
        //  sb_width            = config_f.get_integer(group[2], "Width");
        //  sb_height           = config_f.get_integer(group[2], "Height");