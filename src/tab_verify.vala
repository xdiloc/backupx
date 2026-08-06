using Gtk;

public class VerifyTab : Box {
	private TreeView tree_view;
	private Gtk.ListStore list_store;
	private Window parent_window;
	private Spinner spinner;
	private Button btn_check;
	private Button btn_refresh;
	private Button btn_open;

	private struct BackupItem {
		string name;
		string size_str;
		string date_str;
		int64 mtime;
	}

	/**
	 * @brief Проверка, выполняется ли сейчас фоновая задача
	 */
	public bool is_busy() {
		return !btn_check.sensitive;
	}

	/**
	 * @brief Конструктор вкладки проверки архивов
	 * parent - родительское окно
	 */
	public VerifyTab(Window parent) {
		Object(orientation: Orientation.VERTICAL, spacing: 10);
		this.parent_window = parent;

		this.set_margin_start(20);
		this.set_margin_end(20);
		this.set_margin_top(20);
		this.set_margin_bottom(20);

		// 3 колонки: Имя, Размер, Дата
		list_store = new Gtk.ListStore(3, typeof(string), typeof(string), typeof(string));
		tree_view = new TreeView.with_model(list_store);
		tree_view.set_grid_lines(TreeViewGridLines.BOTH);

		var renderer = new CellRendererText();

		var col_name = new Gtk.TreeViewColumn.with_attributes("Имя архива", renderer, "text", 0);
		col_name.resizable = true;
		col_name.expand = true;
		tree_view.append_column(col_name);

		var col_size = new Gtk.TreeViewColumn.with_attributes("Размер", renderer, "text", 1);
		col_size.resizable = true;
		tree_view.append_column(col_size);

		var col_date = new Gtk.TreeViewColumn.with_attributes("Дата создания", renderer, "text", 2);
		col_date.resizable = true;
		tree_view.append_column(col_date);

		var scroll = new ScrolledWindow(null, null);
		scroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		scroll.set_shadow_type(ShadowType.IN);
		scroll.add(tree_view);
		scroll.set_vexpand(true);

		btn_refresh = new Button.with_label("Обновить список");
		btn_refresh.clicked.connect(() => {
			refresh_backups();
		});

		btn_check = new Button.with_label("Проверить выбранный архив");
		btn_check.clicked.connect(() => {
			verify_backup(parent_window);
		});

		btn_open = new Button.with_label("Открыть папку");
		btn_open.clicked.connect(() => {
			try {
				AppInfo.launch_default_for_uri("file://" + BACKUP_DIR, null);
			} catch (Error e) {
				show_error(parent_window, "Ошибка", "Не удалось открыть директорию: " + e.message);
			}
		});

		spinner = new Spinner();
		spinner.set_no_show_all(true);

		var right_buttons_box = new Box(Orientation.HORIZONTAL, 10);
		right_buttons_box.pack_end(btn_open, false, false, 0);
		right_buttons_box.pack_end(btn_check, false, false, 0);
		right_buttons_box.pack_end(btn_refresh, false, false, 0);

		var button_box = new Box(Orientation.HORIZONTAL, 10);
		button_box.pack_start(spinner, false, false, 0);
		button_box.pack_end(right_buttons_box, false, false, 0);

		this.pack_start(scroll, true, true, 0);
		this.pack_start(button_box, false, false, 5);

		refresh_backups();
	}

	/**
	 * @brief Обновление списка доступных архивов во вкладке проверки средствами GLib/Gio
	 */
	public void refresh_backups() {
		list_store.clear();
		try {
			var dir = File.new_for_path(BACKUP_DIR);
			if (!dir.query_exists()) return;

			var enumerator = dir.enumerate_children("standard::name,standard::size,time::modified", 0);
			FileInfo info;
			BackupItem[] items = {};

			while ((info = enumerator.next_file()) != null) {
				string name = info.get_name();
				if (name.has_suffix(".tar")) {
					string date_str = "Н/Д";
					int64 mtime = 0;

					// Получаем размер файла средствами GLib через общий метод
					string size_str = format_file_size(info.get_size());

					// Получаем дату модификации файла средствами GLib
					var dt = info.get_modification_date_time();
					if (dt != null) {
						var local_dt = dt.to_local();
						date_str = local_dt.format("%Y-%m-%d %H:%M:%S");
						mtime = local_dt.to_unix();
					}

					items += BackupItem() { name = name, size_str = size_str, date_str = date_str, mtime = mtime };
				}
			}

			// Сортировка по времени: от новых к старым (убывание mtime) с помощью QuickSort
			if (items.length > 1) {
				quick_sort(items, 0, (int)items.length - 1);
			}

			// Заполнение хранилища отсортированными элементами
			foreach (var item in items) {
				TreeIter iter;
				list_store.append(out iter);
				list_store.set(iter, 0, item.name, 1, item.size_str, 2, item.date_str);
			}
		} catch (Error e) {
			stderr.printf("Error: %s\n", e.message);
		}
	}

