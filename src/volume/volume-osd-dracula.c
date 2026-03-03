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
    const char *icon;
    if (volume == 0) icon = ICON_MUTE;
    else if (volume < 33) icon = ICON_LOW;
    else if (volume < 66) icon = ICON_MID;
    else icon = ICON_HIGH;

    char icon_markup[128];
    snprintf(icon_markup, sizeof(icon_markup), "<span font='28' color='%s'>%s</span>", 
             volume == 0 ? "#ff5555" : "#bd93f9", icon);
    gtk_label_set_markup(GTK_LABEL(osd->icon_label), icon_markup);
    gtk_progress_bar_set_fraction(GTK_PROGRESS_BAR(osd->progress), (double)volume / 100.0);

    if (osd->timeout_id > 0) g_source_remove(osd->timeout_id);
    osd->timeout_id = g_timeout_add(1500, hide_osd, osd);
    gtk_widget_show_all(osd->window);
}

static gboolean on_fifo_data(GIOChannel *source, GIOCondition condition, gpointer data) {
    OSDData *osd = (OSDData *)data;
    gchar *str = NULL;
    gsize len;
    GIOStatus status;
    int last_val = -1;

    while ((status = g_io_channel_read_line(source, &str, &len, NULL, NULL)) == G_IO_STATUS_NORMAL) {
        if (str) {
            last_val = atoi(str);
            g_free(str);
        }
    }

    if (last_val != -1) {
        update_osd(osd, last_val);
    }

    if (status == G_IO_STATUS_EOF || status == G_IO_STATUS_ERROR) {
        return FALSE;
    }
    
    return TRUE;
}

int main(int argc, char *argv[]) {
    gtk_init(&argc, &argv);
    if (mkfifo(FIFO_PATH, 0666) == -1) {}
    
    int fd = open(FIFO_PATH, O_RDWR | O_NONBLOCK);
    if (fd == -1) return 1;

    GIOChannel *channel = g_io_channel_unix_new(fd);
    g_io_channel_set_flags(channel, G_IO_FLAG_NONBLOCK, NULL);
    
    OSDData *osd = g_new0(OSDData, 1);
    osd->window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    
    gtk_layer_init_for_window(GTK_WINDOW(osd->window));
    gtk_layer_set_layer(GTK_WINDOW(osd->window), GTK_LAYER_SHELL_LAYER_OVERLAY);
    gtk_layer_set_namespace(GTK_WINDOW(osd->window), "volume-osd-classic");
    gtk_layer_set_anchor(GTK_WINDOW(osd->window), GTK_LAYER_SHELL_EDGE_BOTTOM, TRUE);
    gtk_layer_set_margin(GTK_WINDOW(osd->window), GTK_LAYER_SHELL_EDGE_BOTTOM, 80);
    gtk_layer_set_keyboard_interactivity(GTK_WINDOW(osd->window), FALSE);

    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 15);
    gtk_container_set_border_width(GTK_CONTAINER(box), 20);
    gtk_container_add(GTK_CONTAINER(osd->window), box);

    osd->icon_label = gtk_label_new(NULL);
    gtk_widget_set_valign(osd->icon_label, GTK_ALIGN_CENTER);
    gtk_box_pack_start(GTK_BOX(box), osd->icon_label, FALSE, FALSE, 0);

    osd->progress = gtk_progress_bar_new();
    gtk_widget_set_valign(osd->progress, GTK_ALIGN_CENTER);
    gtk_widget_set_size_request(osd->progress, 250, 32);
    gtk_box_pack_start(GTK_BOX(box), osd->progress, TRUE, TRUE, 0);

    GtkCssProvider *provider = gtk_css_provider_new();
    gtk_css_provider_load_from_data(provider,
        "window { background-color: #282a36; border-radius: 24px; border: 2px solid #bd93f9; } "
        "trough { background-color: #44475a; border-radius: 16px; min-height: 32px; } "
        "progress { background-color: #bd93f9; border-radius: 16px; min-height: 32px; transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1); } ", -1, NULL);
    gtk_style_context_add_provider_for_screen(gdk_screen_get_default(), GTK_STYLE_PROVIDER(provider), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);

    g_io_add_watch(channel, G_IO_IN, on_fifo_data, osd);
    gtk_main();
    return 0;
}
