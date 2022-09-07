extends Node2D
class_name Board

class Move:
	enum Flags {
		Standard = 1 << 1,
		Capture = 1 << 2,
		Promotion = 1 << 3,
		EnPassant = 1 << 4,
		PawnInitial = 1 << 5
	}
	
	var start_pos: int
	var end_pos: int
	var deleted_piece
	
	var flags: int = Flags.Standard
	
	func _init(start: int, end: int, _flags: int = Flags.Standard):
		start_pos = start
		end_pos = end
		flags = _flags
	
	func is_capture(pieces: Dictionary):
		return pieces[end_pos] != null
	

var fenArray := "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR"
var board_size := 64

var fenToVar = {
	"p": "Pawn",
	"k": "King",
	"q": "Queen",
	"n": "Knight",
	"r": "Rook",
	"b": "Bishop",
}

var fenToInt = {
	"k": 1,
	"q": 2,
	"b": 3,
	"n": 4,
	"r": 5,
	"p": 6,
}

var evals := {
	Pieces.King: 99999,
	Pieces.Queen: 900,
	Pieces.Bishop: 300,
	Pieces.Knight: 300,
	Pieces.Rook: 500,
	Pieces.Pawn: 100,
}

enum Pieces {
	King = 1
	Queen = 2
	Bishop = 3
	Knight = 4
	Rook = 5
	Pawn = 6
}

var color_to_move := 1
var current_turn := 1
var piece_selected = -1
var direction_offsets = [8, -8, -1, 1, 7, -7, 9, -9]
var direction_to_idx = {8: 0, -8: 1, -1: 2, 1: 3, 7: 4, -7: 5, 9: 6, -9: 7}
var castle_flags := [[false, false],[false, false]]
var squares_until_edge := {}
var pieces_left := {0: {}, 1: {}}
var outlines := []

var squares := {}

func _ready():
	randomize()
	setup_squares()
	setup_pieces()

func setup_squares():
	for piece in Pieces:
		for i in range(2):
			pieces_left[i][Pieces[piece]] = 0
	
	for square in range(board_size):
		squares[square] = null
	
	for square in squares:
		var c = preload("res://Scenes/RedOutline.tscn").instance()
		c.hide()
		add_child(c)
		c.connect("gui_input", self, "_piece_gui_input", [square])
		c.mouse_filter = c.MOUSE_FILTER_PASS
		c.rect_position = board_to_global(square) - Vector2(24,24)
		outlines.append(c)
	
	for file in range(8):
		for rank in range(8):
			
			var north = 7 - rank
			var south = rank
			var west = file
			var east = 7 - file
			
			var square_idx = 8 * rank + file
			
			squares_until_edge[square_idx] = [
				north, 
				south,
				west, 
				east,
				min(north, west),
				min(south, east),
				min(north, east),
				min(south, west)
			]

func setup_pieces():
	var index = 0;
	
	var cachedRow = 0;
	var skipToNextRow = false;
	
	var skipAmount = 0;
	
	for square in squares:
		
		var piece = '!';
		if (index < fenArray.length()) :
			piece = fenArray[index];
		else:
			print("FEN String terminated but further board squares exist. Continuing..."); break; 
		
		if piece == '/':
			index += 1;
			if (index < fenArray.length()):
				piece = fenArray[index]; 
		
		if (skipToNextRow):
			if (square.y == cachedRow):
				continue;
			skipToNextRow = false;
		
		if (piece == '/' and square.x > 0):
			skipToNextRow = true;
			cachedRow = square.y;
			continue;
		
		if (skipAmount > 0):
			skipAmount -= 1;
			continue;
		
		if (piece == str(int(piece))):
			skipAmount = int(piece)-1;
		
		if (fenToVar.has(piece.to_lower())):
			var pieceScene;
			
			var is_white = not bool(piece == piece.to_lower());
			piece = piece.to_lower();
			
			pieceScene = preload("res://Scenes/Piece.tscn")
			var piece_instance = pieceScene.instance()
			
			piece_instance.position = board_to_global(square);
			piece_instance.color_type = 1 if is_white else 0;
			piece_instance.set_type(fenToInt[piece]);
			piece_instance.square = square;
			piece_instance.connect("changed_square", self, "_square_changed_square", [piece_instance])
			piece_instance.connect("physical_move", self, "_player_moved", [piece_instance])
			piece_instance.connect("moved", self, "_piece_moved", [piece_instance])
			piece_instance.connect("unmake_move", self, "_piece_unmaked_move", [piece_instance])
			
			squares[square] = piece_instance
			pieces_left[piece_instance.color_type][fenToInt[piece]] += 1
			
			if piece.to_lower() == "r":
				var row_value: int = board_size if piece_instance.color_type == 1 else 8
				if square == row_value - 1:
					castle_flags[piece_instance.color_type][1] = true
				if square == row_value - 8:
					castle_flags[piece_instance.color_type][0] = true
			
			add_child(piece_instance);
		
		index += 1;
	

