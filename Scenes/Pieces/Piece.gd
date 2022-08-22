extends Area2D
class_name Piece

var piece_type
var color_type
var square

onready var board = get_parent()

var moves: Array

func _on_Piece_mouse_entered():
	
	moves = request_moves()
	for move in moves:
		board.outlines[move.end_pos].show()
	
	$RedOutline.show()

func _on_Piece_mouse_exited():
	
	for move in moves:
		board.outlines[move.end_pos].hide()
	
	$RedOutline.hide()

func request_moves():
	var moves = []
	
	var i := -1
	for direction_offset in board.direction_offsets:
		i += 1
		for step_idx in range(board.squares_until_edge[square][i]):
			step_idx += 1
			var to_square: int = square + direction_offset * step_idx
			
			if board.squares[to_square] != null: break
			
			moves.append(board.Move.new(square, to_square))
	
	return moves
