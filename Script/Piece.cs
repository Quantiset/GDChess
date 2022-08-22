using Godot;
using System;



public class Piece : Area2D
{
	public enum piece {
		Pawn = 1,
		King = 2,
		Queen = 3,
		Knight = 4,
		Rook = 5,
		Bishop = 6,
	}

	public enum color {
		White = 0,
		Black = 1,
	}

	public int pieceType;
	public int colorType;

	public Vector2 square;
	public int index;

	public Vector2 Square {
		get {
			return square;
		}
		set {
			square = value;
		}
	}

	public bool isMouseHovered = false;

	public override void _Ready()
	{
		
	}

	public void _on_Piece_mouse_entered() 
	{
		isMouseHovered = true;
		GetNode<ColorRect>("RedOutline").Show();
	}

	public void _on_Piece_mouse_exited() 
	{
		isMouseHovered = false;
		GetNode<ColorRect>("RedOutline").Hide();
	}

	public override void _Input(InputEvent @event)
	{
		if (Input.IsActionJustPressed("ui_click") && isMouseHovered) {
			MoveHandler.RequestMoves(index);
		}
	}


}
