extends Node

# Менеджер шрифтов для настройки fallback-шрифта с поддержкой эмодзи
# Обеспечивает корректное отображение эмодзи при экспорте в браузер

# Используем preload для гарантированной загрузки шрифта при экспорте
const EMOJI_FONT: FontFile = preload("res://assets/fonts/NotoColorEmoji.ttf")

var emoji_font: FontFile = null

func _ready() -> void:
	_setup_emoji_font()

func _setup_emoji_font() -> void:
	# Используем preloaded шрифт
	if EMOJI_FONT:
		emoji_font = EMOJI_FONT
	else:
		# Fallback: пробуем загрузить через load()
		var loaded_font := load("res://assets/fonts/NotoColorEmoji.ttf") as FontFile
		if loaded_font:
			emoji_font = loaded_font
		else:
			# Последняя попытка: прямой путь
			var font_file := FontFile.new()
			font_file.load_dynamic_font("res://assets/fonts/NotoColorEmoji.ttf")
			
			if not font_file.data.is_empty():
				emoji_font = font_file
			else:
				push_warning("Не удалось загрузить шрифт эмодзи")
				return
	
	# Применяем fallback-шрифт к глобальному Theme
	_apply_fallback_to_theme()

func _apply_fallback_to_theme() -> void:
	if not emoji_font:
		return
	
	# Получаем глобальный Theme проекта
	var theme := ThemeDB.get_project_theme()
	if not theme:
		theme = Theme.new()
	
	# ПРАВИЛЬНЫЙ ПОДХОД: Сохраняем основной шрифт и добавляем эмодзи только как fallback
	# Настраиваем fallback для всех основных UI элементов
	_setup_font_fallback_for_type(theme, "Button")
	_setup_font_fallback_for_type(theme, "Label")
	_setup_font_fallback_for_type(theme, "LineEdit")
	_setup_font_fallback_for_type(theme, "TextEdit")
	_setup_font_fallback_for_type(theme, "RichTextLabel")
	
	# Настраиваем fallback для default font
	var default_font := theme.get_default_font()
	if default_font:
		var font_with_fallback := _add_emoji_fallback_to_font(default_font)
		if font_with_fallback:
			theme.set_default_font(font_with_fallback)
	else:
		# Если нет default font, создаем FontVariation с эмодзи в fallbacks
		# Но лучше не устанавливать эмодзи как основной
		pass
	
	# Применяем theme к корневому узлу
	_apply_theme_to_scene_tree(theme)

func _setup_font_fallback_for_type(theme: Theme, type: String) -> void:
	# Получаем текущий шрифт для типа (если есть)
	var current_font := theme.get_font("font", type)
	
	# Добавляем эмодзи как fallback к текущему шрифту
	var font_with_fallback := _add_emoji_fallback_to_font(current_font)
	
	if font_with_fallback:
		# Устанавливаем шрифт с fallback в theme
		theme.set_font("font", type, font_with_fallback)

func _add_emoji_fallback_to_font(font: Font) -> Font:
	# Если шрифта нет, возвращаем null (используется дефолтный)
	if not font:
		return null
	
	# Если это FontFile, добавляем эмодзи в fallbacks
	if font is FontFile:
		var font_file := font as FontFile
		# Создаем копию fallbacks и добавляем эмодзи-шрифт
		var fallbacks := font_file.fallbacks.duplicate()
		if not fallbacks.has(emoji_font):
			fallbacks.append(emoji_font)
		font_file.fallbacks = fallbacks
		# Возвращаем тот же FontFile с обновленными fallbacks
		return font_file
	
	# Если это FontVariation, работаем с его base_font
	elif font is FontVariation:
		var font_var := font as FontVariation
		var base_font := font_var.base_font
		
		if base_font is FontFile:
			var base_font_file := base_font as FontFile
			var fallbacks := base_font_file.fallbacks.duplicate()
			if not fallbacks.has(emoji_font):
				fallbacks.append(emoji_font)
			base_font_file.fallbacks = fallbacks
			# Создаем новый FontVariation с обновленным base_font
			var new_variation := FontVariation.new()
			new_variation.base_font = base_font_file
			# Копируем остальные свойства
			new_variation.variation_embolden = font_var.variation_embolden
			new_variation.variation_transform = font_var.variation_transform
			new_variation.variation_opentype = font_var.variation_opentype.duplicate()
			new_variation.opentype_features = font_var.opentype_features.duplicate()
			return new_variation
		else:
			# Если base_font не FontFile, создаем новый FontVariation с эмодзи в fallbacks
			# Но это сложнее, поэтому просто возвращаем исходный
			return font_var
	
	# Для других типов шрифтов возвращаем исходный
	return font

func _apply_theme_to_scene_tree(theme: Theme) -> void:
	# Применяем theme к корневому узлу дерева сцен
	# Это обеспечит применение fallback-шрифта ко всем элементам UI
	var scene_tree := get_tree()
	if scene_tree and theme:
		var root := scene_tree.root
		if root:
			root.theme = theme

func get_emoji_font() -> FontFile:
	return emoji_font
