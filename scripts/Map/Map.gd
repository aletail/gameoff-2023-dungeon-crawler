class_name Map extends Node2D

# Used for path finding
var astar_grid:AStarGrid2D = AStarGrid2D.new()

# Map generation variables
var cell_size:Vector2 = Vector2i(64, 64)
var grid_size:Vector2 = Vector2i(10, 10)
var iterations:int = 40000
var neighbors:int = 4
var ground_chance:int = 44
var min_cave_size:int = 40
var caves:Array = []
var cave_object_list:Array = []

# Stores all tiles
var tile_list_array:Array = []
var tile_weight_update:Array = []

func _init(cellsize, gridsize):
	cell_size = cellsize
	grid_size = gridsize

func _ready():
	initialize_grid()
	
	# Create tiles
	var tscene = load("res://Scenes/Map/Tile.tscn")
	for x in grid_size.x:
		tile_list_array.append([])
		for y in grid_size.y:
			var t = tscene.instantiate();
			t.get_node("StaticBody2D/CollisionShape2D").disabled = true
			t.mapx = x
			t.mapy = y
			t.position = convert_to_global(Vector2(x, y))
			var rng = RandomNumberGenerator.new()
			rng.randomize()
			t.get_node("StaticBody2D/AnimatedSprite2D").set_frame(rng.randi_range(1, 8))
			add_child(t)
			tile_list_array[x].append(0)
			tile_list_array[x][y] = t
			
	# Generates Map
	fill_roof()
	random_ground()
	dig_caves()
	get_caves()
	connect_caves()
	
	# Update grid with solid positions
	for x in grid_size.x:
		for y in grid_size.y:
			if tile_list_array[x][y].type == "roof":
				tile_list_array[x][y].get_node("StaticBody2D/CollisionShape2D").disabled = false
				tile_list_array[x][y].get_node("StaticBody2D/AnimatedSprite2D").set_frame(0)
				astar_grid.set_point_solid(Vector2(tile_list_array[x][y].mapx, tile_list_array[x][y].mapy), true)

# 
func get_spawn_point():
	for x in range(0, grid_size.x):
		for y in range(0, grid_size.y):
			if tile_list_array[x][y].type == "ground":
				return tile_list_array[x][y].position

# Returns the first off screen point found from inbound position
func get_offscreen_spawn_point(pos:Vector2, cave_id:int):
	pos = Vector2(pos) / cell_size
	
#	for x in range(pos.x, grid_size.x):
#		for y in range(pos.y, grid_size.y):
#			var t = get_tile(Vector2(x, y-1))
#			if tile_list_array[x][y-1].get_node("VisibleOnScreenNotifier2D").is_on_screen()==false:
#				if tile_list_array[x][y-1].type == "ground":
#					return tile_list_array[x][y-1].position
	for tile in caves[cave_id-1]:
		var d = pos.distance_to(tile_list_array[tile.x][tile.y].position)
		if(d > 50):
			#print("Ideal Spawn")
			#print(tile_list_array[tile.x][tile.y].position)
			return tile_list_array[tile.x][tile.y].position

	
#	pos = Vector2(pos) / cell_size
#	for x in range(0, grid_size.x):
#		for y in range(0, grid_size.y):
#			if tile_list_array[x][y].type == "ground" and tile_list_array[x][y].cave_id == cave_id:
#				var d = pos.distance_to(tile_list_array[x][y].position)
#				if(d < 50):
#					print("Ideal Spawn")
#					return tile_list_array[x][y].position
#
#	for x in range(pos.x, grid_size.x):
#		for y in range(pos.y, grid_size.y):
#			if tile_list_array[x][y].type == "ground":
#				if tile_list_array[x][y].get_node("VisibleOnScreenNotifier2D").is_on_screen()==false:
#					return tile_list_array[x][y].position
	
	
	
# Returns the type of tile, nothing if not found
func get_tile_type(x:int, y:int):
	if(astar_grid.is_in_bounds(x, y)):
		return tile_list_array[x][y].type
	else:
		return ""
	
# Sets all tiles type to roof
func fill_roof():
	for x in range(0, grid_size.x):
		for y in range(0, grid_size.y):
			tile_list_array[x][y].set_type("roof")
		
# Randomly sets a tile to a ground tile type	
func random_ground():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var noise = FastNoiseLite.new()
	noise.noise_type = 3
	noise.frequency = rng.randf_range(0.01, 0.1) # 0.07
	noise.fractal_octaves = rng.randi_range(1, 20) # 5
	for x in range(1, grid_size.x-1):
		for y in range(1, grid_size.y-1):
			var n = noise.get_noise_2d(x, y)
			if(n < 0):
				tile_list_array[x][y].set_type("ground")
