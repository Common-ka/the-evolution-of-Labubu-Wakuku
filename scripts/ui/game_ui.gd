extends Node2D

# Скрипт для UI игровой сцены

# Ссылки на UI элементы
@onready var currency_display: Label = $UI/HUD/CurrencyDisplay
@onready var level_display: Label = $UI/HUD/LevelDisplay
@onready var menu_button: Button = $UI/HUD/MenuButton
@onready var shop_button: Button = $UI/HUD/ShopButton

var _display_currency: int = 0
var _value_tween: Tween
var _pulse_tween: Tween
var _color_tween: Tween
const VALUE_ANIM_DURATION := 0.25
const PULSE_SCALE := 1.08
const PULSE_DURATION := 0.12
const COLOR_FLASH := Color(1.0, 0.88, 0.25)
const COLOR_DURATION := 0.18
var _base_color: Color

func _ready() -> void:
	# Подключение сигналов
	menu_button.pressed.connect(_on_menu_button_pressed)
	shop_button.pressed.connect(_on_shop_button_pressed)
	
	# Подключение сигналов GameManager для обновления UI
	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.level_up.connect(_on_level_up)
	
	# Инициализация UI
	_display_currency = GameManager.current_currency
	_base_color = currency_display.modulate
	update_currency_display()
	update_level_display()
	
	# Отладочная информация о HUD
	print("Game UI: HUD размеры - ", $UI/HUD.size)
	print("Game UI: HUD позиция - ", $UI/HUD.position)
	print("Game UI: HUD mouse_filter - ", $UI/HUD.mouse_filter)

# Обработка нажатия кнопки "Меню"
func _on_menu_button_pressed() -> void:
	print("Возвращаемся в главное меню")
	
	# Сохраняем игру перед выходом
	SaveSystem.save_game()
	
	# Переходим обратно в главное меню
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

# Открытие магазина
func _on_shop_button_pressed() -> void:
	var shop_scene: PackedScene = load("res://scenes/ui/shop_panel.tscn")
	var shop: Control = shop_scene.instantiate()
	$UI.add_child(shop)

# Обновление отображения валюты
func update_currency_display() -> void:
	currency_display.text = "Валюты: " + str(_display_currency)

# Обновление отображения уровня
func update_level_display() -> void:
	level_display.text = "Уровень: " + str(GameManager.current_level)

# Обработчики сигналов
func _on_currency_changed(new_amount: int) -> void:
	_animate_currency_change(new_amount)

func _animate_currency_change(target_amount: int) -> void:
	"""Interpolates numeric label, pulses scale and flashes color on change."""
	# Value interpolation
	if _value_tween:
		_value_tween.kill()
	_value_tween = create_tween()
	_value_tween.tween_method(_update_display_currency, float(_display_currency), float(target_amount), VALUE_ANIM_DURATION)

	# Scale pulse
	if _pulse_tween:
		_pulse_tween.kill()
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(currency_display, "scale", Vector2(PULSE_SCALE, PULSE_SCALE), PULSE_DURATION).set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_property(currency_display, "scale", Vector2.ONE, PULSE_DURATION).set_ease(Tween.EASE_IN)

	# Color flash
	if _color_tween:
		_color_tween.kill()
	_color_tween = create_tween()
	_color_tween.set_parallel(true)
	_color_tween.tween_property(currency_display, "modulate", COLOR_FLASH, COLOR_DURATION).set_ease(Tween.EASE_OUT)
	_color_tween.tween_property(currency_display, "modulate", _base_color, COLOR_DURATION).set_delay(COLOR_DURATION).set_ease(Tween.EASE_IN)

func _update_display_currency(value: float) -> void:
	var v: int = int(round(value))
	if v == _display_currency:
		return
	_display_currency = v
	update_currency_display()

func _on_level_up(new_level: int) -> void:
	update_level_display()

# Отладочная обработка всех событий ввода
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("Game UI: Получен клик мыши в позиции ", event.position, " кнопка ", event.button_index)
		
		# Проверяем, попадает ли клик в область HUD
		var hud_rect = Rect2($UI/HUD.position, $UI/HUD.size)
		if hud_rect.has_point(event.position):
			print("Game UI: Клик попал в область HUD")
		else:
			print("Game UI: Клик НЕ попал в область HUD")
