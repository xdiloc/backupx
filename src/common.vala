using Gtk;
using GLib;

/**
 * @brief Делегат для callback-функций без аргументов
 */
public delegate void SimpleCallback();

/**
 * @brief Показ предупреждающего окна
 * parent - родительское окно
 * title - заголовок окна
 * message - текст сообщения
 */
public void show_warning(Gtk.Window? parent, string title, string message) {
	var dialog = new Gtk.MessageDialog(parent, Gtk.DialogFlags.MODAL, Gtk.MessageType.WARNING, Gtk.ButtonsType.OK, "%s", message);
	dialog.title = title;
	dialog.run();
	dialog.destroy();
}

/**
 * @brief Показ диалогового окна с ошибкой
 * parent - родительское окно
 * title - заголовок окна
 * message - текст сообщения
 */
public void show_error(Gtk.Window? parent, string title, string message) {
	var dialog = new Gtk.MessageDialog(parent, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, "%s", message);
	dialog.title = title;
	dialog.run();
	dialog.destroy();
}

/**
 * @brief Показ информационного окна
 * parent - родительское окно
 * title - заголовок окна
 * message - текст сообщения
 */
public void show_info(Gtk.Window parent, string title, string message) {
	var dialog = new Gtk.MessageDialog(parent, Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.OK, "%s", message);
	dialog.title = title;
	dialog.run();
	dialog.destroy();
}

/**
 * @brief Показ информационного окна со свернутой статистикой выполнения
 * parent - родительское окно
 * title - заголовок окна
 * message - основной текст сообщения
 * stats_text - текст со статистикой по времени процессов
 */
public void show_info_with_stats(Gtk.Window parent, string title, string message, string stats_text) {
	var dialog = new Gtk.Dialog.with_buttons(
		title,
		parent,
		Gtk.DialogFlags.MODAL,
		"OK",
		Gtk.ResponseType.OK,
		null
	);

	var content_area = dialog.get_content_area() as Gtk.Box;
	content_area.set_spacing(10);
	content_area.set_margin_start(15);
	content_area.set_margin_end(15);
	content_area.set_margin_top(15);
	content_area.set_margin_bottom(15);

	var label = new Gtk.Label(message);
	label.set_xalign(0);
	content_area.pack_start(label, false, false, 0);

	var expander = new Gtk.Expander("Статистика выполнения");
	expander.expanded = false;

	var stats_label = new Gtk.Label(stats_text);
	stats_label.set_xalign(0);
	stats_label.set_margin_start(10);
	stats_label.set_margin_top(5);
	expander.add(stats_label);

	content_area.pack_start(expander, false, false, 0);

	dialog.show_all();
	dialog.run();
	dialog.destroy();
}

/**
 * @brief Показ диалогового окна с подтверждением (Да/Нет)
 * parent - родительское окно
 * title - заголовок окна
 * message - текст сообщения
 * return - true, если пользователь нажал YES, иначе false
 */
public bool show_confirm_dialog(Gtk.Window parent, string title, string message) {
	var dialog = new Gtk.MessageDialog(parent, Gtk.DialogFlags.MODAL, Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, "%s", message);
	dialog.title = title;
	int response = dialog.run();
	dialog.destroy();
	return response == Gtk.ResponseType.YES;
}

/**
 * @brief Форматирование размера файла в читаемый вид
 * size - размер файла в байтах
 */
public string format_file_size(uint64 size) {
	const uint64 KB = 1024;
	const uint64 MB = KB * 1024;
	const uint64 GB = MB * 1024;
	const uint64 TB = GB * 1024;

	if (size < KB) {
		return "%u Б".printf((uint)size);
	} else if (size < MB) {
		return "%.1f КБ".printf((double)size / (double)KB);
	} else if (size < GB) {
		return "%.1f МБ".printf((double)size / (double)MB);
	} else if (size < TB) {
		return "%.2f ГБ".printf((double)size / (double)GB);
	} else {
		return "%.2f ТБ".printf((double)size / (double)TB);
	}
}

/**
 * @brief Форматирование времени выполнения в читаемый вид (мс, секунды, минуты, часы)
 * seconds - время в секундах
 * return - отформатированная строка времени
 */
public string format_elapsed_time(double seconds) {
	if (seconds < 1.0) {
		int ms = (int)(seconds * 1000.0 + 0.5);
		return "%d мс".printf(ms);
	}

	int total_sec = (int)seconds;
	int hours = total_sec / 3600;
	int minutes = (total_sec % 3600) / 60;
	int secs = total_sec % 60;

	if (hours > 0) {
		return "%d ч. %d мин. %d сек.".printf(hours, minutes, secs);
	} else if (minutes > 0) {
		return "%d мин. %d сек.".printf(minutes, secs);
	} else {
		return "%d сек.".printf(secs);
	}
}

/**
 * @brief Получение строки со свободным местом на диске для указанного пути
 * target_path - путь к директории или файлу
 */
public string get_free_space_string(string? target_path) {
	string target_dir = (target_path != null && target_path != "") ? target_path : Environment.get_home_dir();
	try {
		var file = File.new_for_path(target_dir);
		var fs_info = file.query_filesystem_info("filesystem::*", null);
		uint64 free_space = fs_info.get_attribute_uint64(FileAttribute.FILESYSTEM_FREE);
		return format_file_size(free_space);
	} catch (Error e) {
		return "Н/Д";
	}
}
