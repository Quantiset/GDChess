extends Area2D
class_name Piece

var piece_type
var color_type
var square setget set_square

onready var board = get_parent()
onready var direction_offsets: Array = board.direction_offsets

var moves: Array
var is_pressed := false

signal changed_square(old, to)

func _ready():
	if piece_type == board.Pieces.Bishop:
		direction_offsets = [9, -9, 7, -7]
	elif piece_type == board.Pieces.Rook:
		direction_offsets = [1, -1, 8, -8]

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				BUTTON_LEFT:
					
					if board.piece_selected == square: continue
					
					if not is_pressed:
						if Rect2(
							board.board_to_global(square)-Vector2(24, 24), 
							Vector2(48, 48)).has_point(event.position
						):
							board.piece_selected = square
							is_pressed = true
							$RedOutline.hide()
					else: move_to(square)
	
	elif event is InputEventMouseMotion and is_pressed:
		position = get_global_mouse_position()

func _on_Piece_mouse_entered():
	if board.piece_selected != -1: return
	
	moves = request_moves()
	for move in moves:
		board.outlines[move.end_pos].call_deferred("show")
	
	$RedOutline.show()

func _on_Piece_mouse_exited():
	if is_pressed: return
	
	for move in moves:
		board.outlines[move.end_pos].hide()
	moves = []
	
	$RedOutline.hide()

func request_moves():
	var moves = []
	
	if piece_type == board.Pieces.Knight:
		for jump in [17, 15, 10, 6, -17, -15, -10, 6]:
			var to_square: int = square + jump
			
			if to_square >= 0 and to_square <= board.board_size - 1:
				moves.append(board.Move.new(square, to_square))
			
		return moves
	
	for direction_offset in direction_offsets:
		for step_idx in range(board.squares_until_edge[square][board.direction_to_idx[direction_offset]]):
			step_idx += 1
			var to_square: int = square + direction_offset * step_idx
			
			if board.squares[to_square] != null: break
			
			moves.append(board.Move.new(square, to_square))
	
	return moves

func move_to(to_square: int):
	is_pressed = false
	board.piece_selected = -1
	_on_Piece_mouse_exited()
	self.square = to_square
	position = board.board_to_global(to_square)

func set_square(val: int):
	emit_signal("changed_square", square, val)
	square = val
