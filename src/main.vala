using Gtk;
using GLib;
using Posix;

class BackupApp : Window {
	private BackupTab backup_tab;
	private VerifyTab verify_tab;

	/**
	 * @brief Создание главного окна приложения
	 */
	public BackupApp () {
		this.title = "Менеджер бэкапов";
		this.set_default_size(600, 300);

		// Подключаем перехват закрытия окна
		this.delete_event.connect(on_delete_event);
		this.destroy.connect(Gtk.main_quit);

		var notebook = new Notebook();

		var home_tab = new HomeTab(this);
		this.verify_tab = new VerifyTab(this);

		this.backup_tab = new BackupTab(this, () => {
			verify_tab.refresh_backups();
			backup_tab.update_free_space();
		});

		notebook.append_page(backup_tab, new Label("Создание"));
		notebook.append_page(verify_tab, new Label("Проверка"));
		notebook.append_page(home_tab, new Label("Справка"));

		this.add(notebook);
	}

	/**
	 * @brief Обработчик попытки закрытия окна
	 * event - событие закрытия окна
	 */
	private bool on_delete_event(Gdk.EventAny event) {
		if (backup_tab.is_busy()) {
			show_warning(this, "Внимание", "В данный момент выполняется архивация. Пожалуйста, дождитесь завершения процесса.");
			return true; // Блокируем закрытие
		}

		if (verify_tab.is_busy()) {
			show_warning(this, "Внимание", "В данный момент выполняется проверка целостности архива. Пожалуйста, дождитесь завершения процесса.");
			return true; // Блокируем закрытие
		}

		return false; // Разрешаем закрытие, если задач нет
	}

	/**
	 * @brief Проверка запуска второй копии приложения с защитой от PID recycling через /proc
	 * lock_path - путь к файлу блокировки
	 */
	private static int check_single_instance (string lock_path) {
		int fd = Posix.open(lock_path, Posix.O_CREAT | Posix.O_EXCL | Posix.O_RDWR, 0600);
		if (fd != -1) {
			return fd;
		}

		int old_fd = Posix.open(lock_path, Posix.O_RDONLY);
		if (old_fd == -1) {
			Posix.unlink(lock_path);
			return Posix.open(lock_path, Posix.O_CREAT | Posix.O_EXCL | Posix.O_RDWR, 0600);
		}

		char[] buf = new char[32];
		ssize_t read_bytes = Posix.read(old_fd, buf, buf.length - 1);
		Posix.close(old_fd);

		if (read_bytes <= 0) {
			Posix.unlink(lock_path);
			return Posix.open(lock_path, Posix.O_CREAT | Posix.O_EXCL | Posix.O_RDWR, 0600);
		}

		buf[read_bytes] = '\0';
		int old_pid = int.parse((string) buf);
		if (old_pid <= 0) {
			Posix.unlink(lock_path);
			return Posix.open(lock_path, Posix.O_CREAT | Posix.O_EXCL | Posix.O_RDWR, 0600);
		}

		if (Posix.kill(old_pid, 0) == -1 && Posix.errno == Posix.ESRCH) {
			Posix.unlink(lock_path);
			return Posix.open(lock_path, Posix.O_CREAT | Posix.O_EXCL | Posix.O_RDWR, 0600);
		}

		string cmdline;
		try {
			if (!FileUtils.get_contents("/proc/%d/cmdline".printf(old_pid), out cmdline)) {
				Posix.unlink(lock_path);
				return Posix.open(lock_path, Posix.O_CREAT | Posix.O_EXCL | Posix.O_RDWR, 0600);
			}
			if (!cmdline.contains("backupx")) {
				Posix.unlink(lock_path);
				return Posix.open(lock_path, Posix.O_CREAT | Posix.O_EXCL | Posix.O_RDWR, 0600);
			}
		} catch (FileError e) {
			Posix.unlink(lock_path);
			return Posix.open(lock_path, Posix.O_CREAT | Posix.O_EXCL | Posix.O_RDWR, 0600);
		}

		return -1;
	}

	/**
	 * @brief Точка входа в приложение
	 * args - аргументы командной строки
	 */
	public static int main (string[] args) {
		Gtk.init (ref args);

		string lock_path = "/tmp/backupx.lock";

		int fd = check_single_instance(lock_path);
		if (fd == -1) {
			show_warning(null, "Внимание", "Приложение уже запущено!");
			return 0;
		}

		string pid = ((int) Posix.getpid()).to_string();
		Posix.write(fd, pid, pid.length);
		Posix.close(fd);

		// Загружаем настройки путей в самом начале работы программы
		load_settings();

		var app = new BackupApp ();
		app.show_all ();
		Gtk.main ();

		// Удаляем файл блокировки при штатном выходе
		Posix.unlink(lock_path);
		return 0;
	}
}
