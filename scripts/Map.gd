class_name Map extends Node2D

var astar_grid = AStarGrid2D.new()
var cell_size = Vector2i(64, 64)
var grid_size = Vector2i(10, 10)

var iterations    = 40000
var neighbors     = 4
var ground_chance = 44
var min_cave_size = 80
var caves = []

var tile_list_array = []

func _init(cellsize, gridsize):
	cell_size = cellsize
	grid_size = gridsize

func _ready():
	initialize_grid()
	
	# Create tiles
	var tscene = load("res://Scenes/Tile/Tile.tscn")
	for x in grid_size.x:
		tile_list_array.append([])
		for y in grid_size.y:
			var t = tscene.instantiate();
			t.get_node("StaticBody2D/Sprite2D").modulate = Color(131/255.0, 121/255.0, 110/255.0)
			t.get_node("StaticBody2D/CollisionShape2D").disabled = true
			t.mapx = x
			t.mapy = y
			t.position = ConvertToGlobal(Vector2(x, y))
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
				tile_list_array[x][y].get_node("StaticBody2D/Sprite2D").modulate = Color(67/255.0, 62/255.0, 56/255.0)
				astar_grid.set_point_solid(Vector2(tile_list_array[x][y].mapx, tile_list_array[x][y].mapy), true)

func get_spawn_point():
	for x in range(0, grid_size.x):
		for y in range(0, grid_size.y):
			if tile_list_array[x][y].type == "ground":
				return tile_list_array[x][y].position
		
func get_offscreen_spawn_point(pos):
	pos = Vector2i(pos) / cell_size
	for x in range(pos.x, grid_size.x):
		for y in range(pos.y, grid_size.y):
			if tile_list_array[x][y].type == "ground":
				if tile_list_array[x][y].get_node("VisibleOnScreenNotifier2D").is_on_screen()==false:
					return tile_list_array[x][y].position
	
func get_tile_type(x, y):
	if(x < grid_size.x && y < grid_size.y):
		return tile_list_array[x][y].type
	else:
		return ""
	
func fill_roof():
	for x in range(0, grid_size.x):
		for y in range(0, grid_size.y):
			tile_list_array[x][y].set_type("roof")
			
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

func check_nearby(x, y):
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

func get_caves():
	caves = []

	for x in range (0, grid_size.x):
		for y in range (0, grid_size.y):
			if tile_list_array[x][y].type == "ground":
				flood_fill(x,y)

	for cave in caves:
		for tile in cave:
			tile_list_array[tile.x][tile.y].type = "ground"
			
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

				# optional: make tunnel wider
				#tile_list_array[drunk_x+1][drunk_y].type = "ground"
				#tile_list_array[drunk_x+1][drunk_y+1].type = "ground"
				
# Util.choose(["one", "two"])   returns one or two
func choose(choices):
	randomize()

	var rand_index = randi() % choices.size()
	return choices[rand_index]
	
func initialize_grid():
	astar_grid.size = grid_size
	astar_grid.cell_size = cell_size
	astar_grid.offset = cell_size / 2
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar_grid.update()

func _draw():
	pass
	#draw_grid()
	#fill_walls()
	
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
				
func FindPath(start, end):
	# TODO: Check for any positions out of bounds of grid
	return PackedVector2Array(astar_grid.get_point_path(start, end))
	
func ConvertToGlobal(pos):
	return Vector2((pos.x * cell_size.x) + (cell_size.x/2), (pos.y * cell_size.y) + (cell_size.y/2))