func _piece_gui_input(input: InputEvent, square: int):
	if input is InputEventMouseButton:
		if input.is_pressed():
			match input.button_index:
				BUTTON_LEFT:
					squares[piece_selected].move(Move.new(square, square), true)
	elif piece_selected != -1:
		squares[piece_selected]._unhandled_input(input)

func _piece_moved(move, piece):
	color_to_move = 1 - color_to_move

func _piece_unmaked_move(move, piece):
	color_to_move = 1 - color_to_move

func _square_changed_square(old: int, to: int, piece):
	squares[old] = null
	squares[to] = piece

func _player_moved(move: Move, piece):
	ai_turn(move, piece)

func ai_turn(move: Move, piece):
	
	var occupied_squares := get_pieces(1-color_to_move)
	var moves := []
	for square in occupied_squares:
		moves.append_array(square.request_moves())
	
	var best_eval := -999.0
	var best_move = moves[randi()%moves.size()]
	var best_piece = squares[best_move.start_pos]
	
	for _piece in occupied_squares:
		for _move in _piece.request_moves():
			_piece.move(_move, false, true)
			color_to_move = 0
			var eval = search()
			if eval > best_eval: 
				best_eval = eval
				best_move = _move
				best_piece = _piece
			_piece.unmake_move(_move)
	
	print(best_eval)
	best_piece.move(best_move)
	

func board_to_global(square: int):
	return $Board.position + Vector2(
		(square % 8) * 48 + 24,
		(square / 8) * 48 + 24
	);

func delete_square(to_square, move = null):
	var piece = squares[to_square]
	squares[to_square] = null
	piece.hide()
	if move: 
		move.deleted_piece = piece
		pieces_left[piece.color_type][piece.piece_type] -= 1

func undelete_square(move):
	var piece = move.deleted_piece
	pieces_left[piece.color_type][piece.piece_type] += 1
	piece.show()
	squares[move.end_pos] = piece

func evaluate_color(color: int) -> int:
	return (
		pieces_left[color][Pieces.Queen] * evals[Pieces.Queen] + 
		pieces_left[color][Pieces.Pawn] * evals[Pieces.Pawn] + 
		pieces_left[color][Pieces.Knight] * evals[Pieces.Knight] + 
		pieces_left[color][Pieces.Bishop] * evals[Pieces.Bishop] + 
		pieces_left[color][Pieces.Rook] * evals[Pieces.Rook] +
		pieces_left[color][Pieces.King] * evals[Pieces.King]
	)

func evaluate() -> int:
	var white_eval: int = evaluate_color(1)
	var black_eval: int = evaluate_color(0)
	
	var eval: int = white_eval - black_eval
	
	return eval * (2*color_to_move-1)

var searches := 0
func search(depth: int = 3) -> int:
	searches += 1
	
	if depth == 1: return evaluate()
	
	var best_eval: int = -999999
	for piece in get_pieces(color_to_move):
		for move in piece.request_moves():
			piece.move(move, false, true)
			best_eval = max(best_eval, -search(depth - 1))
			piece.unmake_move(move)
	
	return best_eval

#func search(depth: int = 3, alpha: int = -9999999, beta: int = 99999999) -> int:
#	searches += 1
#
#	if depth == 1: return evaluate()
#
#	for piece in get_pieces(color_to_move):
#		for move in piece.request_moves():
#			piece.move(move, false, true)
#			var eval = -search(depth - 1, -beta, -alpha)
#			piece.unmake_move(move)
#			if eval >= beta:
#				return beta
#			alpha = max(alpha, eval)
#
#	return alpha

func get_pieces(color_type) -> Array:
	var pieces := []
	for square_pos in squares:
		var square = squares[square_pos]
		if square != null and square.color_type == color_type: 
			pieces.append(square)
	return pieces
