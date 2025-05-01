/++
    Sprite and tile sheet handling for game graphics.
    
    This module provides classes for loading, managing, and rendering
    sprite sheets and tile sheets, supporting various rendering options
    including rotation, scaling, and aspect ratio preservation.
    
    See_Also:
        $(LINK2 resourcemanager.html, ResourceManager)
+/
module spritesheet;

import std.stdio;
import std.string : fromStringz;
import bindbc.sdl;
import std.path : buildPath;

/**
 * TileSheet class for handling the game tileset
 */
class TileSheet {
    private:
        SDL_Texture* texture;
        SDL_Renderer* renderer;
        SDL_Rect[string] tiles;

    public:
        this(SDL_Renderer* renderer) {
            this.renderer = renderer;
        }


        bool load(string path) {
            SDL_Surface* surface = SDL_LoadBMP(path.ptr);
            if (surface is null) {
                writeln("Failed to load tilesheet: ", SDL_GetError().fromStringz);
                return false;
            }
            
            texture = SDL_CreateTextureFromSurface(renderer, surface);
            SDL_FreeSurface(surface);
            
            if (texture is null) {
                writeln("Failed to create texture: ", SDL_GetError().fromStringz);
                return false;
            }
            
            // Define all the tiles in the sheet
            defineTiles();
            
            return true;
        }
        
        // Define a tile region on the sheet
        void defineTile(string name, int x, int y, int width, int height) {
            tiles[name] = SDL_Rect(x, y, width, height);
        }
        
        // Render a tile by name
        bool renderTile(string name, int x, int y, int width = 0, int height = 0) {
            if (name !in tiles) {
                return false;
            }
            
            SDL_Rect src = tiles[name];
            
            // Use original dimensions if no scaling specified
            if (width <= 0) width = src.w;
            if (height <= 0) height = src.h;
            
            SDL_Rect dst = SDL_Rect(x, y, width, height);
            SDL_RenderCopy(renderer, texture, &src, &dst);
            
            return true;
        }
        
        // Define all tile coordinates
        private void defineTiles() {
            // Floor types
            defineTile("floor_yellow", 5, 60, 100, 100);
            defineTile("floor_white", 342, 60, 100, 100);
            defineTile("floor_orange", 5, 230, 100, 100);
            defineTile("floor_brown", 342, 230, 100, 100);
            defineTile("floor_blue", 5, 400, 100, 100);
            defineTile("floor_dark", 342, 400, 100, 100);
            
            // Wood floor tiles (upper right)
            defineTile("wood_floor", 670, 60, 32, 32);
            
            // Wall sections
            defineTile("wall_yellow_h", 10, 190, 100, 10);  // Horizontal wall
            defineTile("wall_yellow_v", 60, 10, 10, 80);    // Vertical wall
            defineTile("wall_orange_h", 10, 360, 100, 10);  // Orange horizontal wall
            defineTile("wall_orange_v", 60, 190, 10, 80);   // Orange vertical wall
            
            // Corner pieces
            defineTile("corner_yellow", 5, 5, 10, 10);
            defineTile("corner_orange", 5, 190, 10, 10);
            defineTile("corner_blue", 5, 380, 10, 10);
            
            // Special objects
            defineTile("yellow_circle", 90, 97, 16, 16);
            defineTile("white_circle", 420, 97, 16, 16);
            
            // Trees and bushes
            defineTile("green_tree_large", 770, 300, 64, 64);
            defineTile("orange_tree_large", 840, 300, 64, 64);
            defineTile("green_bush_small", 770, 370, 32, 32);
            defineTile("orange_bush_small", 840, 370, 32, 32);
            
            // Small decorations (right side)
            defineTile("green_leaf", 980, 330, 16, 16);
            defineTile("blue_gem", 1080, 220, 24, 24);
            defineTile("yellow_coin", 1120, 220, 24, 24);
            
            // Crate/box tiles
            defineTile("wood_crate_large", 770, 220, 48, 48);
            defineTile("wood_crate_small", 830, 220, 32, 32);
            
            // UI panels
            defineTile("orange_panel", 860, 580, 180, 50);
            defineTile("green_panel", 1070, 580, 180, 50);
            defineTile("orange_panel_large", 860, 640, 180, 180);
            defineTile("green_panel_large", 1070, 640, 180, 180);
            
            // Water tiles
            defineTile("blue_water", 830, 780, 64, 32);
            defineTile("green_water", 900, 780, 64, 32);
            
            // Small geometric shapes
            defineTile("gray_pentagon", 1020, 420, 24, 24);
            defineTile("blue_square", 980, 420, 24, 24);
            defineTile("orange_square", 870, 500, 24, 24);
            
            // Window frames
            defineTile("green_window", 1070, 120, 64, 64);
            defineTile("orange_window", 1150, 120, 64, 64);
            
            // Button/UI elements
            defineTile("brown_button", 960, 840, 64, 32);
            defineTile("white_frame", 1070, 840, 100, 48);
            
            // Special effects
            defineTile("gray_smoke", 1020, 550, 32, 32);
            defineTile("black_smoke", 1060, 550, 32, 32);
        }
        
