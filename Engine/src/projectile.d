/++
    Projectile entity module for weapon and combat systems.
    
    Implements projectiles in the game world, handling movement and collisions.
    Projectiles are fired by players and follow straight-line paths.

    See_Also:
        $(LINK2 gameobject.html, GameObject),
        $(LINK2 player.html, Player)
+/
module projectile;

import bindbc.sdl;
import spritesheet;
import common;
import gameobject;

/++
    Projectile class for representing bullets and other fired objects.
    
    Extends GameObject to implement projectile behavior including
    directional movement and collision detection.

    Members:
        direction = Movement direction of the projectile
        damage = Amount of damage dealt on collision
+/
class Projectile : GameObject {
    int dx, dy;
    int ownerIndex;
    
    /++
        Creates a new projectile at the specified position moving in the given direction.
        
        Params:
            pos = Starting position of the projectile
            dx = Horizontal movement component
            dy = Vertical movement component
            ownerIndex = Index of the player who fired the projectile
    +/
    this(Position pos, int dx, int dy, int ownerIndex) {
        super(pos);
        this.dx = dx;
        this.dy = dy;
        this.ownerIndex = ownerIndex;
    }
    
    /++
        Updates the projectile's position based on its direction.
        
        Called each frame to move the projectile one unit in its current direction.
        Overrides GameObject.update().
    +/
    override void update() {
        pos.x += dx;
        pos.y += dy;
    }
    
    /++
        Renders the projectile on screen.
        
        Params:
            renderer = SDL renderer context
            spriteSheet = Sprite sheet containing projectile textures
            
        Overrides GameObject.render().
    +/
    override void render(SDL_Renderer* renderer, SpriteSheet spriteSheet) {
        if (ownerIndex == 0)
            SDL_SetRenderDrawColor(renderer, 0, 200, 100, 255); // Teal-green for Player 0
        else
            SDL_SetRenderDrawColor(renderer, 255, 80, 80, 255); // Soft red for Player 1
            
        SDL_Rect rect = SDL_Rect(pos.x * TILE_SIZE + TILE_SIZE/4, 
                                 pos.y * TILE_SIZE + TILE_SIZE/4, 
                                 TILE_SIZE/2, TILE_SIZE/2);
        SDL_RenderFillRect(renderer, &rect);
    }
}
