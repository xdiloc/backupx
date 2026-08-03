using Gtk;

public class BackupTab : Box {
	private Window parent_window;
	private Entry entry_src;
	private Entry entry_backup;
	private ComboBoxText combo_presets;
	private Entry entry_preset_name;
	private Button btn_make;
	private Spinner spinner;
	private Label label_free_space;
	private Image icon_disk;
	private bool is_updating_preset = false;

	/**
	 * @brief Конструктор вкладки создания бэкапа
	 * parent - родительское окно
	 * on_success - callback функция для обновления списка после создания бэкапа
	 */
	public BackupTab(Window parent, owned SimpleCallback? on_success = null) {
		Object(orientation: Orientation.VERTICAL, spacing: 10);
		this.parent_window = parent;

		this.set_margin_start(20);
		this.set_margin_end(20);
		this.set_margin_top(20);
		this.set_margin_bottom(20);

		// --- Блок пресетов ---
		var label_presets = new Label("Пресеты:");
		label_presets.set_xalign(0);

		combo_presets = new ComboBoxText();
		refresh_presets_combo();

		combo_presets.changed.connect(() => {
			if (is_updating_preset) return;
			string active_text = combo_presets.get_active_text();
			if (active_text != null && active_text != "-- Выберите пресет --") {
				is_updating_preset = true;
				apply_preset(active_text);
				is_updating_preset = false;
			} else {
				ACTIVE_PRESET = null;
			}
			save_settings();
			update_free_space();
		});

		entry_preset_name = new Entry();
		entry_preset_name.placeholder_text = "Имя пресета";

		var btn_save_preset = new Button.with_label("Сохранить");
		btn_save_preset.clicked.connect(() => {
			string name = entry_preset_name.text.strip().replace("\n", "").replace("\r", "");
			if (name == "" || name == "-- Выберите пресет --" || name == "None") {
				show_error(parent_window, "Ошибка", "Недопустимое имя пресета!");
				return;
			}
			string src = entry_src.text.strip();
			string backup = entry_backup.text.strip();
			if (src == "" || backup == "") {
				show_error(parent_window, "Ошибка", "Заполните исходную папку и папку бэкапов!");
				return;
			}

			Preset? existing = null;
			foreach (var p in presets) {
				if (p.name == name) {
					existing = p;
					break;
				}
			}

			if (existing != null) {
				if (!show_confirm_dialog(parent_window, "Подтверждение", "Пресет с именем \"%s\" уже существует. Перезаписать?".printf(name))) {
					return;
				}
				existing.src = src;
				existing.backup = backup;
			} else {
				presets.append(new Preset(name, src, backup));
			}

			ACTIVE_PRESET = name;
			save_settings();

			is_updating_preset = true;
			refresh_presets_combo();
			entry_preset_name.text = "";
			is_updating_preset = false;
		});

		var btn_del_preset = new Button.with_label("Удалить");
		btn_del_preset.clicked.connect(() => {
			string active_text = combo_presets.get_active_text();
			if (active_text == null || active_text == "-- Выберите пресет --") {
				show_error(parent_window, "Ошибка", "Выберите пресет для удаления из выпадающего списка!");
				return;
			}

			string name = active_text;

			Preset? target = null;
			int target_index = -1;
			int idx = 0;
			foreach (var p in presets) {
				if (p.name == name) {
					target = p;
					target_index = idx;
					break;
				}
				idx++;
			}

			if (target == null) {
				show_error(parent_window, "Ошибка", "Пресет не найден!");
				return;
			}

			if (!show_confirm_dialog(parent_window, "Подтверждение удаления", "Вы действительно хотите удалить пресет \"%s\"?".printf(name))) {
				return;
			}

			presets.remove(target);

			int presets_len = (int)presets.length();
			if (presets_len > 0) {
				int new_index = target_index - 1;
				if (new_index < 0) {
					new_index = 0;
				}
				Preset? next_preset = presets.nth_data(new_index);
				if (next_preset != null) {
					ACTIVE_PRESET = next_preset.name;
				} else {
					ACTIVE_PRESET = null;
				}
			} else {
				ACTIVE_PRESET = null;
			}

			is_updating_preset = true;
			refresh_presets_combo();
			entry_preset_name.text = "";
			is_updating_preset = false;

			save_settings();
		});

		var box_preset_row1 = new Box(Orientation.HORIZONTAL, 5);
		box_preset_row1.pack_start(combo_presets, true, true, 0);

		var box_preset_row2 = new Box(Orientation.HORIZONTAL, 5);
		box_preset_row2.pack_start(entry_preset_name, true, true, 0);
		box_preset_row2.pack_start(btn_save_preset, false, false, 0);
		box_preset_row2.pack_start(btn_del_preset, false, false, 0);

		// --- Основные поля путей ---
		var label_src = new Label("Исходная папка:");
		label_src.set_xalign(0);
		entry_src = new Entry();
		entry_src.text = SRC_DIR;

		entry_src.changed.connect(() => {
			SRC_DIR = entry_src.text;
			reset_preset_selection_if_needed();
		});

		var btn_choose_src = new Button.with_label("Обзор...");
		btn_choose_src.clicked.connect(() => {
			choose_directory(parent_window, "Выберите исходную папку", entry_src);
			SRC_DIR = entry_src.text;
		});

		var box_src = new Box(Orientation.HORIZONTAL, 5);
		box_src.pack_start(entry_src, true, true, 0);
		box_src.pack_start(btn_choose_src, false, false, 0);

		var label_backup = new Label("Папка бэкапов:");
		label_backup.set_xalign(0);
		entry_backup = new Entry();
		entry_backup.text = BACKUP_DIR;

		entry_backup.changed.connect(() => {
			BACKUP_DIR = entry_backup.text;
			reset_preset_selection_if_needed();
			update_free_space();
			if (on_success != null) {
				on_success();
			}
		});

		var btn_choose_backup = new Button.with_label("Обзор...");
		btn_choose_backup.clicked.connect(() => {
			choose_directory(parent_window, "Выберите папку для бэкапов", entry_backup);
			BACKUP_DIR = entry_backup.text;
			update_free_space();
			if (on_success != null) {
				on_success();
			}
		});

		var box_backup = new Box(Orientation.HORIZONTAL, 5);
		box_backup.pack_start(entry_backup, true, true, 0);
		box_backup.pack_start(btn_choose_backup, false, false, 0);

		// Кнопка, спиннер и метка свободного места в нижней панели
		btn_make = new Button.with_label("Сделать бэкап");
		spinner = new Spinner();
		spinner.set_no_show_all(true);

		label_free_space = new Label("");
		label_free_space.set_tooltip_text("Свободное место на диске");

		icon_disk = new Image.from_icon_name("drive-harddisk", IconSize.INVALID);
		icon_disk.pixel_size = 28;

		var box_space = new Box(Orientation.HORIZONTAL, 5);
		box_space.pack_start(icon_disk, false, false, 0);
		box_space.pack_start(label_free_space, false, false, 0);

		update_free_space();

		var box_action = new Box(Orientation.HORIZONTAL, 10);
		box_action.pack_start(box_space, false, false, 0);
		box_action.pack_end(btn_make, false, false, 0);
		box_action.pack_end(spinner, false, false, 0);

		btn_make.clicked.connect(() => {
			SRC_DIR = entry_src.text;
			BACKUP_DIR = entry_backup.text;
			save_settings();
			start_backup_task(parent_window, btn_make, spinner, on_success);
		});

		// Добавление элементов на вкладку
		this.pack_start(label_presets, false, false, 0);
		this.pack_start(box_preset_row1, false, false, 0);
		this.pack_start(box_preset_row2, false, false, 5);

		this.pack_start(label_src, false, false, 0);
		this.pack_start(box_src, false, false, 5);
		this.pack_start(label_backup, false, false, 0);
		this.pack_start(box_backup, false, false, 5);
		this.pack_start(box_action, false, false, 0);
	}

