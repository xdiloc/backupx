using Gtk;

class BackupApp : Window {
	public BackupApp () {
		this.title = "Менеджер бэкапов";
		this.set_default_size(600, 300);
		this.destroy.connect(Gtk.main_quit);

		var notebook = new Notebook();

		var home_tab = new HomeTab(this);
		var verify_tab = new VerifyTab(this);

		BackupTab backup_tab = null;
		backup_tab = new BackupTab(this, () => {
			verify_tab.refresh_backups();
			backup_tab.update_free_space();
		});

		notebook.append_page(backup_tab, new Label("Создание"));
		notebook.append_page(verify_tab, new Label("Проверка"));
		notebook.append_page(home_tab, new Label("Справка"));

		this.add(notebook);
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
