extends Node2D
class_name Board

class Move:
	enum Flags {
		Standard
	}
	
	var start_pos: int
	var end_pos: int
	
	var flag: int = Flags.Standard
	
	func _init(start: int, end: int):
		start_pos = start
		end_pos = end
	

var fenArray := "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR"
var board_size = 64

var blackKnight = preload("res://Scenes/Pieces/BlackKnight.tscn");
var whiteKnight = preload("res://Scenes/Pieces/WhiteKnight.tscn");
var blackBishop = preload("res://Scenes/Pieces/BlackBishop.tscn");
var whiteBishop = preload("res://Scenes/Pieces/WhiteBishop.tscn");
var blackPawn = preload("res://Scenes/Pieces/BlackPawn.tscn");
var whitePawn = preload("res://Scenes/Pieces/WhitePawn.tscn");
var blackQueen = preload("res://Scenes/Pieces/BlackQueen.tscn");
var whiteQueen = preload("res://Scenes/Pieces/WhiteQueen.tscn");
var blackKing = preload("res://Scenes/Pieces/BlackKing.tscn");
var whiteKing = preload("res://Scenes/Pieces/WhiteKing.tscn");
var whiteRook = preload("res://Scenes/Pieces/WhiteRook.tscn");
var blackRook = preload("res://Scenes/Pieces/BlackRook.tscn");

var fenToVar = {
	"p": "Pawn",
	"k": "King",
	"q": "Queen",
	"n": "Knight",
	"r": "Rook",
	"b": "Bishop",
}

var fenToInt = {
	"p": 1,
	"k": 2,
	"q": 3,
	"n": 4,
	"r": 5,
	"b": 6,
}

enum Pieces {
	Pawn = 1
	King = 2
	Queen = 3
	Knight = 4
	Rook = 5
	Bishop = 6
}

var piece_selected = -1
var direction_offsets = [8, -8, -1, 1, 7, -7, 9, -9]
var direction_to_idx = {8: 0, -8: 1, -1: 2, 1: 3, 7: 4, -7: 5, 9: 6, -9: 7}
var squares_until_edge := {}
var outlines := []

var squares := {}


func _ready():
	setup_squares()
	setup_pieces()

func setup_squares():
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
			
			if (is_white):
				pieceScene = get("white"+fenToVar[piece])
			else:
				pieceScene = get("black"+fenToVar[piece])
			var piece_instance = pieceScene.instance()
			
			piece_instance.position = board_to_global(square);
			piece_instance.piece_type = fenToInt[piece];
			piece_instance.color_type = 1 if is_white else 0;
			piece_instance.square = square;
			piece_instance.connect("changed_square", self, "_square_changed_square", [piece_instance])
			
			squares[square] = piece_instance
			
			add_child(piece_instance);
		
		index += 1;
	

func _piece_gui_input(input: InputEvent, square: int):
	if input is InputEventMouseButton:
		if input.is_pressed():
			match input.button_index:
				BUTTON_LEFT:
					squares[piece_selected].move(Move.new(square, square))
	elif piece_selected != -1:
		squares[piece_selected]._unhandled_input(input)

func _square_changed_square(old: int, to: int, piece):
	squares[old] = null
	squares[to] = piece

func board_to_global(square: int):
	return $Board.position + Vector2(
		(square % 8 + 1) * 48 - 24,
		(square / 8) * 48 + 24
	);

func delete_square(to_square):
	squares[to_square].queue_free()
	squares[to_square] = null
