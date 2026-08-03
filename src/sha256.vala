using GLib;

/**
 * @brief Безопасный расчет SHA-256 хэша средствами GLib
 * file_path - путь к файлу
 * return - строковое представление хэша или null при ошибке
 */
public string? calculate_sha256(string file_path) {
	try {
		var file = File.new_for_path(file_path);
		if (!file.query_exists()) return null;
		var dis = new DataInputStream(file.read());
		var checksum = new Checksum(ChecksumType.SHA256);
		uint8[] buffer = new uint8[8192];
		size_t bytes_read;
		while ((bytes_read = dis.read(buffer, null)) > 0) {
			checksum.update(buffer, bytes_read);
		}
		return checksum.get_string();
	} catch (Error e) {
		return null;
	}
}
