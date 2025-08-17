extends Node

# Глобальная система событий для коммуникации между компонентами игры

# Игровые события
signal click_performed(amount: int)
signal currency_changed(new_amount: int)
signal level_up(new_level: int)

# Системные события
signal upgrade_purchased(upgrade_id: String)
signal achievement_unlocked(achievement_id: String)
signal game_state_changed

# UI события
signal menu_requested
signal settings_requested
signal start_game_requested
signal continue_game_requested

# Сохранение
signal save_requested
signal load_requested
signal save_completed
signal load_completed

# Звуковые события
signal play_sound(sound_name: String)
signal play_music(music_name: String)
signal stop_music

# Достижения
signal achievement_progress_updated(achievement_id: String, progress: float)
signal achievement_condition_met(achievement_id: String)

# Апгрейды
signal upgrade_available(upgrade_id: String)
signal upgrade_unavailable(upgrade_id: String)
signal upgrade_effect_applied(upgrade_id: String, effect_value: float)
