using GLib;

namespace SwayNotificationCenter.Widgets {
    public class ButtonsGrid : BaseWidget {
        public override string widget_name {
            get {
                return "buttons-grid";
            }
        }

        Action[] actions;
        // 7 is the default Gtk.FlowBox.max_children_per_line
        int buttons_per_row = 7;
        List<ToggleButton> toggle_buttons;

        public ButtonsGrid (string suffix) {
            base (suffix);

            Json.Object ?config = get_config (this);
            if (config != null) {
                Json.Array a = get_prop_array (config, "actions");
                if (a != null) {
                    actions = parse_actions (a);
                }

                bool bpr_found = false;
                int bpr = get_prop<int> (config, "buttons-per-row", out bpr_found);
                if (bpr_found) {
                    buttons_per_row = bpr;
                }
            }

            Gtk.FlowBox container = new Gtk.FlowBox ();
            container.set_max_children_per_line (buttons_per_row);
            container.set_selection_mode (Gtk.SelectionMode.NONE);
            container.set_hexpand (true);
            append (container);

            // add action to container
            foreach (var act in actions) {
                Gtk.Widget button;
                switch (act.type) {
                    case ButtonType.TOGGLE :
                        ToggleButton tb = new ToggleButton (act.label, act.command,
                                                            act.update_command, act.active);
                        toggle_buttons.append (tb);
                        button = tb;
                        break;
                    default:
                        Gtk.Button b = new Gtk.Button.with_label (act.label);
                        b.clicked.connect (() => execute_command.begin (act.command));
                        button = b;
                        break;
                }
                button.add_css_class ("buttons-grid-icon");
                container.insert (wrap_with_caption (button, act.text), -1);
            }
        }

        // Wraps a button so its icon stays inside the clickable chip while the
        // caption is rendered underneath as plain text with no background.
        Gtk.Widget wrap_with_caption (Gtk.Widget button, string text) {
            if (text == "") {
                return button;
            }

            Gtk.Box wrapper = new Gtk.Box (Gtk.Orientation.VERTICAL, 4);
            wrapper.set_halign (Gtk.Align.CENTER);
            wrapper.append (button);

            Gtk.Label text_label = new Gtk.Label (text);
            text_label.add_css_class ("buttons-grid-text");
            wrapper.append (text_label);

            return wrapper;
        }

        public override void on_cc_visibility_change (bool value) {
            if (value) {
                foreach (var tb in toggle_buttons) {
                    tb.on_update.begin ();
                }
            }
        }
    }
}
