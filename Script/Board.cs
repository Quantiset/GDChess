using Godot;
using System;
using System.Collections.Generic;

public class Board : Node2D
{
	
	private PackedScene blackKnight = ResourceLoader.Load<PackedScene>("res://Scenes/Pieces/BlackKnight.tscn");
	private PackedScene whiteKnight = ResourceLoader.Load<PackedScene>("res://Scenes/Pieces/WhiteKnight.tscn");
	private PackedScene blackBishop = ResourceLoader.Load<PackedScene>("res://Scenes/Pieces/BlackBishop.tscn");
	private PackedScene whiteBishop = ResourceLoader.Load<PackedScene>("res://Scenes/Pieces/WhiteBishop.tscn");
	private PackedScene blackPawn = ResourceLoader.Load<PackedScene>("res://Scenes/Pieces/BlackPawn.tscn");
	private PackedScene whitePawn = ResourceLoader.Load<PackedScene>("res://Scenes/Pieces/WhitePawn.tscn");
	private PackedScene blackQueen = ResourceLoader.Load<PackedScene>("res://Scenes/Pieces/BlackQueen.tscn");
	private PackedScene whiteQueen = ResourceLoader.Load<PackedScene>("res://Scenes/Pieces/WhiteQueen.tscn");
	private PackedScene blackKing = ResourceLoader.Load<PackedScene>("res://Scenes/Pieces/BlackKing.tscn");
	private PackedScene whiteKing = ResourceLoader.Load<PackedScene>("res://Scenes/Pieces/WhiteKing.tscn");
	private PackedScene whiteRook = ResourceLoader.Load<PackedScene>("res://Scenes/Pieces/WhiteRook.tscn");
	private PackedScene blackRook = ResourceLoader.Load<PackedScene>("res://Scenes/Pieces/BlackRook.tscn");


	public string fenString = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR";

	private Dictionary<char, string> fenToVar = new Dictionary<char, string>(){
		{'p', "Pawn"},
		{'k', "King"},
		{'q', "Queen"},
		{'n', "Knight"},
		{'r', "Rook"},
		{'b', "Bishop"},
	};

	private Dictionary<char, int> fenToInt = new Dictionary<char, int>(){
		{'p', 1},
		{'k', 2},
		{'q', 3},
		{'n', 4},
		{'r', 5},
		{'b', 6},
	};

	public static List<Vector2> squares = new List<Vector2>(){};

	public static List<Vector2> occupiedSquares = new List<Vector2>();

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{

		DefineSquares();
		SetupFenString();

	}

	void DefineSquares() 
	{
		for (int y = 0; y < 8; y++) 
		{
			for (int x = 0; x < 8; x++) 
			{
				Vector2 pos = new Vector2(x, y);
				squares.Add(pos);
			}
		}
	}

	Vector2 boardToGlobal(Vector2 square) 
	{
		return GetNode<Node2D>("Board").Position + new Vector2(
			(square.x + 1f) * 48f - 24f,
			square.y * 48f + 24f
		);
	}

	void SetupFenString() {
		char[] fenArray = fenString.ToCharArray();
		int index = 0;

		float cachedRow = 0f;
		bool skipToNextRow = false;

		int skipAmount = 0;

		int boardIndex = -1;
		foreach (Vector2 square in squares) 
		{
			boardIndex++;
			char piece = '!';
			if (index < fenArray.Length) {
				piece = fenArray[index];
			} else { 
				GD.Print("FEN String terminated but further board squares exist. Continuing..."); break; 
			};

			if (piece == '/') {
				index++;
				if (index < fenArray.Length) { 
					piece = fenArray[index]; 
				}
			}

			if (skipToNextRow) {
				if (square.y == cachedRow) {
					GD.Print(square.y);
					continue;
				}
				skipToNextRow = false;
			}

			if (piece == '/' && square.x > 0) {
				skipToNextRow = true;
				cachedRow = square.y;
				continue;
			}

			if (skipAmount > 0) {
				skipAmount--;
				continue;
			}
			
			if (char.IsNumber(piece)) {
				skipAmount = (int)(piece - '0')-1;
			}

			if (fenToVar.ContainsKey(Char.ToLower(piece))) 
			{
				PackedScene pieceScene;

				bool is_white = Char.IsUpper(piece);
				piece = Char.ToLower(piece);

				if (is_white) {
					pieceScene = (PackedScene) Get("white" + fenToVar[piece]);
				} else {
					pieceScene = (PackedScene) Get("black" + fenToVar[piece]);
				}
				Piece pieceInstance = pieceScene.Instance<Piece>();

				pieceInstance.Position = boardToGlobal(square);
				pieceInstance.pieceType = fenToInt[piece];
				pieceInstance.colorType = is_white ? 1 : 0;
				pieceInstance.square = square;
				pieceInstance.index = boardIndex;

				occupiedSquares.Add(square);
				AddChild(pieceInstance);
			}
			index++;
		}
	}

}