	/**
	 * @brief Быстрая сортировка массива элементов бэкапов по времени модификации
	 * items - массив элементов бэкапа
	 * low - начальный индекс сортируемого подмассива
	 * high - конечный индекс сортируемого подмассива
	 */
	private void quick_sort(BackupItem[] items, int low, int high) {
		if (low < high) {
			int pi = partition(items, low, high);
			quick_sort(items, low, pi - 1);
			quick_sort(items, pi + 1, high);
		}
	}

	/**
	 * @brief Вспомогательная функция разделения массива для быстрой сортировки
	 * items - массив элементов бэкапа
	 * low - начальный индекс
	 * high - конечный индекс
	 */
	private int partition(BackupItem[] items, int low, int high) {
		int64 pivot = items[high].mtime;
		int i = (low - 1);
		for (int j = low; j <= high - 1; j++) {
			if (items[j].mtime > pivot) {
				i++;
				BackupItem temp = items[i];
				items[i] = items[j];
				items[j] = temp;
			}
		}
		BackupItem temp = items[i + 1];
		items[i + 1] = items[high];
		items[high] = temp;
		return (i + 1);
	}

	/**
	 * @brief Проверка целостности выбранного архива по контрольной сумме в отдельном фоновом потоке
	 * parent - родительское окно
	 */
	private void verify_backup(Window parent) {
		TreeIter iter;
		TreeModel model;
		if (!tree_view.get_selection().get_selected(out model, out iter)) {
			show_error(parent, "Ошибка", "Выберите архив из списка для проверки.");
			return;
		}

		string selected_name;
		model.get(iter, 0, out selected_name);

		string selected_file = Path.build_filename(BACKUP_DIR, selected_name);

		// Безопасное формирование имени файла манифеста без жесткого обрезания строк
		if (!selected_name.has_suffix(".tar")) {
			show_error(parent, "Ошибка", "Неверный формат имени архивного файла.");
			return;
		}
		string manifest_file = Path.build_filename(BACKUP_DIR, selected_name.substring(0, selected_name.length - 4) + ".sha256");

		if (!FileUtils.test(selected_file, FileTest.EXISTS)) {
			show_error(parent, "Ошибка", "Выбранный файл не найден.");
			return;
		}

		if (!FileUtils.test(manifest_file, FileTest.EXISTS)) {
			show_error(parent, "Ошибка", "Файл контрольной суммы (.sha256) для этого архива не найден!");
			return;
		}

		// Блокируем интерфейс и запускаем спиннер перед операцией
		btn_check.sensitive = false;
		btn_refresh.sensitive = false;
		spinner.start();
		spinner.show();

		// Запускаем процесс в отдельном системном потоке, чтобы не морозить GUI
		new Thread<void*>("verify-worker", () => {
			string? err_msg = null;
			string? success_msg = null;
			double elapsed = 0.0;

			var timer = new Timer();
			timer.start();

			// Искусственная задержка
			/*
			for (int i = 0; i < 60; i++) {
				Posix.usleep(100000); // 0.1 сек
				while (Gtk.events_pending()) {
					Gtk.main_iteration();
				}
			}
			*/

			try {
				string manifest_contents;
				if (!FileUtils.get_contents(manifest_file, out manifest_contents)) {
					err_msg = "Не удалось прочитать файл манифеста.";
					throw new IOError.FAILED(err_msg);
				}

				// Безопасный парсинг манифеста с проверкой на пустоту массива
				string[] parts = manifest_contents.split_set(" \t\n");
				if (parts.length == 0 || parts[0].strip() == "") {
					err_msg = "Файл манифеста поврежден или имеет неверный формат.";
					throw new IOError.FAILED(err_msg);
				}

				string expected_hash = parts[0].strip();
				string? actual_hash = calculate_sha256(selected_file);

				timer.stop();
				elapsed = timer.elapsed();

				string formatted_time = format_elapsed_time(elapsed);
				if (actual_hash != null && actual_hash == expected_hash) {
					success_msg = "Контрольная сумма подтверждена.\nЦелостность архива не нарушена.\nВремя проверки: %s".printf(formatted_time);
				} else {
					err_msg = "Контрольная сумма не совпадает!\nАрхив поврежден или изменен.\nВремя проверки: %s".printf(formatted_time);
					throw new IOError.FAILED(err_msg);
				}
			} catch (Error e) {
				timer.stop();
				if (err_msg == null) {
					err_msg = e.message;
				}
			}

			// Возвращаем управление в главный поток GTK для разблокировки интерфейса и вывода результатов
			Idle.add(() => {
				if (spinner != null) {
					spinner.stop();
					spinner.hide();
				}
				if (btn_check != null) {
					btn_check.sensitive = true;
				}
				if (btn_refresh != null) {
					btn_refresh.sensitive = true;
				}

				if (err_msg != null && success_msg == null) {
					show_error(parent, "Ошибка", err_msg);
				} else if (success_msg != null) {
					show_info(parent, "Проверка", success_msg);
				}
				return false;
			});

			return null;
		});
	}
}
