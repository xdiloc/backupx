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

		// Визуальный разделитель с уменьшенным отступом
		var separator = new Separator(Orientation.HORIZONTAL);

		// Заголовок секции о программе
		var label_about_title = new Label("<b>О программе</b>");
		label_about_title.use_markup = true;
		label_about_title.set_xalign(0);

		// Контейнер для плотного размещения информации о программе без лишних отступов
		var about_box = new Box(Orientation.VERTICAL, 2);

		var version_label = new Label("Версия: 1.0");
		version_label.set_xalign(0);

		var label_dev = new Label("Разработчик: xdiloc");
		label_dev.set_xalign(0);

		var link = new Label("<a href=\"https://github.com/xdiloc/backupx\">https://github.com/xdiloc/backupx</a>");
		link.use_markup = true;
		link.set_xalign(0);

		about_box.pack_start(version_label, false, false, 0);
		about_box.pack_start(label_dev, false, false, 0);
		about_box.pack_start(link, false, false, 0);

		this.pack_start(label_welcome, false, false, 0);
		this.pack_start(label_info, false, false, 0);
		this.pack_start(label_rules, false, false, 0);
		this.pack_start(separator, false, false, 5);
		this.pack_start(label_about_title, false, false, 0);
		this.pack_start(about_box, false, false, 0);
	}
}