	/**
	 * @brief Обновление информации о свободном месте
	 */
	public void update_free_space() {
		string space = get_free_space_string(BACKUP_DIR);
		label_free_space.label = "<b>%s</b>".printf(space);
		label_free_space.use_markup = true;
	}

	/**
	 * @brief Применение выбранного пресета к полям ввода
	 * name - имя пресета
	 */
	private bool apply_preset(string name) {
		foreach (var p in presets) {
			if (p.name == name) {
				ACTIVE_PRESET = p.name;
				entry_src.text = p.src;
				entry_backup.text = p.backup;
				return true;
			}
		}
		return false;
	}

	/**
	 * @brief Сброс выбора пресета при ручном изменении путей
	 */
	private void reset_preset_selection_if_needed() {
		if (!is_updating_preset) {
			is_updating_preset = true;
			if (combo_presets.get_active() > 0) {
				combo_presets.set_active(0);
			}
			is_updating_preset = false;
		}
	}

	/**
	 * @brief Обновление выпадающего списка пресетов
	 */
	private void refresh_presets_combo() {
		is_updating_preset = true;
		combo_presets.remove_all();
		combo_presets.append_text("-- Выберите пресет --");

		int active_index = 0;
		int current_index = 1;

		foreach (var p in presets) {
			combo_presets.append_text(p.name);
			if (ACTIVE_PRESET != null && p.name == ACTIVE_PRESET) {
				active_index = current_index;
			}
			current_index++;
		}

		combo_presets.set_active(active_index);
		if (active_index > 0 && ACTIVE_PRESET != null) {
			apply_preset(ACTIVE_PRESET);
		} else {
			combo_presets.set_active(0);
		}
		is_updating_preset = false;
		update_free_space();
	}

	/**
	 * @brief Диалог выбора папки
	 * parent - родительское окно
	 * title - заголовок диалога
	 * entry - текстовое поле для записи выбранного пути
	 */
	private void choose_directory(Window parent, string title, Entry entry) {
		var dialog = new FileChooserDialog(title, parent, FileChooserAction.SELECT_FOLDER,
			"Отмена", ResponseType.CANCEL,
			"Выбрать", ResponseType.ACCEPT);
		if (entry.text != "") {
			dialog.set_current_folder(entry.text);
		}
		if (dialog.run() == ResponseType.ACCEPT) {
			entry.text = dialog.get_filename();
		}
		dialog.destroy();
	}
}
