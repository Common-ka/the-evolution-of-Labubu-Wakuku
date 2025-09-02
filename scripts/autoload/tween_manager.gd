# TweenManager - универсальный менеджер для управления Tween'ами
# Решает проблемы с устаревшим API Godot 3.x и обеспечивает безопасное управление анимациями

extends Node

# Словарь для хранения Tween'ов по узлам
var node_tweens: Dictionary = {}

# Словарь для хранения глобальных Tween'ов (не привязанных к узлам)
var global_tweens: Array[Tween] = []

# Сигналы для отслеживания состояния
signal tween_started(tween: Tween, node: Node)
signal tween_finished(tween: Tween, node: Node)
signal tween_killed(tween: Tween, node: Node)

func _ready() -> void:
	# Подключаемся к сигналу tree_exiting для автоматической очистки
	tree_exiting.connect(_on_tree_exiting)

# Создает Tween для конкретного узла с дополнительными проверками
func create_tween_for_node(node: Node) -> Tween:
	# Проверяем валидность узла
	if not is_instance_valid(node):
		push_error("[TweenManager] Попытка создать Tween для невалидного узла")
		return null
	
	# Проверяем, что узел находится в дереве сцены
	if not node.is_inside_tree():
		push_warning("[TweenManager] Узел не в дереве сцены: ", node.name)
		return null
	
	# Проверяем, что узел не помечен на удаление
	if node.is_queued_for_deletion():
		push_warning("[TweenManager] Узел помечен на удаление: ", node.name)
		return null
	
	var tween = node.create_tween()
	
	# Привязываем Tween к узлу для автоматической очистки
	tween.bind_node(node)
	
	# Добавляем в словарь
	if not node_tweens.has(node):
		node_tweens[node] = []
	node_tweens[node].append(tween)
	
	# Подключаемся к сигналу завершения
	tween.finished.connect(_on_tween_finished.bind(tween, node))
	
	print("[TweenManager] Создан Tween для узла: ", node.name)
	tween_started.emit(tween, node)
	
	return tween

# Создает глобальный Tween (не привязанный к узлу)
func create_global_tween() -> Tween:
	var tween = get_tree().create_tween()
	global_tweens.append(tween)
	
	print("[TweenManager] Создан глобальный Tween")
	tween_started.emit(tween, null)
	
	return tween

# Безопасное создание Tween с отложенным запуском
func create_delayed_tween_for_node(node: Node, delay: float = 0.1) -> Tween:
	var tween = create_tween_for_node(node)
	if tween:
		# Добавляем небольшую задержку для стабилизации
		tween.set_delay(delay)
	return tween

# Убивает все Tween'ы для конкретного узла
func kill_node_tweens(node: Node) -> void:
	if not node_tweens.has(node):
		return
	
	var tweens = node_tweens[node]
	for tween in tweens:
		if is_instance_valid(tween):
			tween.kill()
			tween_killed.emit(tween, node)
	
	node_tweens.erase(node)
	print("[TweenManager] Убиты все Tween'ы для узла: ", node.name)

# Убивает конкретный Tween
func kill_tween(tween: Tween, node: Node = null) -> void:
	if not is_instance_valid(tween):
		return
	
	# Убираем из глобальных Tween'ов
	var global_index = global_tweens.find(tween)
	if global_index != -1:
		global_tweens.remove_at(global_index)
		tween.kill()
		tween_killed.emit(tween, null)
		return
	
	# Убираем из Tween'ов узла
	if node and node_tweens.has(node):
		var node_tweens_list = node_tweens[node]
		var index = node_tweens_list.find(tween)
		if index != -1:
			node_tweens_list.remove_at(index)
			tween.kill()
			tween_killed.emit(tween, node)
			
			# Если у узла больше нет Tween'ов, убираем его из словаря
			if node_tweens_list.is_empty():
				node_tweens.erase(node)

# Убивает все глобальные Tween'ы
func kill_all_global_tweens() -> void:
	for tween in global_tweens:
		if is_instance_valid(tween):
			tween.kill()
			tween_killed.emit(tween, null)
	
	global_tweens.clear()
	print("[TweenManager] Убиты все глобальные Tween'ы")

# Убивает все Tween'ы в системе
func kill_all_tweens() -> void:
	# Убиваем Tween'ы узлов
	for node in node_tweens.keys():
		if is_instance_valid(node):
			kill_node_tweens(node)
	
	# Убиваем глобальные Tween'ы
	kill_all_global_tweens()
	
	print("[TweenManager] Убиты все Tween'ы в системе")

# Получает количество активных Tween'ов для узла
func get_node_tween_count(node: Node) -> int:
	if not node_tweens.has(node):
		return 0
	return node_tweens[node].size()

# Получает общее количество активных Tween'ов
func get_total_tween_count() -> int:
	var total = global_tweens.size()
	for node in node_tweens.keys():
		if is_instance_valid(node):
			total += node_tweens[node].size()
	return total

# Проверяет, есть ли активные Tween'ы для узла
func has_node_tweens(node: Node) -> bool:
	return node_tweens.has(node) and not node_tweens[node].is_empty()

# Очистка невалидных узлов из словаря
func cleanup_invalid_nodes() -> void:
	var nodes_to_remove: Array[Node] = []
	
	for node in node_tweens.keys():
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			nodes_to_remove.append(node)
	
	for node in nodes_to_remove:
		node_tweens.erase(node)
		print("[TweenManager] Убран невалидный узел: ", node.name if node else "null")

# Обработчик завершения Tween'а
func _on_tween_finished(tween: Tween, node: Node) -> void:
	print("[TweenManager] Tween завершен для узла: ", node.name if node else "глобальный")
	tween_finished.emit(tween, node)
	
	# Убираем завершенный Tween из списков
	if node:
		if node_tweens.has(node):
			var tweens = node_tweens[node]
			var index = tweens.find(tween)
			if index != -1:
				tweens.remove_at(index)
				
				# Если у узла больше нет Tween'ов, убираем его из словаря
				if tweens.is_empty():
					node_tweens.erase(node)
	else:
		# Глобальный Tween
		var index = global_tweens.find(tween)
		if index != -1:
			global_tweens.remove_at(index)

# Обработчик выхода из дерева сцены
func _on_tree_exiting() -> void:
	kill_all_tweens()

# Очистка при уничтожении
func _exit_tree() -> void:
	kill_all_tweens()

# Обработчик процесса для периодической очистки
func _process(_delta: float) -> void:
	# Периодически очищаем невалидные узлы
	if Engine.get_process_frames() % 60 == 0:  # Каждую секунду при 60 FPS
		cleanup_invalid_nodes()
