extends Node

# Система сохранения и загрузки игровых данных

const SAVE_FILE_PATH: String = "user://save_data.json"
const SAVE_VERSION: String = "1.0.0"

# Таймер для автосохранения
var auto_save_timer: Timer
var auto_save_interval: float = 30.0

# Флаги состояния
var is_saving: bool = false
var is_loading: bool = false

func _ready() -> void:
	
	# Инициализация таймера автосохранения
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = auto_save_interval
	auto_save_timer.timeout.connect(_on_auto_save_timer_timeout)
	add_child(auto_save_timer)
	
	# Подключение сигналов
	EventBus.save_requested.connect(_on_save_requested)
	EventBus.load_requested.connect(_on_load_requested)
	EventBus.game_state_changed.connect(_on_game_state_changed)
	
	# Запуск автосохранения
	auto_save_timer.start()

# Сохранение игры
func save_game() -> void:
	if is_saving:
		return
	
	is_saving = true
	
	var save_data: Dictionary = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"game_data": GameManager.get_save_data()
	}
	
	var json_string: String = JSON.stringify(save_data)
	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	
	if file:
		file.store_string(json_string)
		file.close()
		print("Игра сохранена успешно")
		EventBus.emit_signal("save_completed")
	else:
		print("Ошибка при сохранении игры")
	
	is_saving = false

# Загрузка игры
func load_game() -> void:
	if is_loading:
		return
	
	is_loading = true
	
	if not has_save_data():
		print("Файл сохранения не найден")
		is_loading = false
		return
	
	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	
	if file:
		var json_string: String = file.get_as_text()
		file.close()
		
		var json: JSON = JSON.new()
		var parse_result: int = json.parse(json_string)
		
		if parse_result == OK:
			var save_data: Dictionary = json.data
			
			# Проверка версии
			if save_data.get("version", "") != SAVE_VERSION:
				print("Версия сохранения не совпадает, загрузка может быть некорректной")
			
			# Загрузка игровых данных
			var game_data: Dictionary = save_data.get("game_data", {})
			GameManager.load_save_data(game_data)
			
			print("Игра загружена успешно")
			EventBus.emit_signal("load_completed")
		else:
			print("Ошибка при парсинге файла сохранения")
	else:
		print("Ошибка при открытии файла сохранения")
	
	is_loading = false

# Проверка наличия сохранения
func has_save_data() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

# Удаление сохранения
func delete_save_data() -> void:
	if has_save_data():
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		print("Сохранение удалено")

# Получение информации о сохранении
func get_save_info() -> Dictionary:
	if not has_save_data():
		return {}
	
	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	
	if file:
		var json_string: String = file.get_as_text()
		file.close()
		
		var json: JSON = JSON.new()
		var parse_result: int = json.parse(json_string)
		
		if parse_result == OK:
			var save_data: Dictionary = json.data
			return {
				"version": save_data.get("version", ""),
				"timestamp": save_data.get("timestamp", 0),
				"game_data": save_data.get("game_data", {})
			}
	
	return {}

# Экспорт сохранения
func export_save_data() -> String:
	if not has_save_data():
		return ""
	
	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	
	if file:
		var content: String = file.get_as_text()
		file.close()
		return content
	
	return ""

# Импорт сохранения
func import_save_data(json_string: String) -> bool:
	var json: JSON = JSON.new()
	var parse_result: int = json.parse(json_string)
	
	if parse_result == OK:
		var save_data: Dictionary = json.data
		
		# Проверка структуры
		if not save_data.has("version") or not save_data.has("game_data"):
			print("Неверный формат файла сохранения")
			return false
		
		# Сохранение импортированных данных
		var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
		
		if file:
			file.store_string(json_string)
			file.close()
			print("Сохранение импортировано успешно")
			return true
		else:
			print("Ошибка при импорте сохранения")
			return false
	else:
		print("Ошибка при парсинге импортируемого файла")
		return false

# Сигналы
func _on_save_requested() -> void:
	save_game()

func _on_load_requested() -> void:
	load_game()

func _on_game_state_changed() -> void:
	# Автосохранение при изменении состояния игры
	# (может быть отключено для частых изменений)
	pass

func _on_auto_save_timer_timeout() -> void:
	# Автосохранение каждые 30 секунд
	if not is_saving and not is_loading:
		save_game()
