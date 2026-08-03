using Gtk;
using GLib;

/**
 * @brief Делегат для callback-функций без аргументов
 */
public delegate void SimpleCallback();

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
