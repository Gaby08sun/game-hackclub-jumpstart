class_name GameManager
extends Node2D

const LevelsData = preload("res://data/levels.gd")

@onready var level_loader: Node2D = $LevelLoader
@onready var player: CharacterBody2D = $Player
@onready var hud_label: Label = $HUD/StatsLabel
@onready var win_panel: Control = $HUD/WinPanel
@onready var win_summary_label: Label = $HUD/WinPanel/VBox/SummaryLabel
@onready var retry_button: Button = $HUD/WinPanel/VBox/RetryButton

var current_level_index: int = 0
var death_count: int = 0
var current_spawn_position: Vector2 = Vector2.ZERO
var _busy: bool = false


func _ready() -> void:
	level_loader.level_completed.connect(_on_level_completed)
	level_loader.hazard_hit.connect(_on_player_died)
	player.died.connect(_on_player_died)
	retry_button.pressed.connect(_on_retry_pressed)
	_load_current_level()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		if win_panel.visible:
			_on_retry_pressed()
		else:
			death_count += 1
			_load_current_level()


func _load_current_level() -> void:
	_busy = false
	win_panel.visible = false
	player.set_physics_process(true)
	current_spawn_position = level_loader.load_level(LevelsData.LEVELS[current_level_index])
	player.reset_to(current_spawn_position)
	_update_hud()


func _on_level_completed() -> void:
	if _busy or win_panel.visible:
		return
	_busy = true
	if current_level_index + 1 < LevelsData.LEVELS.size():
		current_level_index += 1
		call_deferred("_load_current_level")
	else:
		call_deferred("_show_win_screen")


func _show_win_screen() -> void:
	_busy = false
	player.set_physics_process(false)
	win_summary_label.text = "You finished all %d levels!\nTotal Deaths: %d" % [
		LevelsData.LEVELS.size(),
		death_count
	]
	win_panel.visible = true
	retry_button.grab_focus()


func _on_retry_pressed() -> void:
	current_level_index = 0
	death_count = 0
	_load_current_level()


func _on_player_died() -> void:
	if _busy or win_panel.visible:
		return
	_busy = true
	death_count += 1
	call_deferred("_respawn_player")


func _respawn_player() -> void:
	_busy = false
	player.reset_to(current_spawn_position)
	_update_hud()


func _update_hud() -> void:
	hud_label.text = "Level: %d / %d\nDeaths: %d" % [
		current_level_index + 1,
		LevelsData.LEVELS.size(),
		death_count
	]
