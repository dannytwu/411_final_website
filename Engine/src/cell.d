/++
    Cell module for map grid representation.
    
    This module implements the Cell class which represents individual
    tiles in the game map grid. Each cell has a position, tile type,
    and optional sprite.

    See_Also:
        $(LINK2 gameobject.html, GameObject),
        $(LINK2 gamescene.html, GameScene),
        $(LINK2 common.html, Position type)
+/
module cell;

import bindbc.sdl;
import spritesheet;
import common;
import gameobject;

/++
    Cell class representing a single map tile.
    
    Extends GameObject to implement grid-based map cells with
    specific tile types and optional sprite overlays.
+/
class Cell : GameObject {
    /// Type of terrain for this cell
    int tileType;
    /// Optional sprite to display on this cell (-1 for none)
    int spriteType;
    
    /++
        Creates a new cell at the specified position.
        
        Params:
            pos = Grid position for this cell
            tileType = Terrain type index
            spriteType = Sprite type index (-1 for none)
    +/
    this(Position pos, int tileType, int spriteType) {
        super(pos);
        this.tileType = tileType;
        this.spriteType = spriteType;
    }
    
    /++
        Renders this cell to the screen.
        
        Params:
            renderer = SDL rendering context
            spriteSheet = Sprite sheet containing cell textures
            
        Overrides GameObject.render() to draw the appropriate
        terrain type with the specified color.
    +/
    override void render(SDL_Renderer* renderer, SpriteSheet spriteSheet) {
        SDL_Rect rect = SDL_Rect(pos.x * TILE_SIZE, pos.y * TILE_SIZE, TILE_SIZE, TILE_SIZE);
        setTileColor(renderer, tileType);
        SDL_RenderFillRect(renderer, &rect);
    }
}
