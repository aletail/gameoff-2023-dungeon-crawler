class_name Map extends Node2D

var astar_grid = AStarGrid2D.new()
var cell_size = Vector2i(64, 64)
var grid_size = Vector2i(10, 10)

func _init(cellsize, gridsize):
	cell_size = cellsize
	grid_size = gridsize

func _ready():
	initialize_grid()
	
func initialize_grid():
	astar_grid.size = grid_size
	astar_grid.cell_size = cell_size
	astar_grid.offset = cell_size / 2
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar_grid.update()

func _draw():
	draw_grid()
	
func draw_grid():
	for x in grid_size.x + 1:
		draw_line(Vector2(x * cell_size.x, 0), Vector2(x * cell_size.x, grid_size.y * cell_size.y), Color.DARK_GRAY, 2.0)
	for y in grid_size.y + 1:
		draw_line(Vector2(0, y * cell_size.y), Vector2(grid_size.x * cell_size.x, y * cell_size.y), Color.DARK_GRAY, 2.0)

func FindPath(start, end):
	return PackedVector2Array(astar_grid.get_point_path(start, end))
