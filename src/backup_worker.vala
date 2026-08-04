using Gtk;

/**
 * @brief Запуск процесса создания бэкапа в отдельном фоновом потоке
 * parent - родительское окно
 * btn_make - кнопка запуска создания бэкапа
 * spinner - индикатор выполнения
 * on_success - callback-функция при успешном завершении
 */
public void start_backup_task(Window parent, Button btn_make, Spinner spinner, SimpleCallback? on_success) {
	if (!FileUtils.test(SRC_DIR, FileTest.IS_DIR)) {
		show_error(parent, "Ошибка", "Исходная директория " + SRC_DIR + " не найдена.");
		return;
	}

	if (!FileUtils.test(BACKUP_DIR, FileTest.IS_DIR)) {
		show_error(parent, "Ошибка", "Директория для бэкапов " + BACKUP_DIR + " не найдена.");
		return;
	}

	// Предупреждение
/*
	var warn_dialog = new MessageDialog(parent, DialogFlags.MODAL, MessageType.WARNING, ButtonsType.OK, 
		"Пожалуйста, не проводите никаких операций с файлами в архивируемой папке до завершения процесса упаковки!");
	warn_dialog.title = "Внимание";
	warn_dialog.run();
	warn_dialog.destroy();
*/

	// Блокируем интерфейс и запускаем анимацию вращения
	btn_make.set_sensitive(false);
	spinner.start();
	spinner.show();

	// Запускаем долгий процесс в отдельном системном потоке, чтобы не морозить GUI
	new Thread<void*>("backup-worker", () => {
		// Искусственная пауза в 5 секунд для демонстрации спиннера
		// Thread.usleep(5000000);

		string? err_msg = null;
		string backup_file = "";
		string manifest_file = "";

		double time_tar_create = 0.0;
		double time_tar_test = 0.0;
		double time_hash = 0.0;
		double time_total = 0.0;

		var total_timer = new Timer();
		var step_timer = new Timer();

		try {
			var now = new DateTime.now_local();
			string timestamp = now.format("%Y%m%d_%H%M%S");
			backup_file = BACKUP_DIR + "/" + timestamp + ".tar";
			manifest_file = BACKUP_DIR + "/" + timestamp + ".sha256";

			string parent_dir = Path.get_dirname(SRC_DIR);
			string base_dir = Path.get_basename(SRC_DIR);

			// Создание архива с захватом ошибок из stderr
			step_timer.start();
			string[] tar_args = { "tar", "-cvf", backup_file, "-C", parent_dir, base_dir };
			int status;
			string? standard_error = null;
			Process.spawn_sync(null, tar_args, null, SpawnFlags.SEARCH_PATH, null, null, out standard_error, out status);
			step_timer.stop();
			time_tar_create = step_timer.elapsed();

			if (status != 0) {
				err_msg = "Не удалось создать архив." + (standard_error != null && standard_error != "" ? "\n\nДетали: " + standard_error.strip() : "");
				throw new IOError.FAILED(err_msg);
			}

			// Проверка архива с захватом ошибок
			step_timer.start();
			string[] test_args = { "tar", "-tf", backup_file };
			Process.spawn_sync(null, test_args, null, SpawnFlags.SEARCH_PATH, null, null, out standard_error, out status);
			step_timer.stop();
			time_tar_test = step_timer.elapsed();

			if (status != 0) {
				err_msg = "Архив поврежден!" + (standard_error != null && standard_error != "" ? "\n\nДетали: " + standard_error.strip() : "");
				throw new IOError.FAILED(err_msg);
			}

			// Создание хэша безопасно средствами GLib
			step_timer.start();
			string? hash_str = calculate_sha256(backup_file);
			step_timer.stop();
			time_hash = step_timer.elapsed();

			if (hash_str == null) {
				err_msg = "Не удалось вычислить контрольную сумму архива.";
				throw new IOError.FAILED(err_msg);
			}

			string manifest_content = "%s  %s\n".printf(hash_str, Path.get_basename(backup_file));
			FileUtils.set_contents(manifest_file, manifest_content);

			total_timer.stop();
			time_total = total_timer.elapsed();

		} catch (Error e) {
			if (err_msg == null) {
				err_msg = e.message;
			}
		}

		string stats_details = "• Упаковка архива: %.2f сек.\n• Проверка архива: %.2f сек.\n• Расчет хеша (SHA-256): %.2f сек.\n• Общее время: %.2f сек.".printf(
			time_tar_create, time_tar_test, time_hash, time_total
		);

		// Возвращаем управление в главный поток GTK для разблокировки интерфейса и вывода сообщений
		Idle.add(() => {
			// Проверяем, существует ли еще кнопка и родительское окно, чтобы избежать краша
			if (btn_make != null) {
				btn_make.set_sensitive(true);
			}
			if (spinner != null) {
				spinner.stop();
				spinner.hide();
			}

			if (err_msg != null) {
				show_error(parent, "Ошибка", err_msg);
			} else {
				string main_message = "Бекап успешно создан!\n\nАрхив: " + backup_file + "\nМанифест: " + manifest_file;
				show_info_with_stats(parent, "Успех", main_message, stats_details);
				if (on_success != null) {
					on_success();
				}
			}
			return false;
		});

		return null;
	});
}
