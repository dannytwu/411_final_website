/++
    Player entity module implementing character movement and combat.
    
    This module extends the base GameObject to create player characters with
    movement, rotation, health management, and combat capabilities. Players
    can move in eight directions, rotate to aim, and fire projectiles.

    Example:
    ---
    auto player = new Player(Position(5, 5));
    player.moveLeft();
    player.shoot();
    ---

    See_Also:
        $(LINK2 gameobject.html, GameObject),
        $(LINK2 projectile.html, Projectile)
+/
module player;

import std.stdio;
import bindbc.sdl;
import spritesheet;
import common;
import gameobject;
import cell;
import projectile;

/++
    Player class representing an active game character.
    
    Inherits from GameObject and adds player-specific functionality
    including health, movement controls, and combat abilities.

    Members:
        health = Current health points of the player
        angle = Current rotation angle in degrees
        spriteType = Index of player's sprite in spritesheet
+/
class Player : GameObject {
    int spriteType;
    int health = 100;
    SDL_Scancode up, down, left, right, shoot;
    SDL_Scancode turnLeft, turnRight;
    int dx = 1, dy = 0; // direction faced
    int playerIndex;
    int moveCooldown = 0;
    int turnCooldown = 0;
    bool shotCooldown = false;

    /++
        Constructs a new Player at the specified position.
        
        Params:
            pos = Initial spawn position
            spriteType = Index of player sprite in spritesheet
    +/
    this(Position pos, int spriteType, int playerIndex,
         SDL_Scancode up, SDL_Scancode down, SDL_Scancode left, SDL_Scancode right, 
         SDL_Scancode shoot, SDL_Scancode turnLeft, SDL_Scancode turnRight) {
        super(pos);
        this.spriteType = spriteType;
        this.playerIndex = playerIndex;
        this.up = up;
        this.down = down;
        this.left = left;
        this.right = right;
        this.shoot = shoot;
        this.turnLeft = turnLeft;
        this.turnRight = turnRight;
    }
    
    /++
        Updates player state for the current frame.
        
        Handles movement, rotation, and any status effects.
        Called once per frame during game loop.
    +/
    override void update() {
        // Cooldown logic moved to the player class
        if (turnCooldown > 0) turnCooldown--;
        if (moveCooldown > 0) moveCooldown--;
    }
    
    void handleInput(const Uint8* keystate, Cell[][] map, ref GameObject[] gameObjects) {
        // Turn handling
        if (turnCooldown == 0) {
            if (keystate[turnLeft]) {
                int tmp = dx;
                dx = dy;
                dy = -tmp;
                turnCooldown = 10;
            } else if (keystate[turnRight]) {
                int tmp = dx;
                dx = -dy;
                dy = tmp;
                turnCooldown = 10;
            }
        }
        
        // Movement handling
        if (moveCooldown == 0) {
            Position old = pos;
            bool moved = false;
            
            if (keystate[up]) { pos.y--; moved = true; }
            else if (keystate[down]) { pos.y++; moved = true; }
            else if (keystate[left]) { pos.x--; moved = true; }
            else if (keystate[right]) { pos.x++; moved = true; }
            
            // Boundary and collision check
            if (pos.x < 0 || pos.x >= map[0].length ||
                pos.y < 0 || pos.y >= map.length ||
                map[pos.y][pos.x].tileType == Terrain.YELLOW) {
                pos = old;
            } else if (moved) {
                int delay = 6;
                if (map[old.y][old.x].tileType == Terrain.BLUE) delay = 12;
                moveCooldown = delay;
                
                // Check for damage on red tiles
                if (map[pos.y][pos.x].tileType == Terrain.RED) {
                    health--;
                    writeln("Player ", playerIndex, " hurt on red tile! HP = ", health);
                }
            }
        }
        
        // Shooting logic
        if (keystate[shoot] && !shotCooldown) {
            shotCooldown = true;
            if (dx != 0 || dy != 0) {
                gameObjects ~= new Projectile(Position(pos.x, pos.y), dx, dy, playerIndex);
            }
        } else if (!keystate[shoot]) {
            shotCooldown = false;
        }
    }
    
    /++
        Renders the player character to the screen.
        
        Params:
            renderer = SDL rendering context
            spriteSheet = Character sprite sheet containing player textures
    +/
    override void render(SDL_Renderer* renderer, SpriteSheet spriteSheet) {
        int screenX = pos.x * TILE_SIZE;
        int screenY = pos.y * TILE_SIZE;

        double angle = 0;
        if (dx == 1 && dy == 0) angle = 0;
        else if (dx == 0 && dy == 1) angle = 90;
        else if (dx == -1 && dy == 0) angle = 180;
        else if (dx == 0 && dy == -1) angle = 270;

        SDL_Rect src;
        if (spriteType == 0) {
            src = SDL_Rect(0, 0, 60, 44);
        } else {
            src = SDL_Rect(60, 0, 52, 44);
        }

        SDL_Rect destRect = SDL_Rect(screenX, screenY, TILE_SIZE, TILE_SIZE);
        spriteSheet.renderSpriteRotated(spriteType, &src, &destRect, angle);
    }
}
