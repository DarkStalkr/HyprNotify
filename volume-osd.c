#include <gtk/gtk.h>
#include <gtk-layer-shell/gtk-layer-shell.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>

#define FIFO_PATH "/tmp/volume_bar.fifo"
#define ICON_MUTE "󰝟"
#define ICON_LOW  "󰕿"
#define ICON_MID  "󰖀"
#define ICON_HIGH "󰕾"

typedef struct {
    GtkWidget *window;
    GtkWidget *progress;
    GtkWidget *icon_label;
    guint timeout_id;
} OSDData;

static gboolean hide_osd(gpointer data) {
    OSDData *osd = (OSDData *)data;
    gtk_widget_hide(osd->window);
    osd->timeout_id = 0;
    return FALSE;
}

static void update_osd(OSDData *osd, int volume) {
    // Detect mute status
    gboolean is_muted = FALSE;
    FILE *fp = popen("pamixer --get-mute", "r");
    if (fp) {
        char buffer[16];
        if (fgets(buffer, sizeof(buffer), fp)) {
            if (strstr(buffer, "true")) is_muted = TRUE;
        }
        pclose(fp);
    }

    const char *icon;
    if (is_muted) icon = ICON_MUTE;
    else if (volume < 33) icon = ICON_LOW;
    else if (volume < 66) icon = ICON_MID;
    else icon = ICON_HIGH;

    // Update UI
    char icon_markup[128];
    snprintf(icon_markup, sizeof(icon_markup), "<span font='28' color='%s'>%s</span>", 
             is_muted ? "#f38ba8" : "#cba6f7", icon);
    gtk_label_set_markup(GTK_LABEL(osd->icon_label), icon_markup);
    gtk_progress_bar_set_fraction(GTK_PROGRESS_BAR(osd->progress), (double)volume / 100.0);

    // Reset Timer & Show
    if (osd->timeout_id > 0) g_source_remove(osd->timeout_id);
    osd->timeout_id = g_timeout_add(1500, hide_osd, osd);
    gtk_widget_show_all(osd->window);
}

static gboolean on_fifo_data(GIOChannel *source, GIOCondition condition, gpointer data) {
    OSDData *osd = (OSDData *)data;
    gchar *str = NULL;
    gsize len;
    GError *err = NULL;

    if (g_io_channel_read_line(source, &str, &len, NULL, &err) == G_IO_STATUS_NORMAL) {
        int volume = atoi(str);
        update_osd(osd, volume);
        g_free(str);
    }
    return TRUE;
}

int main(int argc, char *argv[]) {
    gtk_init(&argc, &argv);

    // Create FIFO if not exists
    mkfifo(FIFO_PATH, 0666);
    int fd = open(FIFO_PATH, O_RDONLY | O_NONBLOCK);
    GIOChannel *channel = g_io_channel_unix_new(fd);
    
    OSDData *osd = g_new0(OSDData, 1);
    osd->window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    
    gtk_layer_init_for_window(GTK_WINDOW(osd->window));
    gtk_layer_set_layer(GTK_WINDOW(osd->window), GTK_LAYER_SHELL_LAYER_OVERLAY);
    gtk_layer_set_namespace(GTK_WINDOW(osd->window), "volume-osd");
    gtk_layer_set_anchor(GTK_WINDOW(osd->window), GTK_LAYER_SHELL_EDGE_BOTTOM, TRUE);
    gtk_layer_set_margin(GTK_WINDOW(osd->window), GTK_LAYER_SHELL_EDGE_BOTTOM, 80);
    gtk_layer_set_keyboard_interactivity(GTK_WINDOW(osd->window), FALSE);

    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 20);
    gtk_container_set_border_width(GTK_CONTAINER(box), 25);
    gtk_container_add(GTK_CONTAINER(osd->window), box);

    osd->icon_label = gtk_label_new(NULL);
    gtk_widget_set_valign(osd->icon_label, GTK_ALIGN_CENTER);
    gtk_box_pack_start(GTK_BOX(box), osd->icon_label, FALSE, FALSE, 0);

    osd->progress = gtk_progress_bar_new();
    gtk_widget_set_valign(osd->progress, GTK_ALIGN_CENTER);
    gtk_widget_set_size_request(osd->progress, 250, 24);
    gtk_box_pack_start(GTK_BOX(box), osd->progress, TRUE, TRUE, 0);

    GtkCssProvider *provider = gtk_css_provider_new();
    gtk_css_provider_load_from_data(provider,
        "window { background-color: rgba(24, 24, 37, 0.95); border-radius: 20px; border: 2px solid #cba6f7; box-shadow: 0 4px 15px rgba(0,0,0,0.5); } "
        "progressbar trough { background-image: repeating-linear-gradient(to right, rgba(69, 71, 90, 0.3) 0, rgba(69, 71, 90, 0.3) 12px, transparent 12px, transparent 16px); background-color: transparent; border-radius: 4px; border: none; min-height: 24px; } "
        "progressbar progress { background-image: repeating-linear-gradient(to right, #cba6f7 0, #cba6f7 12px, transparent 12px, transparent 16px); background-color: transparent; border-radius: 4px; border: none; min-height: 24px; transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1); } ", -1, NULL);
    gtk_style_context_add_provider_for_screen(gdk_screen_get_default(), GTK_STYLE_PROVIDER(provider), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);

    g_io_add_watch(channel, G_IO_IN, on_fifo_data, osd);
    
    // Start listening but don't show window yet
    gtk_main();

    return 0;
}
