extends Control

# Скрипт для главного меню

# Ссылки на кнопки
@onready var continue_button: Button = $ButtonsContainer/ContinueButton
@onready var achievements_button: Button = $ButtonsContainer/AchievementsButton
@onready var settings_button: Button = $ButtonsContainer/SettingsButton

func _ready() -> void:
	# Подключение сигналов кнопок
	continue_button.pressed.connect(_on_continue_button_pressed)
	achievements_button.pressed.connect(_on_achievements_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
    
	
	# Проверяем наличие сохранения для кнопки "Продолжить"
	update_continue_button()
	
	# Обновляем текст кнопки звука при запуске
	update_sound_button()

# Обработка нажатия "Продолжить"
func _on_continue_button_pressed() -> void:
	
	# Загружаем сохранение
	SaveSystem.load_game()
	
	# Переходим к игровой сцене
	change_scene_to_game()

func _on_achievements_button_pressed() -> void:
	var panel = load("res://scenes/ui/achievement_panel.tscn").instantiate()
	add_child(panel)
	panel.show()
	if SoundManager:
		SoundManager.play_ui("ui_open")

# Обработка нажатия кнопки звука (переключение)
func _on_settings_button_pressed() -> void:
	if SoundManager:
		var new_state = SoundManager.toggle_sound()
		update_sound_button()



# Переход к игровой сцене
func change_scene_to_game() -> void:
	# Используем change_scene_to_file для перехода к Game сцене
	get_tree().change_scene_to_file("res://scenes/main/game.tscn")

# Обновление состояния кнопки "Продолжить"
func update_continue_button() -> void:
	# Проверяем наличие сохранения
	if SaveSystem.has_save_data():
		continue_button.disabled = false
		continue_button.text = "Продолжить"
	else:
		continue_button.disabled = true
		continue_button.text = "Нет сохранения"

# Обновление текста кнопки звука
func update_sound_button() -> void:
	if SoundManager and SoundManager.get_sound_state():
		settings_button.text = "🔊 Звук ВКЛ"
	else:
		settings_button.text = "🔇 Звук ВЫКЛ"
