using Gtk;

public class PresetWidget : Box {
	private ComboBoxText combo_presets;
	private Entry entry_preset_name;
	private Entry entry_src;
	private Entry entry_backup;
	private Window parent_window;
	private bool is_updating_preset = false;
	private SimpleCallback? on_preset_changed;

	/**
	@brief Конструктор виджета управления пресетами
	parent - родительское окно
	entry_s - текстовое поле исходной папки
	entry_b - текстовое поле папки бэкапов
	on_changed - callback при изменении или применении пресета
	*/
	public PresetWidget(Window parent, Entry entry_s, Entry entry_b, owned SimpleCallback? on_changed = null) {
		Object(orientation: Orientation.VERTICAL, spacing: 5);
		this.parent_window = parent;
		this.entry_src = entry_s;
		this.entry_backup = entry_b;
		this.on_preset_changed = (owned)on_changed;

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
			if (this.on_preset_changed != null) {
				this.on_preset_changed();
			}
		});

		entry_preset_name = new Entry();
		entry_preset_name.placeholder_text = "Имя пресета";

		var btn_save_preset = new Button.with_label("Сохранить");
		btn_save_preset.clicked.connect(on_save_clicked);

		var btn_del_preset = new Button.with_label("Удалить");
		btn_del_preset.clicked.connect(on_delete_clicked);

		var box_preset_row1 = new Box(Orientation.HORIZONTAL, 5);
		box_preset_row1.pack_start(combo_presets, true, true, 0);

		var box_preset_row2 = new Box(Orientation.HORIZONTAL, 5);
		box_preset_row2.pack_start(entry_preset_name, true, true, 0);
		box_preset_row2.pack_start(btn_save_preset, false, false, 0);
		box_preset_row2.pack_start(btn_del_preset, false, false, 0);

		this.pack_start(label_presets, false, false, 0);
		this.pack_start(box_preset_row1, false, false, 0);
		this.pack_start(box_preset_row2, false, false, 0);
	}

	/**
	@brief Обработчик сохранения пресета
	*/
	private void on_save_clicked() {
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
	}

	/**
	@brief Обработчик удаления пресета
	*/
	private void on_delete_clicked() {
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
		if (this.on_preset_changed != null) {
			this.on_preset_changed();
		}
	}

	/**
	@brief Применение выбранного пресета к полям ввода
	name - имя пресета
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
	@brief Сброс выбора пресета при ручном изменении путей внешне
	*/
	public void reset_selection() {
		if (!is_updating_preset) {
			ACTIVE_PRESET = null;
			is_updating_preset = true;
			if (combo_presets.get_active() > 0) {
				combo_presets.set_active(0);
			}
			is_updating_preset = false;
		}
	}

	/**
	@brief Обновление выпадающего списка пресетов
	*/
	public void refresh_presets_combo() {
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
	}
}
