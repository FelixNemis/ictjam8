extends Node2D


export var squishy = false

var tile_position = Vector2(0, 0)
var target_position = Vector2(0, 0)
var facing_angle = 0
var facing = "down"

var active = false

var r_current_map = null

var UP_ANGLE = PI
var DOWN_ANGLE = 0
var LEFT_ANGLE = PI/2
var RIGHT_ANGLE = PI + PI/2

var MAX_TILE = 40

var TILE = 16

var NON_WALKABLE = []
var NON_GRABBABLE = []
var AUTOTILES : Array = ['puddle', 'wood_wall']

var names
var inv_names

func _ready():
	randomize()
	tile_position.x = round(position.x/TILE)
	tile_position.y = round(position.y/TILE)
	position = tile_position * TILE
	target_position = position

	call_deferred("post_ready")

func post_ready() -> void:
	var r_combinator = get_node("/root/Combinator")
	names = r_combinator.names
	inv_names = r_combinator.inv_names
	
	NON_GRABBABLE = r_combinator.NON_GRABBABLE
	NON_WALKABLE = r_combinator.NON_WALKABLE
	AUTOTILES = r_combinator.AUTOTILES

func spawn(new_tilemap, new_tile_position = false) -> void:
	r_current_map = new_tilemap
	if new_tile_position:
		set_my_positionv(new_tile_position)
	
	set_active(true)

func set_active(new_active : bool) -> void:
	active = new_active

func set_my_positionv(new_tile_position : Vector2):
	tile_position = new_tile_position
	position = tile_position * TILE
	target_position = position

func set_my_position(xpos : int, ypos : int) -> void:
	set_my_positionv(Vector2(xpos, ypos))

func change_facing(direction_h, direction_v = false) -> void:
	var direction = direction_h
	match direction_h:
		'up':
			facing_angle = UP_ANGLE
		'down':
			facing_angle = DOWN_ANGLE
		'left':
			facing_angle = LEFT_ANGLE
		'right':
			facing_angle = RIGHT_ANGLE
		_:
			direction = direction_v
			match direction_v:
				'up':
					facing_angle = UP_ANGLE
				'down':
					facing_angle = DOWN_ANGLE
				_:
					print('not a vertical direction: ' + direction_v)
					return
	facing = direction
	$EntitySprite.set_facing_dir(direction)

func _get_facing_xdelta() -> int:
	if facing == 'up' or facing == 'down':
		return 0
	return 1 if facing == 'right' else -1
func _get_facing_ydelta() -> int:
	if facing == 'left' or facing == 'right':
		return 0
	return 1 if facing == 'down' else -1

func get_facing_tile_coord(amount : int = 1) -> Vector2:
	var facing_c = Vector2(tile_position.x, tile_position.y)
	facing_c.x += _get_facing_xdelta() * amount
	facing_c.y += _get_facing_ydelta() * amount
	return facing_c

func standard_move(direction):
	if not active:
		return
	var new_facing = move_tile(direction)
	change_facing(new_facing)

#returns facing direction
func move_tile(direction_h, direction_v = false) -> String:
	var xd = 0
	var yd = 0
	match direction_h:
		'up':
			yd = -1
		'down':
			yd = 1
		'left':
			xd = -1
		'right':
			xd = 1
		false:
			pass
		_:
			print('not a h direction: ' + direction_h)
			return 'up'
	match direction_v:
		'up':
			yd = -1
		'down':
			yd = 1
		false:
			pass
		_:
			print('not a vertical direction: ' + direction_v)
			return 'up'
	return _move(xd, yd)

func tile_blocks_move(tile):
	return NON_WALKABLE.find(tile) != -1

func delta_to_direction(xdelta, ydelta):
	var direction = ''
	match xdelta:
		1:
			direction = 'right'
		-1:
			direction = 'left'
		0:
			match ydelta:
				1:
					direction = 'down'
				-1:
					direction = 'up'
	return direction

func get_map_cell(x : int, y : int):
	return r_current_map.get_cell(x, y)
func get_map_cellv(v : Vector2):
# warning-ignore:narrowing_conversion
	return get_map_cell(v.x, v.y)

func set_map_cellv(coord : Vector2, index : int) -> void:
	set_map_cell(int(coord.x), int(coord.y), index)

func set_map_cell(x : int, y : int, index : int) -> void:
	var old = r_current_map.get_cell(x, y)
	r_current_map.set_cell(x, y, index)
	if AUTOTILES.has(index) or AUTOTILES.has(old):
		r_current_map.update_bitmask_area(Vector2(x, y))

func _move(xdelta, ydelta) -> String:
	var facing_dir = delta_to_direction(xdelta, ydelta)
	if tile_position.x + xdelta > MAX_TILE or tile_position.x + xdelta < 0:
		xdelta = 0
	if tile_position.y + ydelta > MAX_TILE or tile_position.y + ydelta < 0:
		ydelta = 0

	if xdelta == 0 and ydelta == 0: # hit map edge, no diagonal
		return facing_dir

	facing_dir = delta_to_direction(xdelta, ydelta) #update facing if diagonally along map edge

	tile_position.x += xdelta
	tile_position.y += ydelta

	#can I step here?
	if xdelta != 0 and ydelta != 0:
		var object_dest = get_map_cellv(tile_position)
		var object_vert = get_map_cell(tile_position.x - xdelta, tile_position.y)
		var object_horiz = get_map_cell(tile_position.x, tile_position.y - ydelta)
		if tile_blocks_move(object_horiz) and tile_blocks_move(object_vert):
			tile_position.x -= xdelta
			tile_position.y -= ydelta
			return facing_dir
		if tile_blocks_move(object_dest):
			if tile_blocks_move(object_vert):
				facing_dir = delta_to_direction(xdelta, 0)
				tile_position.y -= ydelta
			else: # move horizontally by default
				facing_dir = delta_to_direction(0, ydelta)
				tile_position.x -= xdelta
	else:
		var object_here = get_map_cellv(tile_position)
		if NON_WALKABLE.find(object_here) != -1:
			tile_position.x -= xdelta
			tile_position.y -= ydelta
			return facing_dir

	target_position.x = tile_position.x * TILE
	target_position.y = tile_position.y * TILE
	#position.x += xdelta * TILE
	#position.y += ydelta * TILE
	return facing_dir

func set_y_stretch(amount: float) -> void:
	$EntitySprite.set_y_stretch(amount)

# warning-ignore:unused_argument
func _process(delta) -> void:
	if not active:
		return

	var x_diff = abs(target_position.x - position.x)
	var y_diff = abs(target_position.y - position.y)
	position = lerp(position, target_position, 24 * delta)

	if squishy:
		var max_stretch = 0.3
		#var diff = (target_position - position).length_squared()
		if x_diff > 0.001 or y_diff > 0.001:
			var stretch_x = x_diff >= y_diff
			var diff = x_diff if stretch_x else y_diff
			var scaled_diff = (max_stretch * (diff/TILE)) + 1
			set_y_stretch(1/scaled_diff if stretch_x else scaled_diff)
		else:
			set_y_stretch(1)

func serialize_for_save() -> Dictionary:
	var serialized = {
		"name": get_name(),
		"mode": 'restore',

		"tile_pos_x": tile_position.x,
		"tile_pos_y": tile_position.y,
		"pos_x": position.x,
		"pos_y": position.y,
		"facing": facing,
		
		"active": active,
	}
	return serialized

func restore_save(serialized, save_version) -> void:
	set_active(serialized['active'])
	change_facing(serialized['facing'])
	set_my_position(serialized['tile_pos_x'], serialized['tile_pos_y'])