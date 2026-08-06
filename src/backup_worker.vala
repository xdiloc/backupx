using Gtk;

/**
 * @brief Запуск процесса создания бэкапа в отдельном фоновом потоке с хэшированием на лету
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
		double time_total = 0.0;

		var total_timer = new Timer();
		var step_timer = new Timer();
		total_timer.start();

		try {
			var now = new DateTime.now_local();
			string timestamp = now.format("%Y%m%d_%H%M%S");
			backup_file = BACKUP_DIR + "/" + timestamp + ".tar";
			manifest_file = BACKUP_DIR + "/" + timestamp + ".sha256";

			string parent_dir = Path.get_dirname(SRC_DIR);
			string base_dir = Path.get_basename(SRC_DIR);

			// Создание архива и расчет хэша на лету (в один проход)
			step_timer.start();
			string[] tar_args = { "tar", "-cf", "-", "-C", parent_dir, base_dir };

			int std_out_fd, std_err_fd;
			Pid pid;
			Process.spawn_async_with_pipes(null, tar_args, null, SpawnFlags.SEARCH_PATH, null, out pid, null, out std_out_fd, out std_err_fd);

			var checksum = new Checksum(ChecksumType.SHA256);
			var file = File.new_for_path(backup_file);
			var fos = file.replace(null, false, FileCreateFlags.NONE, null);

			uint8[] buffer = new uint8[65536];
			ssize_t bytes_read;
			while ((bytes_read = Posix.read(std_out_fd, buffer, buffer.length)) > 0) {
				fos.write(buffer[0:(size_t)bytes_read], null);
				checksum.update(buffer, (size_t)bytes_read);
			}
			fos.close(null);
			Posix.close(std_out_fd);

			// Читаем stderr через POSIX
			StringBuilder err_builder = new StringBuilder();
			ssize_t err_bytes;
			while ((err_bytes = Posix.read(std_err_fd, buffer, buffer.length)) > 0) {
				for (int i = 0; i < err_bytes; i++) {
					err_builder.append_c((char)buffer[i]);
				}
			}
			Posix.close(std_err_fd);
			string? standard_error = err_builder.len > 0 ? err_builder.str.strip() : null;

			int status;
			Posix.waitpid(pid, out status, 0);

			step_timer.stop();
			time_tar_create = step_timer.elapsed();

			if (status != 0) {
				err_msg = "Не удалось создать архив." + (standard_error != null && standard_error != "" ? "\n\nДетали: " + standard_error : "");
				throw new IOError.FAILED(err_msg);
			}

			// Проверка архива с захватом ошибок
			step_timer.start();
			string[] test_args = { "tar", "-tf", backup_file };
			int test_status;
			string? test_stdout = null;
			string? test_stderr = null;
			Process.spawn_sync(null, test_args, null, SpawnFlags.SEARCH_PATH, null, out test_stdout, out test_stderr, out test_status);
			step_timer.stop();
			time_tar_test = step_timer.elapsed();

			if (test_status != 0) {
				err_msg = "Архив поврежден!" + (test_stderr != null && test_stderr != "" ? "\n\nДетали: " + test_stderr.strip() : "");
				throw new IOError.FAILED(err_msg);
			}

			string? hash_str = checksum.get_string();
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

		string stats_details = "• Упаковка архива (с хэшем): %s\n• Проверка архива: %s\n• Общее время: %s".printf(
			format_elapsed_time(time_tar_create),
			format_elapsed_time(time_tar_test),
			format_elapsed_time(time_total)
		);

		// Возвращаем управление в главный поток GTK для разблокировки интерфейса и вывода сообщений
		Idle.add(() => {
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
