using Gtk;
using GLib;

// Конфигурация
public string SRC_DIR = null;
public string BACKUP_DIR = null;
public string ACTIVE_PRESET = null;

/**
 * @brief Структура для хранения пресета бэкапа
 * name - имя пресета
 * src - исходная папка
 * backup - папка бэкапов
 */
public class Preset {
	public string name;
	public string src;
	public string backup;

	public Preset(string name, string src, string backup) {
		this.name = name;
		this.src = src;
		this.backup = backup;
	}
}

public List<Preset> presets = null;

/**
 * @brief Получение пути к файлу конфигурации пресетов
 */
private string get_settings_file_path() {
	return Environment.get_user_config_dir() + "/xback/presets";
}

/**
 * @brief Загрузка конфигурации через GLib.KeyFile
 * config_file - путь к файлу конфигурации
 * kf - объект для работы с INI файлом
 * group - имя группы для чтения
 * i - счетчик итераций
 * e - объект ошибки
 */
public void load_settings() {
	string config_file = get_settings_file_path();
	presets = new List<Preset>();
	ACTIVE_PRESET = null;
	SRC_DIR = "";
	BACKUP_DIR = "";

	if (!FileUtils.test(config_file, FileTest.EXISTS)) return;

	var kf = new KeyFile();
	try {
		kf.load_from_file(config_file, KeyFileFlags.NONE);

		// Чтение General
		if (kf.has_group("General")) {
			ACTIVE_PRESET = kf.get_string("General", "Name");
			SRC_DIR = kf.get_string("General", "Src");
			BACKUP_DIR = kf.get_string("General", "Backup");
		}

		// Чтение пресетов (итерация по группам Preset0, Preset1...)
		for (int i = 0; ; i++) {
			string group = "Preset%d".printf(i);
			if (!kf.has_group(group)) break;

			presets.append(new Preset(
				kf.get_string(group, "Name"),
				kf.get_string(group, "Src"),
				kf.get_string(group, "Backup")
			));
		}
	} catch (Error e) {
		show_error(null, "Ошибка загрузки", "Не удалось загрузить настройки:\n" + e.message);
	}
}

/**
 * @brief Сохранение конфигурации через GLib.KeyFile
 * config_file - путь к файлу конфигурации
 * config_dir - путь к директории с конфигом
 * dir - объект для работы с файловой системой
 * kf - объект для записи данных
 * i - счетчик пресетов
 * p - текущий объект пресета
 * group - имя группы для записи
 * e - объект ошибки
 */
public void save_settings() {
	string config_file = get_settings_file_path();
	string config_dir = Path.get_dirname(config_file);

	try {
		var dir = File.new_for_path(config_dir);
		if (!dir.query_exists()) {
			dir.make_directory_with_parents(null);
		}

		var kf = new KeyFile();

		// Запись General
		kf.set_string("General", "Name", (ACTIVE_PRESET != null) ? ACTIVE_PRESET : "None");
		kf.set_string("General", "Src", (SRC_DIR != null) ? SRC_DIR : "");
		kf.set_string("General", "Backup", (BACKUP_DIR != null) ? BACKUP_DIR : "");

		// Запись пресетов
		int i = 0;
		foreach (var p in presets) {
			string group = "Preset%d".printf(i++);
			kf.set_string(group, "Name", p.name);
			kf.set_string(group, "Src", p.src);
			kf.set_string(group, "Backup", p.backup);
		}

		FileUtils.set_contents(config_file, kf.to_data());
	} catch (Error e) {
		show_error(null, "Ошибка сохранения", "Не удалось сохранить настройки:\n" + e.message);
	}
}
