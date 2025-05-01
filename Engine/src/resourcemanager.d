/++
    A centralized resource management system for handling game assets.
    
    The ResourceManager class provides efficient loading and caching of game resources
    like spritesheets and tilesheets. It ensures resources are loaded only once and
    properly managed throughout the game's lifecycle.

    See_Also:
        $(LINK2 spritesheet.html, SpriteSheet),
        $(LINK2 tilesheet.html, TileSheet)

    Example:
    ---
    auto resources = new ResourceManager(renderer);
    auto spriteSheet = resources.getSpriteSheet("characters", "media/spritesheet.bmp", 40, 48);
    auto tileSheet = resources.getTileSheet("default", "media/tilesheet.bmp");
    ---
+/
module resourcemanager;

import std.stdio;
import std.file : exists;
import std.string : fromStringz;
import bindbc.sdl;
import spritesheet;

/++
    Resource manager for centralized asset loading.
    
    Members:
        renderer = SDL renderer instance used for texture loading
        tileSheets = Cache of loaded TileSheet instances
        spriteSheets = Cache of loaded SpriteSheet instances

    Throws:
        Exception if resource files cannot be loaded
        Exception if SDL texture creation fails
+/
class ResourceManager {
    private {
        SDL_Renderer* renderer;
        TileSheet[string] tileSheets;
        SpriteSheet[string] spriteSheets;
        // Could add more resource types like sounds, fonts, etc.
    }

    /++
        Constructs a new ResourceManager instance.
        
        Params:
            renderer = SDL renderer used for loading textures
    +/
    this(SDL_Renderer* renderer) {
        this.renderer = renderer;
    }

    /++
        Load or retrieve a tilesheet from cache.
        
        Params:
            id = Unique identifier for the tilesheet
            path = File path to the tilesheet image
            tileWidth = Width of each tile (default: 48)
            tileHeight = Height of each tile (default: 48)
            
        Returns: The loaded or cached TileSheet instance, or null if loading fails
    +/
    TileSheet getTileSheet(string id, string path, int tileWidth = 48, int tileHeight = 48) {
        if (id in tileSheets) {
            return tileSheets[id];
        }

        auto sheet = new TileSheet(renderer);
        if (!sheet.load(path)) {
            writeln("Failed to load tilesheet from: ", path);
            writeln("File exists: ", exists(path));
            
            // Try an alternative path as backup
            string altPath = "../" ~ path;
            writeln("Trying alternative path: ", altPath);
            writeln("File exists: ", exists(altPath));
            
            if (!sheet.load(altPath)) {
                writeln("Failed to load tilesheet from alternative path");
                return null;
            }
        }
        
        tileSheets[id] = sheet;
        writeln("Tilesheet '", id, "' loaded successfully");
        return sheet;
    }
    
    /++
        Load or retrieve a spritesheet from cache.
        
        Params:
            id = Unique identifier for the spritesheet
            path = File path to the spritesheet image
            spriteWidth = Width of each sprite (default: 40)
            spriteHeight = Height of each sprite (default: 48)
            
        Returns: The loaded or cached SpriteSheet instance, or null if loading fails
    +/
    SpriteSheet getSpriteSheet(string id, string path, int spriteWidth = 40, int spriteHeight = 48) {
        if (id in spriteSheets) {
            return spriteSheets[id];
        }

        auto sheet = new SpriteSheet(renderer);
        if (!sheet.load(path, spriteWidth, spriteHeight)) {
            writeln("Failed to load spritesheet from: ", path);
            writeln("File exists: ", exists(path));
            
            // Try an alternative path as backup
            string altPath = "../" ~ path;
            writeln("Trying alternative path: ", altPath);
            writeln("File exists: ", exists(altPath));
            
            if (!sheet.load(altPath, spriteWidth, spriteHeight)) {
                writeln("Failed to load spritesheet from alternative path");
                return null;
            }
        }
        
        spriteSheets[id] = sheet;
        writeln("Spritesheet '", id, "' loaded successfully");
        return sheet;
    }
    
    /++
        Check if a tilesheet exists in the cache.
        
        Params:
            id = Identifier of the tilesheet to check
            
        Returns: true if the tilesheet exists, false otherwise
    +/
    bool hasTileSheet(string id) {
        return (id in tileSheets) != null;
    }
    
    /++
        Check if a spritesheet exists in the cache.
        
        Params:
            id = Identifier of the spritesheet to check
            
        Returns: true if the spritesheet exists, false otherwise
    +/
    bool hasSpriteSheet(string id) {
        return (id in spriteSheets) != null;
    }
    
    /++
        Retrieve a tilesheet from cache without loading.
        
        Params:
            id = Identifier of the tilesheet to retrieve
            
        Returns: The cached TileSheet instance, or null if not found
    +/
    TileSheet getTileSheetById(string id) {
        if (id in tileSheets) {
            return tileSheets[id];
        }
        return null;
    }
    
    /++
        Retrieve a spritesheet from cache without loading.
        
        Params:
            id = Identifier of the spritesheet to retrieve
            
        Returns: The cached SpriteSheet instance, or null if not found
    +/
    SpriteSheet getSpriteSheetById(string id) {
        if (id in spriteSheets) {
            return spriteSheets[id];
        }
        return null;
    }
    
    /++
        Clean up all loaded resources.
        
        This method destroys all loaded tilesheets and spritesheets,
        freeing associated SDL textures and memory.
    +/
    void cleanup() {
        foreach (sheet; tileSheets) {
            if (sheet !is null) sheet.destroy();
        }
        
        foreach (sheet; spriteSheets) {
            if (sheet !is null) sheet.destroy();
        }
        
        tileSheets = null;
        spriteSheets = null;
    }
}
