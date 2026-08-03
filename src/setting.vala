using Gtk;

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
 * @brief Вспомогательная функция для записи полей пресета в StringBuilder
 * sb - объект StringBuilder для формирования текста
 * name - имя пресета или конфигурации
 * src - путь к исходной папке
 * backup - путь к папке бэкапа
 */
private void append_preset_fields(StringBuilder sb, string name, string src, string backup) {
	sb.append("Name=" + name + "\n");
	sb.append("Src=" + src + "\n");
	sb.append("Backup=" + backup + "\n\n");
}

/**
 * @brief Загрузка конфигурации с одинаковым порядком полей для [General] и [Preset]
 */
public void load_settings() {
	string config_file = get_settings_file_path();

	presets = new List<Preset>();
	ACTIVE_PRESET = null;
	SRC_DIR = "";
	BACKUP_DIR = "";

	try {
		string contents;
		if (FileUtils.get_contents(config_file, out contents)) {
			string clean_contents = contents.replace("\r\n", "\n").replace("\r", "\n");
			string[] lines = clean_contents.split("\n");

			string current_name = null;
			string current_src = null;
			string current_backup = null;
			bool in_general_section = false;
			bool in_preset_section = false;

			foreach (var raw_line in lines) {
				string line = raw_line.strip();

				if (line == "[General]") {
					in_general_section = true;
					in_preset_section = false;
					continue;
				} else if (line == "[Preset]") {
					if (in_preset_section && current_name != null && current_src != null && current_backup != null) {
						presets.append(new Preset(current_name, current_src, current_backup));
					}
					in_general_section = false;
					in_preset_section = true;
					current_name = null;
					current_src = null;
					current_backup = null;
					continue;
				}

				if (in_general_section) {
					if (line.has_prefix("Name=")) {
						string ap = line.substring(5).strip();
						if (ap != "" && ap != "None") {
							ACTIVE_PRESET = ap;
						}
					} else if (line.has_prefix("Src=")) {
						SRC_DIR = line.substring(4).strip();
					} else if (line.has_prefix("Backup=")) {
						string bkp = line.substring(7).strip();
						if (bkp != "None") {
							BACKUP_DIR = bkp;
						}
					}
				} else if (in_preset_section) {
					if (line.has_prefix("Name=")) {
						current_name = line.substring(5).strip();
					} else if (line.has_prefix("Src=")) {
						current_src = line.substring(4).strip();
					} else if (line.has_prefix("Backup=")) {
						current_backup = line.substring(7).strip();

						if (current_name != null && current_name != "" && current_src != null && current_backup != null) {
							presets.append(new Preset(current_name, current_src, current_backup));
						}
						in_preset_section = false;
						current_name = null;
						current_src = null;
						current_backup = null;
					}
				}
			}

			if (in_preset_section && current_name != null && current_src != null && current_backup != null) {
				presets.append(new Preset(current_name, current_src, current_backup));
			}
		}
	} catch (Error e) {
		show_error(null, "Ошибка загрузки", "Не удалось загрузить настройки:\n" + e.message);
	}

	if (SRC_DIR == null) {
		SRC_DIR = "";
	}
	if (BACKUP_DIR == null) {
		BACKUP_DIR = "";
	}
}

/**
 * @brief Сохранение конфигурации с единым порядком полей (Name, Src, Backup)
 */
public void save_settings() {
	string config_file = get_settings_file_path();
	string config_dir = Path.get_dirname(config_file);
	try {
		var dir = File.new_for_path(config_dir);
		if (!dir.query_exists()) {
			dir.make_directory_with_parents(null);
		}
		var sb = new StringBuilder();

		// Подготовка значений для главной секции
		string general_name = (ACTIVE_PRESET != null && ACTIVE_PRESET != "") ? ACTIVE_PRESET : "None";
		string general_src = SRC_DIR != null ? SRC_DIR : "";
		string general_backup = BACKUP_DIR != null ? BACKUP_DIR : "";

		// Главная секция параметров в том же порядке
		sb.append("[General]\n");
		append_preset_fields(sb, general_name, general_src, general_backup);

		// Секции пресетов
		if (presets != null) {
			foreach (var p in presets) {
				sb.append("[Preset]\n");
				append_preset_fields(sb, p.name, p.src, p.backup);
			}
		}

		FileUtils.set_contents(config_file, sb.str);
	} catch (Error e) {
		show_error(null, "Ошибка сохранения", "Не удалось сохранить настройки:\n" + e.message);
	}
}
