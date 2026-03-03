#include <gtk/gtk.h>
#include <gtk-layer-shell/gtk-layer-shell.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Configuration
#define ICON_PERF "󰓅"
#define ICON_BATT "󰁹"
#define LOW_REFRESH 60

typedef struct {
    char name[64];
    int width;
    int height;
    int current_refresh;
    int max_refresh;
} MonitorInfo;

// Simple parser to find focused monitor details from hyprctl -j
MonitorInfo get_focused_monitor() {
    MonitorInfo mon = {"", 0, 0, 0, 0};
    FILE *fp = popen("hyprctl monitors -j", "r");
    if (!fp) return mon;

    char buffer[16384]; // Increased for large multi-monitor setups
    size_t len = fread(buffer, 1, sizeof(buffer) - 1, fp);
    buffer[len] = '\0';
    pclose(fp);

    // This is a "quick and dirty" JSON scraper
    char *focused_ptr = strstr(buffer, "\"focused\": true");
    if (!focused_ptr) focused_ptr = buffer; // Fallback to first if none focused

    // Find name
    char *name_start = strstr(focused_ptr - 1000 > buffer ? focused_ptr - 1000 : buffer, "\"name\": \"");
    if (name_start) {
        sscanf(name_start, "\"name\": \"%[^\"]\"", mon.name);
    }

    // Find current refresh
    char *refresh_ptr = strstr(focused_ptr - 500, "\"refreshRate\": ");
    if (refresh_ptr) {
        // Find the colon and scan after it
        char *colon = strchr(refresh_ptr, ':');
        if (colon) sscanf(colon + 1, "%d", &mon.current_refresh);
    }

    // Find width/height
    char *width_ptr = strstr(focused_ptr - 500, "\"width\": ");
    if (width_ptr) {
        char *colon = strchr(width_ptr, ':');
        if (colon) sscanf(colon + 1, "%d", &mon.width);
    }
    char *height_ptr = strstr(focused_ptr - 500, "\"height\": ");
    if (height_ptr) {
        char *colon = strchr(height_ptr, ':');
        if (colon) sscanf(colon + 1, "%d", &mon.height);
    }

    // Find max available refresh
    char *modes_ptr = strstr(focused_ptr - 500, "\"availableModes\": [");
    if (modes_ptr) {
        int r;
        char *search = modes_ptr;
        // Search until the end of the array
        char *end_of_modes = strchr(modes_ptr, ']');
        while ((search = strstr(search, "@")) != NULL && (end_of_modes == NULL || search < end_of_modes)) {
            if (sscanf(search, "@%d", &r) == 1) {
                if (r > mon.max_refresh) mon.max_refresh = r;
            }
            search++;
        }
    }

    return mon;
}

static gboolean on_timeout(gpointer data) {
    gtk_main_quit();
    return FALSE;
}

int main(int argc, char *argv[]) {
    MonitorInfo mon = get_focused_monitor();
    
    if (strlen(mon.name) == 0) {
        fprintf(stderr, "Error: Could not detect monitor.\n");
        return 1;
    }

    int target_refresh;
    const char *icon;
    const char *msg;

    // Logic: If current is high (e.g. 165), drop to 60. Else go to max.
    if (mon.current_refresh > LOW_REFRESH) {
        target_refresh = LOW_REFRESH;
        icon = ICON_BATT;
        msg = "Battery Saving Mode";
    } else {
        target_refresh = (mon.max_refresh > 0) ? mon.max_refresh : 165;
        icon = ICON_PERF;
        msg = "Performance Mode";
    }

    // Execute the toggle via hyprctl
    char cmd[512];
    // Note: Using hardcoded scale 2 as requested in original script
    snprintf(cmd, sizeof(cmd), "hyprctl keyword monitor \"%s,%dx%d@%d,0x0,2\"", 
             mon.name, mon.width, mon.height, target_refresh);
    system(cmd);

    // GTK UI
    gtk_init(&argc, &argv);
    GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_layer_init_for_window(GTK_WINDOW(window));
    gtk_layer_set_layer(GTK_WINDOW(window), GTK_LAYER_SHELL_LAYER_OVERLAY);
    gtk_layer_set_namespace(GTK_WINDOW(window), "power-mod");
    gtk_layer_set_keyboard_interactivity(GTK_WINDOW(window), FALSE);
    
    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 10);
    gtk_container_set_border_width(GTK_CONTAINER(box), 30);
    gtk_container_add(GTK_CONTAINER(window), box);

    GtkWidget *icon_label = gtk_label_new(NULL);
    char icon_markup[512];
    snprintf(icon_markup, sizeof(icon_markup), "<span font='48'>%s</span>", icon);
    gtk_label_set_markup(GTK_LABEL(icon_label), icon_markup);
    gtk_container_add(GTK_CONTAINER(box), icon_label);

    GtkWidget *msg_label = gtk_label_new(NULL);
    char msg_markup[512];
    snprintf(msg_markup, sizeof(msg_markup), "<span font='18' weight='bold'>%s</span>", msg);
    gtk_label_set_markup(GTK_LABEL(msg_label), msg_markup);
    gtk_container_add(GTK_CONTAINER(box), msg_label);
    
    GtkCssProvider *provider = gtk_css_provider_new();
    gtk_css_provider_load_from_data(provider,
        "window { background-color: rgba(24, 24, 37, 0.9); border-radius: 24px; border: 2px solid #cba6f7; } "
        "label { color: #cdd6f2; margin: 10px; }", -1, NULL);
    gtk_style_context_add_provider_for_screen(gdk_screen_get_default(), GTK_STYLE_PROVIDER(provider), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    g_object_unref(provider);

    gtk_widget_show_all(window);
    g_timeout_add(1500, on_timeout, NULL);
    gtk_main();

    return 0;
}
