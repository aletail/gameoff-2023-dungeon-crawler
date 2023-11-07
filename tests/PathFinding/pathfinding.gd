extends Node2D

var astar_grid = AStarGrid2D.new()
var party
var start = Vector2i.ZERO
var end = Vector2i(5, 5)

@export var cell_size = Vector2i(64, 64)
@export var grid_size = Vector2i(10, 10)

@onready var cameraNode : Camera2D = get_node("Camera2D")
func _ready():
	initialize_grid()
	party = PartyManager.new()
	add_child(party)
	
func _process(delta):
	cameraNode.position = cameraNode.position.lerp(party.getLeader().position, delta * 2)
	
func initialize_grid():
	astar_grid.size = grid_size
	astar_grid.cell_size = cell_size
	astar_grid.offset = cell_size / 2
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar_grid.update()

func _draw():
	draw_grid()
	fill_walls()
	
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

func update_path():
	$Line2D.points = PackedVector2Array(astar_grid.get_point_path(start, end))
	
func move_party():
	var PartyLeader = party.getLeader();
	if(PartyLeader):
		var s = Vector2i(PartyLeader.position) / cell_size
		var pathlist = PackedVector2Array(astar_grid.get_point_path(s, end))
		PartyLeader.Move(pathlist)

func _input(event):
	if event is InputEventMouseButton:
		# Add/remove wall
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var pos = Vector2i(event.position) / cell_size
			if astar_grid.is_in_boundsv(pos):
				astar_grid.set_point_solid(pos, not astar_grid.is_point_solid(pos))
			update_path()
			queue_redraw()
		# Move end
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var PartyLeader = party.getLeader();
			start = Vector2i(PartyLeader.position) / cell_size
			end = Vector2i(get_global_mouse_position()) / cell_size
			update_path()
			move_party()
			queue_redraw()

