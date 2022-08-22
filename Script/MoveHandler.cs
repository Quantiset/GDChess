using Godot;
using System;

public class MoveHandler : Node
{
	
	private struct Move {
		public int startingPos;
		public int endingPos;
	}
	
	private int[][] offsetUntilEdge = new int[64][];
	
	public static int[] loopedDirections = {
	+8, // SOUTH
	-8, // NORTH
	-1, // WEST
	+1, // EAST
	+7, // SOUTHWEST
	-7, // NORTHEAST
	+9, // SOUTHEAST
	-9  // NORTHWEST
	};
	
	public enum direction {
		SOUTH = 8,
		NORTH = -8,
		WEST = -1,
		EAST = 1,
		SOUTHWEST = +7,
		NORTHEAST = -7,
		SOUTHEAST = +9,
		NORTHWEST = -9,
	}
	
	public override void _Ready()
	{
		ComputeToEdgeOfBoard();
		//foreach (int[] offsetTable in offsetUntilEdge) {
		//    string p = "{";
		//    foreach (int offset in offsetTable) {
		//        p += offset.ToString();
		//    }
		//    GD.Print(p+"}");
		//}
	}
	
	
	public static void RequestMoves(int index) {
		
	}
	
	private void ComputeToEdgeOfBoard() 
	{
		for (int file = 0; file < 8; file++) {
			for (int rank = 0; rank < 8; rank++) {
				
				int numSouth = 7 - rank;
				int numNorth = rank;
				int numWest = 7 - file;
				int numEast = file;
				
				int currSquare = rank * 8 + file;
				
				offsetUntilEdge[currSquare] = new int[] {
					numSouth,
					numNorth,
					numEast,
					numWest,
					Math.Min(numSouth, numEast),
					Math.Min(numNorth, numWest),
					Math.Min(numSouth, numWest),
					Math.Min(numNorth, numEast),
				};
				
			}
		}
	}
	
}