        void destroy() {
            if (texture !is null) {
                SDL_DestroyTexture(texture);
                texture = null;
            }
        }
        
        ~this() {
            destroy();
        }
}

/++
    SpriteSheet class for handling uniform grid-based sprites like character animations.
    
    Manages loading and rendering of sprite sheets with uniform grid layouts,
    supporting various rendering options including rotation, scaling, and
    aspect ratio preservation.
+/
class SpriteSheet {
    private:
        SDL_Texture* texture;
        SDL_Renderer* renderer;
        int spriteWidth;
        int spriteHeight;
        int columns;
        int rows;

    public:
        this(SDL_Renderer* renderer) {
            this.renderer = renderer;
        }

        /++
            Renders a sprite with rotation.
            
            Params:
                index = Sprite index to render
                src = Source rectangle in the spritesheet
                dst = Destination rectangle on screen
                angle = Rotation angle in degrees
        +/
        void renderSpriteRotated(int index, SDL_Rect* src, SDL_Rect* dst, double angle) {
            SDL_RenderCopyEx(renderer, texture, src, dst, angle, null, SDL_FLIP_NONE);
        }

        /++
            Loads a sprite sheet from the specified file.
            
            Params:
                path = Path to the sprite sheet image file
                spriteWidth = Width of each sprite in pixels
                spriteHeight = Height of each sprite in pixels
                
            Returns:
                true if loading was successful, false otherwise
        +/
        bool load(string path, int spriteWidth, int spriteHeight) {
            SDL_Surface* surface = SDL_LoadBMP(path.ptr);
            if (surface is null) {
                writeln("Failed to load spritesheet: ", SDL_GetError().fromStringz);
                return false;
            }
            
            texture = SDL_CreateTextureFromSurface(renderer, surface);
            SDL_FreeSurface(surface);
            
            if (texture is null) {
                writeln("Failed to create texture: ", SDL_GetError().fromStringz);
                return false;
            }

            // Get texture dimensions
            int width, height;
            SDL_QueryTexture(texture, null, null, &width, &height);
            
            // Store sprite info
            this.spriteWidth = spriteWidth;
            this.spriteHeight = spriteHeight;
            this.columns = width / spriteWidth;
            this.rows = height / spriteHeight;
            
            writeln("Spritesheet loaded: ", columns, "x", rows, " sprites (", columns * rows, " total)");
            return true;
        }
        
        /++
            Gets the source rectangle for a sprite by index.
            
            Params:
                index = Index of the sprite in the sheet
                
            Returns:
                SDL_Rect defining the sprite's position and dimensions in the sheet
        +/
        SDL_Rect getSpriteRect(int index) {
            int col = index % columns;
            int row = index / columns;
            
            return SDL_Rect(
                col * spriteWidth,
                row * spriteHeight,
                spriteWidth,
                spriteHeight
            );
        }
        
        /++
            Gets the source rectangle for a sprite by column and row.
            
            Params:
                col = Column of the sprite in the sheet
                row = Row of the sprite in the sheet
                
