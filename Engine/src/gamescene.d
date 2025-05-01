/++
    Game scene module for managing the game world and entities.
    
    This module implements the GameScene class which serves as the main
    container for the game world, handling map loading, entity management,
    collision detection, and game state.

    See_Also:
        $(LINK2 cell.html, Cell),
        $(LINK2 player.html, Player),
        $(LINK2 projectile.html, Projectile)
+/
module gamescene;

import std.stdio;
import std.file;
import std.string;
import std.conv;
import std.algorithm : filter;
import std.array : array;
import bindbc.sdl;
import spritesheet;
import common;
import gameobject;
import cell;
import player;
import projectile;

/++
    Game scene class for managing the game world and entities.
    
    Handles map loading, entity updates, collision detection,
    and game state management. Acts as the central coordinator
    for the game logic.
+/
class GameScene {
    /// 2D grid of map cells
    Cell[][] mapCells;
    /// Array of all active game objects
    GameObject[] gameObjects;
    /// Sprite sheet for rendering
    SpriteSheet spriteSheet;
    /// SDL renderer for drawing
    SDL_Renderer* renderer;
    /// Flag indicating if the game is over
    bool gameOver = false;
    
    /++
        Creates a new game scene.
        
        Params:
            renderer = SDL rendering context
            spriteSheet = Sprite sheet for rendering game entities
    +/
    this(SDL_Renderer* renderer, SpriteSheet spriteSheet) {
        this.renderer = renderer;
        this.spriteSheet = spriteSheet;
    }
    
    /++
        Loads a map from a file.
        
        Params:
            filename = Path to the map file
            
        The map file format consists of rows and columns of tile types
        and sprite types. Players are created based on sprite indices.
    +/
    void loadMap(string filename) {
        auto file = File(filename, "r");
        int rows, cols;
        file.readf("%d %d\n", &rows, &cols);

        mapCells.length = rows;
        foreach (ref row; mapCells) row.length = cols;

        int playerCount = 0;
        for (int y = 0; y < rows; y++) {
            auto tokens = file.readln().split();
            for (int x = 0; x < cols; x++) {
                int tile = tokens[x * 2].to!int;
                int sprite = tokens[x * 2 + 1].to!int;
                
                // Create map cell
                mapCells[y][x] = new Cell(Position(x, y), tile, sprite);
                
                // Create players at specified positions
                if (sprite >= 0 && playerCount < 2) {
                    auto pos = Position(x, y);
                    if (playerCount == 0) {
                        gameObjects ~= new Player(
                            pos, sprite, playerCount, 
                            SDL_SCANCODE_W, SDL_SCANCODE_S, SDL_SCANCODE_A, SDL_SCANCODE_D, 
                            SDL_SCANCODE_SPACE, SDL_SCANCODE_Q, SDL_SCANCODE_E
                        );
                    } else {
                        gameObjects ~= new Player(
                            pos, sprite, playerCount,
                            SDL_SCANCODE_UP, SDL_SCANCODE_DOWN, SDL_SCANCODE_LEFT, SDL_SCANCODE_RIGHT, 
                            SDL_SCANCODE_PERIOD, SDL_SCANCODE_SLASH, SDL_SCANCODE_RSHIFT
                        );
                    }
                    playerCount++;
                }
            }
        }
        writeln("Loaded map with ", playerCount, " players.");
    }
    
    /++
        Updates all game entities for the current frame.
        
        Params:
            keystate = Current keyboard state for input handling
            
        Updates all active game objects, handles player input,
        checks for collisions, and updates game state.
    +/
    void update(const Uint8* keystate) {
        // Get all players
        auto players = getPlayers();
        
        // Update all active game objects
        for (int i = 0; i < gameObjects.length; i++) {
            if (gameObjects[i].active) {
                // Special handling for player input
                if (auto player = cast(Player)gameObjects[i]) {
                    player.handleInput(keystate, mapCells, gameObjects);
                }
                
                // Update game object
                gameObjects[i].update();
            }
        }
        
        // Check for collisions
        checkCollisions();
        
        // Remove inactive objects
        removeInactiveObjects();
        
        // Check game over
        checkGameOver();
    }
    
    /++
        Renders the game scene.
        
        Draws the map cells and all active game objects to the screen.
    +/
    void render() {
        // Render map
        for (int y = 0; y < mapCells.length; y++) {
            for (int x = 0; x < mapCells[y].length; x++) {
                mapCells[y][x].render(renderer, spriteSheet);
            }
        }
        
        // Render all active game objects
        foreach (obj; gameObjects) {
            if (obj.active) {
                obj.render(renderer, spriteSheet);
            }
        }
    }
    
    /++
        Gets all player objects in the scene.
        
        Returns:
            Array of Player objects
    +/
    private Player[] getPlayers() {
        Player[] players;
        foreach (obj; gameObjects) {
            if (auto player = cast(Player)obj) {
                players ~= player;
            }
        }
        return players;
    }
    
    /++
        Checks for collisions between game objects.
        
        Handles projectile collisions with map boundaries and players,
        applying damage and deactivating projectiles as needed.
    +/
    private void checkCollisions() {
        // Projectile collision with map boundaries and players
        foreach (obj; gameObjects) {
            // Skip inactive objects
            if (!obj.active) continue;
            
            // Check projectiles
            if (auto proj = cast(Projectile)obj) {
                // Check map boundaries
                if (proj.pos.x < 0 || proj.pos.x >= mapCells[0].length ||
                    proj.pos.y < 0 || proj.pos.y >= mapCells.length ||
                    mapCells[proj.pos.y][proj.pos.x].tileType == Terrain.YELLOW) {
                    proj.active = false;
                    continue;
                }
                
                // Check player collisions
                foreach (player; getPlayers()) {
                    if (player.playerIndex != proj.ownerIndex && player.pos == proj.pos) {
                        player.health -= 10;
                        writeln("Player ", player.playerIndex, " hit by projectile! HP = ", player.health);
                        proj.active = false;
                        break;
                    }
                }
            }
        }
    }
    
    /++
        Removes inactive objects from the game world.
        
        Filters out any game objects that have been deactivated.
    +/
    private void removeInactiveObjects() {
        // Remove inactive objects
        gameObjects = gameObjects.filter!(obj => obj.active).array;
    }
    
    /++
        Checks if the game is over.
        
        Determines if either player has been defeated and sets
        the game over flag accordingly.
    +/
    private void checkGameOver() {
        auto players = getPlayers();
        if (players.length < 2) return;
        
        if (players[0].health <= 0) {
            writeln("Player 1 wins!");
            gameOver = true;
        } else if (players[1].health <= 0) {
            writeln("Player 0 wins!");
            gameOver = true;
        }
    }
    
    /++
        Gets the game over state.
        
        Returns:
            true if the game is over, false otherwise
    +/
    bool isGameOver() {
        return gameOver;
    }
}
