/++
    Common types and utilities shared across the game engine.
    
    This module provides fundamental types, constants, and utility
    functions used throughout the game engine. It defines core
    concepts like grid positions and terrain types.

    See_Also:
        $(LINK2 gameobject.html, GameObject),
        $(LINK2 cell.html, Cell)
+/
module common;

import bindbc.sdl;

/++
    Core game constants defining the game world dimensions and rendering.
+/
/// Size of each tile in pixels
enum TILE_SIZE = 48;
/// Number of columns in the game grid
enum GRID_COLS = 32;
/// Number of rows in the game grid
enum GRID_ROWS = 32;
/// Total window width including UI panels
enum WINDOW_WIDTH = TILE_SIZE * GRID_COLS + 200;
/// Total window height including toolbar
enum WINDOW_HEIGHT = TILE_SIZE * GRID_ROWS + 40;

/++
    Terrain type enumeration defining the basic tile types.
+/
enum Terrain {
    RED = 0,    /// Damaging terrain
    BLUE = 1,   /// Slow movement terrain
    GREEN = 2,  /// Normal terrain
    YELLOW = 3  /// Blocking/wall terrain
}

/++
    Position structure for grid-based coordinates.
    
    Represents a position in the game's grid coordinate system,
    where each unit corresponds to one cell/tile.
+/
struct Position {
    /// X-coordinate (column) in the grid
    int x;
    /// Y-coordinate (row) in the grid
    int y;
    
    /++
        Equality comparison operator.
        
        Params:
            other = Position to compare with
            
        Returns:
            true if both x and y coordinates match
    +/
    bool opEquals(Position other) const {
        return x == other.x && y == other.y;
    }
}

/++
    Sets the rendering color for a specific tile type.
    
    Params:
        renderer = SDL rendering context
        tileType = Terrain type index to set color for
+/
void setTileColor(SDL_Renderer* renderer, int tileType) {
    switch (tileType) {
        case Terrain.RED: SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255); break;
        case Terrain.BLUE: SDL_SetRenderDrawColor(renderer, 0, 0, 255, 255); break;
        case Terrain.GREEN: SDL_SetRenderDrawColor(renderer, 0, 255, 0, 255); break;
        case Terrain.YELLOW: SDL_SetRenderDrawColor(renderer, 255, 255, 0, 255); break;
        default: SDL_SetRenderDrawColor(renderer, 70, 70, 70, 255); break;
    }
}