#
func dig_caves():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(iterations):
		# Pick a random point with a 1-tile buffer within the map
		var x = floor(rng.randi_range(1, grid_size.x-1))
		var y = floor(rng.randi_range(1, grid_size.y-1))

		# if nearby cells > neighbors, make it a roof tile
		if check_nearby(x,y) > neighbors:
			tile_list_array[x][y].set_type("roof")

		# or make it the ground tile
		elif check_nearby(x,y) < neighbors:
			tile_list_array[x][y].set_type("ground")
#
func check_nearby(x:int, y:int):
	var count = 0
	if get_tile_type(x, y-1) == "roof":  count += 1
	if get_tile_type(x, y+1) == "roof":  count += 1
	if get_tile_type(x-1, y) == "roof":  count += 1
	if get_tile_type(x+1, y) == "roof":  count += 1
	if get_tile_type(x+1, y+1) == "roof":  count += 1
	if get_tile_type(x+1, y-1) == "roof":  count += 1
	if get_tile_type(x-1, y+1) == "roof":  count += 1
	if get_tile_type(x-1, y-1) == "roof":  count += 1
	return count

func get_nearby_ground(x:int, y:int):
	var t = get_tile_type(x, y-1)
	var tile = null
	if t == "ground":  
		return get_tile(Vector2(x, y-1))
	
	t = get_tile_type(x, y+1)
	if t == "ground":  
		return get_tile(Vector2(x, y+1))
	
	t = get_tile_type(x-1, y)
	if t == "ground":
		return get_tile(Vector2(x-1, y))
		
	t = get_tile_type(x+1, y) 
	if t == "ground":  
		return get_tile(Vector2(x+1, y))
		
	t = get_tile_type(x+1, y+1)
	if t == "ground":
		return get_tile(Vector2(x+1, y+1))
		
	t = get_tile_type(x+1, y-1)
	if t == "ground":
		return get_tile(Vector2(x+1, y-1))
		
	t = get_tile_type(x-1, y+1)
	if t == "ground":
		return get_tile(Vector2(x-1, y+1))
		
	t = get_tile_type(x-1, y-1)
	if t == "ground":
		return get_tile(Vector2(x-1, y-1))
		
	return null

#
func get_caves():
	caves = []

	for x in range (0, grid_size.x):
		for y in range (0, grid_size.y):
			if tile_list_array[x][y].type == "ground":
				flood_fill(x,y)
	
	var count = 0
	for cave in caves:
		var cave_object = Cave.new()
		cave_object.id = count
		cave_object_list.push_back(cave_object)
		count+=1
		for tile in cave:
			tile_list_array[tile.x][tile.y].type = "ground"
			tile_list_array[tile.x][tile.y].cave_id = count
			
#
func flood_fill(tilex, tiley):
	var cave = []
	var to_fill = [Vector2(tilex, tiley)]
	while to_fill:
		var tile = to_fill.pop_back()

		if !cave.has(tile):
			cave.append(tile)
			tile_list_array[tile.x][tile.y].type = "roof"

			#check adjacent cells
			var north = Vector2(tile.x, tile.y-1)
			var south = Vector2(tile.x, tile.y+1)
			var east  = Vector2(tile.x+1, tile.y)
			var west  = Vector2(tile.x-1, tile.y)

			for dir in [north,south,east,west]:
				if get_tile_type(dir.x, dir.y) == "ground":
					if !to_fill.has(dir) and !cave.has(dir):
						to_fill.append(dir)

	if cave.size() >= min_cave_size:
		caves.append(cave)
		
#	
func connect_caves():
	var prev_cave = null
	var tunnel_caves = caves.duplicate()

	for cave in tunnel_caves:
		if prev_cave:
			var new_point  = choose(cave)
			var prev_point = choose(prev_cave)

			# ensure not the same point
			if new_point != prev_point:
				create_tunnel(new_point, prev_point, cave)

		prev_cave = cave
		
