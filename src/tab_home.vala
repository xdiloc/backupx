using Gtk;
using GLib;

public class HomeTab : Box {
	private Window parent_window;

	/**
	 * @brief Конструктор вкладки справки
	 * parent - родительское окно
	 */
	public HomeTab(Window parent) {
		Object(orientation: Orientation.VERTICAL, spacing: 10);
		this.parent_window = parent;

		this.set_margin_start(20);
		this.set_margin_end(20);
		this.set_margin_top(20);
		this.set_margin_bottom(20);

		var label_welcome = new Label("<big><b>Справка и информация</b></big>");
		label_welcome.use_markup = true;
		label_welcome.set_xalign(0);

		var label_info = new Label("Программа предназначена для быстрого создания и проверки локальных резервных копий.");
		label_info.set_xalign(0);
		label_info.set_line_wrap(true);

		var label_rules = new Label(
			"<b>Важные рекомендации:</b>\n" +
			"1. Пожалуйста, не проводите никаких операций с файлами в архивируемой папке до завершения процесса упаковки.\n" +
			"2. Всегда следите за тем, чтобы на диске было достаточно свободного места для создания архива."
		);
		label_rules.use_markup = true;
		label_rules.set_xalign(0);
		label_rules.set_line_wrap(true);

		this.pack_start(label_welcome, false, false, 0);
		this.pack_start(label_info, false, false, 0);
		this.pack_start(label_rules, false, false, 0);
	}
}
