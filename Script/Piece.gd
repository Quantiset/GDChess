extends Area2D
class_name Piece

var piece_type
var color_type
var square setget set_square
onready var board = get_parent()
onready var direction_offsets: Array = board.direction_offsets
var direction_length = 15

var moves: Array
var is_pressed := false

var row_shifts := {
	17: 2, 15: 2, 10: 1, 6: 1, -17: -2, -15: -2, -10: -1, -6: -1
}
var knight_offsets = [17, 15, 10, 6, -17, -15, -10, -6]

onready var squares: Dictionary = board.squares

enum Pieces {

	King = 1
	Queen = 2
	Bishop = 3
	Knight = 4
	Rook = 5
	Pawn = 6

}

signal changed_square(old, to)

func _ready():
	set_type(piece_type)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				BUTTON_RIGHT:
					if is_pressed: move(board.Move.new(square, square))
				
				BUTTON_LEFT:
					
					if board.piece_selected != -1 and \
						squares[board.piece_selected].is_pressed: 
						continue
					
					if not is_pressed:
						if Rect2(
							board.board_to_global(square)-Vector2(24, 24), 
							Vector2(48, 48)).has_point(event.position
						):
							board.piece_selected = square
							is_pressed = true
							$RedOutline.hide()
							get_tree().set_input_as_handled()
					else: move(board.Move.new(square, square))
	
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
		for jump in knight_offsets:
			var to_square: int = square + jump
			
			if not is_in_row(jump):
				continue
			
			if to_square >= 0 and to_square <= board.board_size - 1:
				if squares[to_square] != null and \
						squares[to_square].color_type == color_type:
					continue
				moves.append(board.Move.new(square, to_square))
			
		return moves
	
	if piece_type == board.Pieces.Pawn:
		var color_scale = 2 * color_type - 1
		for attack_query in [-9 * color_scale, -7 * color_scale]:
			var to_square = square + attack_query
			if to_square >= 0 and to_square < board.board_size and \
					squares[to_square] != null and \
					squares[to_square].color_type != color_type:
				moves.append(board.Move.new(square, to_square))
	
	for direction_offset in direction_offsets:
		for step_idx in range(1, board.squares_until_edge[square][board.direction_to_idx[direction_offset]]+1):
			var to_square: int = square + direction_offset * step_idx
			
			if step_idx > direction_length: break
			if squares[to_square] != null: 
				if squares[to_square].color_type != color_type and not piece_type == board.Pieces.Pawn:
					moves.append(board.Move.new(square, to_square))
				break
			
			moves.append(board.Move.new(square, to_square))
	
	return moves

func move(move):
	print(move)
	var to_square: int = move.end_pos
	
	if piece_type == board.Pieces.Pawn and (
		square < 8 if color_type == 1 else
		square > board.board_size - 8 
	):
		set_type(board.Pieces.Queen)
	
	if to_square != square:
		if squares[to_square] != null:
			board.delete_square(to_square)
			squares[square] = null
		
		if piece_type == board.Pieces.Pawn:
			direction_length = 1
	
	is_pressed = false
	board.piece_selected = -1
	_on_Piece_mouse_exited()
	self.square = to_square
	position = board.board_to_global(to_square)

func set_square(val: int):
	emit_signal("changed_square", square, val)
	square = val

func set_type(_piece: int):
	
	piece_type = _piece
	$Sprite.region_rect = Rect2(
		Vector2(45*(_piece-1),45*(-color_type+1)), Vector2(45,45)
	)
	
	if piece_type == Pieces.Bishop:
		direction_offsets = [9, -9, 7, -7]
		direction_length = 15
	elif piece_type == Pieces.Rook:
		direction_offsets = [1, -1, 8, -8]
		direction_length = 15
	elif piece_type == Pieces.Pawn:
		direction_offsets = [(-8 if color_type == 1 else 8)]
		direction_length = 2
	elif piece_type == Pieces.King:
		direction_offsets = [8, -8, -1, 1, 7, -7, 9, -9]
		direction_length = 1
	else:
		direction_offsets = [8, -8, -1, 1, 7, -7, 9, -9]
		direction_length = 15

func is_in_row(shift: int) -> bool:
	return (square+shift)/8==square/8+row_shifts[shift]