            Returns:
                SDL_Rect defining the sprite's position and dimensions in the sheet
        +/
        SDL_Rect getSpriteRect(int col, int row) {
            return SDL_Rect(
                col * spriteWidth,
                row * spriteHeight,
                spriteWidth,
                spriteHeight
            );
        }
        
        void renderSprite(int index, int x, int y, int width = 0, int height = 0) {
            SDL_Rect src = getSpriteRect(index);
            
            // Use sprite dimensions if no scaling specified
            if (width <= 0) width = spriteWidth;
            if (height <= 0) height = spriteHeight;
            
            SDL_Rect dst = SDL_Rect(x, y, width, height);
            SDL_RenderCopy(renderer, texture, &src, &dst);
        }
        
        void renderSprite(int col, int row, int x, int y, int width = 0, int height = 0) {
            SDL_Rect src = getSpriteRect(col, row);
            
            // Use sprite dimensions if no scaling specified
            if (width <= 0) width = spriteWidth;
            if (height <= 0) height = spriteHeight;
            
            SDL_Rect dst = SDL_Rect(x, y, width, height);
            SDL_RenderCopy(renderer, texture, &src, &dst);
        }
        
        void renderSpritePreserveAspect(int index, int x, int y, int maxWidth = 0, int maxHeight = 0) {
            SDL_Rect src = getSpriteRect(index);
            
            // Use sprite dimensions if no scaling specified
            int width = spriteWidth;
            int height = spriteHeight;
            
            // Calculate aspect ratio
            float ratio = cast(float)width / height;
            
            // Calculate target dimensions while preserving aspect ratio
            if (maxWidth > 0 && maxHeight > 0) {
                if (maxWidth / ratio <= maxHeight) {
                    // Width is the limiting factor
                    width = maxWidth;
                    height = cast(int)(width / ratio);
                } else {
                    // Height is the limiting factor
                    height = maxHeight;
                    width = cast(int)(height * ratio);
                }
            } else if (maxWidth > 0) {
                width = maxWidth;
                height = cast(int)(width / ratio);
            } else if (maxHeight > 0) {
                height = maxHeight;
                width = cast(int)(height * ratio);
            }
            
            // Center the sprite in its cell
            int offsetX = 0;
            int offsetY = 0;
            if (maxWidth > 0) offsetX = (maxWidth - width) / 2;
            if (maxHeight > 0) offsetY = (maxHeight - height) / 2;
            
            SDL_Rect dst = SDL_Rect(x + offsetX, y + offsetY, width, height);
            SDL_RenderCopy(renderer, texture, &src, &dst);
        }

        void renderPlayerSprite(int index, int x, int y, int maxWidth, int maxHeight) {
            SDL_Rect src;
            
            // Custom offsets and widths for the two player sprites
            if (index == 0) {
                // Green character with weapon 
                src.x = 0;  
                src.y = 0;
                src.w = 60; // Wider to include weapon
                src.h = 44; // Narrower to exclude neighboring sprite
            } else if (index == 1) {
                // Blue character with weapon
                src.x = 60; // Position of second sprite, but include more space
                src.y = 0;
                src.w = 52; // Wider to include weapon
                src.h = 44;
            } else {
                // Fallback to normal sprite rendering for other indices
                src = getSpriteRect(index);
            }
            
            // Create a destination rectangle that preserves aspect ratio
            float ratio = cast(float)src.w / src.h;
            int width, height;
            
            if (maxWidth / ratio <= maxHeight) {
                width = maxWidth;
                height = cast(int)(width / ratio);
            } else {
                height = maxHeight;
                width = cast(int)(height * ratio);
            }
            
            // Center the sprite in its cell
            int offsetX = (maxWidth - width) / 2;
            int offsetY = (maxHeight - height) / 2;
            
            SDL_Rect dst = SDL_Rect(x + offsetX, y + offsetY, width, height);
            SDL_RenderCopy(renderer, texture, &src, &dst);
        }


        int getColumns() {
            return columns;
        }
        
        int getRows() {
            return rows;
        }
        
        void destroy() {
            if (texture !is null) {
                SDL_DestroyTexture(texture);
                texture = null;
            }
        }
        
        ~this() {
            destroy();
        }
}
