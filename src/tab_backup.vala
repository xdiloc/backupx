using Gtk;

public class BackupTab : Box {
	private Window parent_window;
	private Entry entry_src;
	private Entry entry_backup;
	private PresetWidget preset_widget;
	private Button btn_make;
	private Spinner spinner;
	private Label label_free_space;
	private Image icon_disk;
	private uint backup_save_timeout_id = 0;

	/**
	@brief Проверка, выполняется ли сейчас фоновая задача
	*/
	public bool is_busy() {
		return !btn_make.sensitive;
	}

	/**
	@brief Отложенное сохранение настроек и обновление свободного места
	on_success - callback функция для обновления списка
	*/
	private void schedule_save(SimpleCallback? on_success) {
		if (backup_save_timeout_id != 0) {
			GLib.Source.remove(backup_save_timeout_id);
			backup_save_timeout_id = 0;
		}

		backup_save_timeout_id = GLib.Timeout.add(500, () => {
			update_free_space();
			save_settings();
			if (on_success != null) {
				on_success();
			}
			backup_save_timeout_id = 0;
			return false;
		});
	}

	/**
	@brief Конструктор вкладки создания бэкапа
	parent - родительское окно
	on_success - callback функция для обновления списка после создания бэкапа
	*/
	public BackupTab(Window parent, owned SimpleCallback? on_success = null) {
		Object(orientation: Orientation.VERTICAL, spacing: 10);
		this.parent_window = parent;

		this.set_margin_start(20);
		this.set_margin_end(20);
		this.set_margin_top(20);
		this.set_margin_bottom(20);

		entry_src = new Entry();
		entry_backup = new Entry();
		label_free_space = new Label("");
		label_free_space.set_tooltip_text("Свободное место на диске");

		preset_widget = new PresetWidget(parent_window, entry_src, entry_backup, () => {
			update_free_space();
			if (on_success != null) {
				on_success();
			}
		});

		var label_src = new Label("Исходная папка:");
		label_src.set_xalign(0);
		entry_src.text = SRC_DIR;

		entry_src.changed.connect(() => {
			SRC_DIR = entry_src.text;
			preset_widget.reset_selection();
			schedule_save(on_success);
		});

		var btn_choose_src = new Button.with_label("Обзор...");
		btn_choose_src.clicked.connect(() => {
			if (backup_save_timeout_id != 0) {
				GLib.Source.remove(backup_save_timeout_id);
				backup_save_timeout_id = 0;
			}
			choose_directory(parent_window, "Выберите исходную папку", entry_src);
			SRC_DIR = entry_src.text;
			update_free_space();
			save_settings();
			if (on_success != null) {
				on_success();
			}
		});

		var box_src = new Box(Orientation.HORIZONTAL, 5);
		box_src.pack_start(entry_src, true, true, 0);
		box_src.pack_start(btn_choose_src, false, false, 0);

		var label_backup = new Label("Папка бэкапов:");
		label_backup.set_xalign(0);
		entry_backup.text = BACKUP_DIR;

		entry_backup.changed.connect(() => {
			BACKUP_DIR = entry_backup.text;
			preset_widget.reset_selection();
			schedule_save(on_success);
		});

		var btn_choose_backup = new Button.with_label("Обзор...");
		btn_choose_backup.clicked.connect(() => {
			if (backup_save_timeout_id != 0) {
				GLib.Source.remove(backup_save_timeout_id);
				backup_save_timeout_id = 0;
			}
			choose_directory(parent_window, "Выберите папку для бэкапов", entry_backup);
			BACKUP_DIR = entry_backup.text;
			update_free_space();
			save_settings();
			if (on_success != null) {
				on_success();
			}
		});

		var box_backup = new Box(Orientation.HORIZONTAL, 5);
		box_backup.pack_start(entry_backup, true, true, 0);
		box_backup.pack_start(btn_choose_backup, false, false, 0);

		btn_make = new Button.with_label("Сделать бэкап");
		spinner = new Spinner();
		spinner.set_no_show_all(true);

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
			if (backup_save_timeout_id != 0) {
				GLib.Source.remove(backup_save_timeout_id);
				backup_save_timeout_id = 0;
			}
			SRC_DIR = entry_src.text;
			BACKUP_DIR = entry_backup.text;
			save_settings();
			start_backup_task(parent_window, btn_make, spinner, on_success);
		});

		this.pack_start(preset_widget, false, false, 5);

		this.pack_start(label_src, false, false, 0);
		this.pack_start(box_src, false, false, 5);
		this.pack_start(label_backup, false, false, 0);
		this.pack_start(box_backup, false, false, 5);
		this.pack_start(box_action, false, false, 0);
	}

	/**
	@brief Обновление информации о свободном месте
	*/
	public void update_free_space() {
		string space = get_free_space_string(BACKUP_DIR);
		label_free_space.label = "<b>%s</b>".printf(space);
		label_free_space.use_markup = true;
	}

	/**
	@brief Диалог выбора папки
	parent - родительское окно
	title - заголовок диалога
	entry - текстовое поле для записи выбранного пути
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