# do a drunken walk from point1 to point2
func create_tunnel(point1, point2, cave):
	randomize()          # for randf
	var max_steps = 500  # so editor won't hang if walk fails
	var steps = 0
	var drunk_x = point2[0]
	var drunk_y = point2[1]
	
	while steps < max_steps and !cave.has(Vector2(drunk_x, drunk_y)):
		steps += 1

		# set initial dir weights
		var n       = 1.0
		var s       = 1.0
		var e       = 1.0
		var w       = 1.0
		var weight  = 1

		# weight the random walk against edges
		if drunk_x < point1.x: # drunkard is left of point1
			e += weight
		elif drunk_x > point1.x: # drunkard is right of point1
			w += weight
		if drunk_y < point1.y: # drunkard is above point1
			s += weight
		elif drunk_y > point1.y: # drunkard is below point1
			n += weight

		# normalize probabilities so they form a range from 0 to 1
		var total = n + s + e + w
		n /= total
		s /= total
		e /= total
		w /= total

		var dx
		var dy

		# choose the direction
		var choice = randf()

		if 0 <= choice and choice < n:
			dx = 0
			dy = -1
		elif n <= choice and choice < (n+s):
			dx = 0
			dy = 1
		elif (n+s) <= choice and choice < (n+s+e):
			dx = 1
			dy = 0
		else:
			dx = -1
			dy = 0

		# ensure not to walk past edge of map
		if (2 < drunk_x + dx and drunk_x + dx < grid_size.x-2) and \
			(2 < drunk_y + dy and drunk_y + dy < grid_size.y-2):
			drunk_x += dx
			drunk_y += dy
			if tile_list_array[drunk_x][drunk_y].type == "roof":
				tile_list_array[drunk_x][drunk_y].type = "ground"
	
	# Check if tunnel was created, if not use a simple path to forge a tunnel
	if steps >= 500:
		var tunnel_path = find_path(point1, point2)
		for t in tunnel_path:
			var mt = Vector2(t / cell_size)
			if tile_list_array[mt.x][mt.y].type == "roof":
				tile_list_array[mt.x][mt.y].type = "ground"
		
				
# Util.choose(["one", "two"])   returns one or two
func choose(choices):
	randomize()

	var rand_index = randi() % choices.size()
	return choices[rand_index]

# 
func initialize_grid():
	astar_grid.size = grid_size
	astar_grid.cell_size = cell_size
	astar_grid.offset = cell_size / 2
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar_grid.update()
	
func draw_grid():
	for x in grid_size.x + 1:
		draw_line(Vector2(x * cell_size.x, 0), Vector2(x * cell_size.x, grid_size.y * cell_size.y), Color.DARK_GRAY, 2.0)
	for y in grid_size.y + 1:
		draw_line(Vector2(0, y * cell_size.y), Vector2(grid_size.x * cell_size.x, y * cell_size.y), Color.DARK_GRAY, 2.0)

func fill_walls():
	for x in grid_size.x:
		for y in grid_size.y:
			if astar_grid.is_point_solid(Vector2i(x, y)):
				draw_rect(Rect2(x * cell_size.x, y * cell_size.y, cell_size.x, cell_size.y), Color.DARK_GRAY)
			
# Turns a point on the grid to not solid	
func make_ground(v:Vector2):
	astar_grid.set_point_solid(v, false)

# Adds weight to the selected point
func add_tile_weight(v:Vector2):
	var nv = Vector2(v / cell_size)
	if(astar_grid.is_in_boundsv(nv)):
		tile_weight_update.push_back([nv, 0.1])
		
# Subtracts weight from the selected point
func subtract_tile_weight(v:Vector2):
	var nv = Vector2(v / cell_size)
	if(astar_grid.is_in_boundsv(nv)):
		tile_weight_update.push_back([nv, -0.1])

# Reset all tile weights to zero		
func reset_tile_weights():
	for x in grid_size.x:
		for y in grid_size.y:
			if !astar_grid.is_point_solid(Vector2i(x, y)):
				astar_grid.set_point_weight_scale(Vector2(x, y), 0)

# Process the queue of tile weight updates				
func process_tile_weight_updates():
	for t in tile_weight_update:
		var current_weight = astar_grid.get_point_weight_scale(t[0]) + t[1]
		astar_grid.set_point_weight_scale(t[0], current_weight)
		
	tile_weight_update.clear()
	
# Find Path
func find_path(start, end):
	if astar_grid.is_in_boundsv(start) and astar_grid.is_in_boundsv(end):
		var r = PackedVector2Array(astar_grid.get_point_path(start, end))
		if(r):
			return r
		else:
			#print("path not found")
			return []
	else:
		return []
	
func get_tile(v:Vector2):
	var pos = Vector2(v)/cell_size
	if pos.x < grid_size.x and pos.y < grid_size.y:
		return tile_list_array[pos.x][pos.y]
	
func convert_to_global(pos):
	return Vector2((pos.x * cell_size.x) + (cell_size.x/2), (pos.y * cell_size.y) + (cell_size.y/2))
