class_name LevelLoader
extends Node2D

signal level_completed
signal hazard_hit

const TILE_SIZE: int = 32

@export var block_texture: Texture2D
@export var door_texture: Texture2D
@export var spike_texture: Texture2D

@onready var tile_map_layer: TileMapLayer = $TileMapLayer

var _entities: Array[Area2D] = []


func _ready() -> void:
	tile_map_layer.tile_set = _build_tile_set()


func load_level(grid: Array) -> Vector2:
	if tile_map_layer.tile_set == null:
		tile_map_layer.tile_set = _build_tile_set()

	tile_map_layer.clear()
	for area in _entities:
		if is_instance_valid(area):
			area.set_deferred("monitoring", false)
			area.queue_free()
	_entities.clear()

	var spawn := Vector2(48.0, 48.0)
	for y in range(grid.size()):
		var row: String = grid[y]
		for x in range(row.length()):
			var pos := Vector2(x * TILE_SIZE + 16.0, y * TILE_SIZE + 16.0)
			match row[x]:
				"#":
					tile_map_layer.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
				"P":
					spawn = pos
				"D":
					_spawn_door(pos)
				"^":
					_spawn_spike(pos)
	return spawn


func _build_tile_set() -> TileSet:
	var img: Image
	if block_texture != null:
		img = block_texture.get_image()
		img.resize(TILE_SIZE, TILE_SIZE)
	else:
		img = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.24, 0.28, 0.36))
	var tex := ImageTexture.create_from_image(img)

	var atlas := TileSetAtlasSource.new()
	atlas.texture = tex
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	atlas.create_tile(Vector2i.ZERO)

	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	ts.add_physics_layer(0)
	ts.add_source(atlas, 0)

	var tile_data: TileData = atlas.get_tile_data(Vector2i.ZERO, 0)
	tile_data.add_collision_polygon(0)
	tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16)
	]))
	return ts


func _spawn_door(pos: Vector2) -> void:
	var door := _create_area(
		pos,
		Vector2(24, 30),
		Vector2.ZERO,
		door_texture,
		PackedVector2Array([Vector2(-12, -15), Vector2(12, -15), Vector2(12, 15), Vector2(-12, 15)]),
		Color(0.25, 0.9, 0.45)
	)
	door.body_entered.connect(func(body: Node2D) -> void:
		if body is CharacterBody2D:
			level_completed.emit()
	)


func _spawn_spike(pos: Vector2) -> void:
	var spike := _create_area(
		pos,
		Vector2(20, 14),
		Vector2(0, 9),
		spike_texture,
		PackedVector2Array([Vector2(-14, 16), Vector2(0, -10), Vector2(14, 16)]),
		Color(0.95, 0.25, 0.3)
	)
	spike.body_entered.connect(func(body: Node2D) -> void:
		if body is CharacterBody2D:
			hazard_hit.emit()
			if body.has_method("die"):
				body.die()
	)


func _create_area(pos: Vector2, hit_size: Vector2, hit_offset: Vector2, tex: Texture2D, poly: PackedVector2Array, color: Color) -> Area2D:
	var area := Area2D.new()
	area.position = pos

	var shape := RectangleShape2D.new()
	shape.size = hit_size
	var col := CollisionShape2D.new()
	col.position = hit_offset
	col.shape = shape
	area.add_child(col)

	if tex != null:
		var sprite := Sprite2D.new()
		sprite.texture = tex
		var s := tex.get_size()
		if s.x > 0 and s.y > 0:
			sprite.scale = Vector2(TILE_SIZE / s.x, TILE_SIZE / s.y)
		area.add_child(sprite)
	else:
		var visual := Polygon2D.new()
		visual.polygon = poly
		visual.color = color
		area.add_child(visual)

	add_child(area)
	_entities.append(area)
	return area
