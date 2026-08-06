using Gtk;

class BackupApp : Window {
	private BackupTab backup_tab;
	private VerifyTab verify_tab;

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

	public static int main (string[] args) {
		Gtk.init (ref args);

		// Загружаем настройки путей в самом начале работы программы
		load_settings();

		var app = new BackupApp ();
		app.show_all ();
		Gtk.main ();
		return 0;
	}
}
