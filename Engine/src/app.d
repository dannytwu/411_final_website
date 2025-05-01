/++
    Tile Editor Application module.
    
    This module implements the main tile editor application, providing
    a graphical interface for creating and editing game maps. It handles
    user input, rendering, and file operations for map editing.

    See_Also:
        $(LINK2 common.html, Common types),
        $(LINK2 spritesheet.html, SpriteSheet),
        $(LINK2 resourcemanager.html, ResourceManager)
+/
module app;

import std.stdio;

import std.string : fromStringz;

import bindbc.sdl;

import std.math : abs;

import std.algorithm : min;
import spritesheet;
import std.path : buildPath;
import std.process : spawnProcess, wait;
import std.array : array;
import std.algorithm : canFind, map, filter, count;
import std.path : buildPath, dirName;
import std.file : exists;
import std.algorithm : startsWith;

import resourcemanager;

// Constants for the application
enum {
    TILE_SIZE = 48,          // Size of each tile in pixels
    COLOR_COUNT = 8,         // Number of colors/tile types
    GRID_COLS = 32,          // Columns for the map
    GRID_ROWS = 32,          // Rows for the map
    PANEL_WIDTH = 200,       // Width of the side panel
    TOOLBAR_HEIGHT = 40      // Height of the toolbar
}

// UI states
enum ToolType {
    PLACE,
    ERASE,
    FILL,
    SELECT,
    SPRITE
}

//Game Objects
enum GameObjectType {
    NONE = -1,
    TERRAIN_RED = 0,   // Terrain types (using original color indices)
    TERRAIN_BLUE = 1,
    TERRAIN_GREEN = 2,
    TERRAIN_YELLOW = 3,
    PLAYER = 4,        // Repurpose purple for Player
    NPC = 5,           // Repurpose cyan for NPC
    ITEM = 6,          // Repurpose orange for Item
    CONSUMABLE = 7     // Repurpose brown for Consumable
}

/++
    Main application class for the tile editor.
    
    Handles window creation, event processing, rendering, and all editor functionality
    including tile placement, map editing, and launching the shootout game.
+/
struct TileEditorApp {
    // SDL Components
    SDL_Window* window = null;
    SDL_Renderer* renderer = null;
    
    /++
        Represents a single cell in the map grid.
        
        Contains both terrain type and optional sprite information.
    +/
    struct MapCell {
        /// Type of terrain for this cell
        int tileType = -1;     // -1 for empty
        /// Optional sprite to display on this cell (-1 for no sprite)
        int spriteType = -1;   // -1 for no sprite
    }

    int[] availableSprites = [0, 1];

    int selectedColor = 0;
    ToolType currentTool = ToolType.PLACE;
    MapCell[][] map;
    int selectedSprite = 0;
    bool showingSpritePanel = false;
    int spritePanelScrollY = 0;
    int lastSavedFileNumber = 0;

    // Window dimensions
    int windowWidth = TILE_SIZE * GRID_COLS + PANEL_WIDTH;
    int windowHeight = TILE_SIZE * GRID_ROWS + TOOLBAR_HEIGHT;
    
    // UI State
    bool isRunning = true;
    
    // Selection state
    bool isSelecting = false;
    int selectionStartX = -1;
    int selectionStartY = -1;
    //TileSheet
    TileSheet tileSheet;
    //Spritesheet
    SpriteSheet characterSheet;
    ResourceManager resources;
    
    // UI Components
    SDL_Rect toolbarRect;
    SDL_Rect sidebarRect;
    SDL_Rect gridRect;

    bool isPanning = false;
    int panStartX, panStartY;
    int offsetX = 0, offsetY = 0;
    float zoomFactor = 1.0;

    /++
        Creates a new tile editor application with the specified title.
        
        Params:
            title = Window title for the application
    +/
    this(string title) {
        // Initialize SDL
        if (SDL_Init(SDL_INIT_VIDEO) < 0) {
            writeln("SDL_Init failed: ", SDL_GetError().fromStringz);
            isRunning = false;
            return;
        }
        
        // Create window
        window = SDL_CreateWindow(
            cast(const char*)title.ptr,
            SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
            windowWidth, windowHeight,
            SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE
        );
        
        if (window is null) {
            writeln("SDL_CreateWindow failed: ", SDL_GetError().fromStringz);
            isRunning = false;
            return;
        }
        
        // Create renderer
        renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
        if (renderer is null) {
            writeln("SDL_CreateRenderer failed: ", SDL_GetError().fromStringz);
            isRunning = false;
            return;
        }
        
        // Initialize map with empty cells
        map.length = GRID_ROWS;
        foreach (ref row; map) {
            row.length = GRID_COLS;
            foreach (ref cell; row) {
                cell.tileType = 2; // Default to green (grass-like)
                cell.spriteType = -1; // No sprite
            }
        }
        
        // Set up UI component rectangles
        toolbarRect = SDL_Rect(0, 0, windowWidth, TOOLBAR_HEIGHT);
        sidebarRect = SDL_Rect(windowWidth - PANEL_WIDTH, TOOLBAR_HEIGHT, PANEL_WIDTH, windowHeight - TOOLBAR_HEIGHT);
        gridRect = SDL_Rect(0, TOOLBAR_HEIGHT, windowWidth - PANEL_WIDTH, windowHeight - TOOLBAR_HEIGHT);

	resources = new ResourceManager(renderer);
	initResources();
    }
        
    /++
        Initializes game resources by loading tilesheets and spritesheets.
        
        Loads the default tilesheet and character spritesheet from media files.
    +/
    void initResources() {
        // Load tilesheet
        tileSheet = resources.getTileSheet("default", "media/tilesheet.bmp");
        
        // Load character sheet
        characterSheet = resources.getSpriteSheet("characters", "media/spritesheet.bmp", 40, 48);
    }

    /++
        Renders the sprite selection panel for choosing character sprites.
        
        Displays available sprites with visual indicators and handles
        sprite selection through mouse interaction.
    +/
    void renderSpritePanel() {
        int panelTop = TOOLBAR_HEIGHT + 50;
        int panelHeight = windowHeight - panelTop - 10;
        
        // Draw panel background
        SDL_Rect panelRect = SDL_Rect(
            windowWidth - PANEL_WIDTH + 5, 
            panelTop, 
            PANEL_WIDTH - 10, 
            panelHeight
        );
        SDL_SetRenderDrawColor(renderer, 40, 40, 40, 255);
        SDL_RenderFillRect(renderer, &panelRect);
        
        // Set clip region to panel area
        SDL_RenderSetClipRect(renderer, &panelRect);
        
        // Calculate how many sprites can fit in a row
        int spriteSize = 60; // Larger size for better visibility
        int padding = 10;
        int spritesPerRow = (PANEL_WIDTH - 20) / (spriteSize + padding);
        if (spritesPerRow < 1) spritesPerRow = 1;
        
        // Draw only the two selected sprites
        for (int i = 0; i < availableSprites.length; i++) {
            int spriteIndex = availableSprites[i];
            int row = i / spritesPerRow;
            int col = i % spritesPerRow;
            
            int x = windowWidth - PANEL_WIDTH + 10 + col * (spriteSize + padding);
            int y = panelTop + 5 + row * (spriteSize + padding) + spritePanelScrollY;
            
            // Skip if outside visible area
            if (y + spriteSize < panelTop || y > panelTop + panelHeight) {
                continue;
            }
            
            // Draw sprite background with a color tint matching the character
            SDL_Rect spriteRect = SDL_Rect(x, y, spriteSize, spriteSize);
            
            // Highlight selected sprite
            if (spriteIndex == selectedSprite) {
                SDL_SetRenderDrawColor(renderer, 100, 150, 255, 255);
            } else {
                // Color background based on character (green for first, blue for second)
                if (spriteIndex == 0) {
                    SDL_SetRenderDrawColor(renderer, 40, 100, 40, 255); // Green tint
                } else {
                    SDL_SetRenderDrawColor(renderer, 40, 40, 100, 255); // Blue tint
                }
            }
            SDL_RenderFillRect(renderer, &spriteRect);
            
            // Draw border
            SDL_SetRenderDrawColor(renderer, 160, 160, 160, 255);
            SDL_RenderDrawRect(renderer, &spriteRect);
            
            // Draw sprite
            characterSheet.renderPlayerSprite(spriteIndex, x, y, spriteSize, spriteSize);
            
            // Add label underneath indicating character color
            SDL_SetRenderDrawColor(renderer, 200, 200, 200, 255);
            SDL_Rect textBg = SDL_Rect(x, y + spriteSize + 2, spriteSize, 15);
            SDL_RenderFillRect(renderer, &textBg);
            
            // Use simple line drawing to indicate character (would normally use SDL_ttf)
            SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
            if (spriteIndex == 0) {
                // Draw "GREEN" indicator
                int textX = x + 10;
                int textY = y + spriteSize + 8;
                // G
                SDL_RenderDrawLine(renderer, textX, textY-5, textX, textY+5);
                SDL_RenderDrawLine(renderer, textX, textY-5, textX+5, textY-5);
                SDL_RenderDrawLine(renderer, textX, textY+5, textX+5, textY+5);
                SDL_RenderDrawLine(renderer, textX+5, textY, textX+5, textY+5);
            } else {
                // Draw "BLUE" indicator
                int textX = x + 10;
                int textY = y + spriteSize + 8;
                // B
                SDL_RenderDrawLine(renderer, textX, textY-5, textX, textY+5);
                SDL_RenderDrawLine(renderer, textX, textY-5, textX+4, textY-5);
                SDL_RenderDrawLine(renderer, textX, textY, textX+4, textY);
                SDL_RenderDrawLine(renderer, textX, textY+5, textX+4, textY+5);
                SDL_RenderDrawLine(renderer, textX+4, textY-4, textX+4, textY-1);
                SDL_RenderDrawLine(renderer, textX+4, textY+1, textX+4, textY+4);
            }
        }
        
        // Reset clip region
        SDL_RenderSetClipRect(renderer, null);
    }

    /++
        Main application loop that processes events and renders the UI.
        
        Handles all user input, updates the application state, and
        renders the interface until the application is closed.
    +/
    void run() {
        SDL_Event event;
        
        while (isRunning) {
            // Process events
            while (SDL_PollEvent(&event) != 0) {
                switch (event.type) {
                    case SDL_QUIT:
                        isRunning = false;
                        break;
                        
                    case SDL_MOUSEBUTTONDOWN:
                        handleMouseDown(event.button.x, event.button.y, event.button.button);
                        break;
                        
                    case SDL_MOUSEBUTTONUP:
                        handleMouseUp(event.button.x, event.button.y, event.button.button);
                        break;
                        
                    case SDL_MOUSEMOTION:
                        handleMouseMotion(event.motion.x, event.motion.y, event.motion.state);
                        break;
                        
                    case SDL_KEYDOWN:
                        handleKeyPress(event.key.keysym.sym);
                        break;
                        
                    case SDL_WINDOWEVENT:
                        if (event.window.event == SDL_WINDOWEVENT_RESIZED) {
                            handleResize(event.window.data1, event.window.data2);
                        }
                        break;
                        
                    default:
                        break;
                }
            }
            
            // Render the UI
            render();
            
            // Cap frame rate
            SDL_Delay(16); // ~60 FPS
        }
    }
    
    /++
        Handles mouse button press events.
        
        Processes UI interactions including tool selection, color selection,
        and map editing operations based on the current tool.
        
        Params:
            x = Mouse X coordinate
            y = Mouse Y coordinate
            button = Which mouse button was pressed
    +/
    void handleMouseDown(int x, int y, ubyte button) {
        if (button == SDL_BUTTON_LEFT) {
            // Check if clicking in the toolbar (tool selection or color selection)
            if (y < TOOLBAR_HEIGHT) {
                int buttonWidth = 50; // Should match what's in renderToolbar
                
                // Check if clicking on tool buttons (5 tools)
                for (int i = 0; i < 5; i++) {
                    SDL_Rect toolRect = SDL_Rect(10 + i * (buttonWidth + 5), 4, buttonWidth, TOOLBAR_HEIGHT - 8);
                    if (x >= toolRect.x && x < toolRect.x + toolRect.w && 
                        y >= toolRect.y && y < toolRect.y + toolRect.h) {
                        currentTool = cast(ToolType)i;
                        return;
                    }
                }
                
                // Check if clicking on color buttons
                int colorStartX = 5 * (buttonWidth + 5) + 20; // Same as in renderToolbar
                int colorWidth = 30; // Same as in renderToolbar
                int colorSpacing = 35; // Same as in renderToolbar
                
                for (int i = 0; i < COLOR_COUNT; i++) {
                    SDL_Rect colorRect = SDL_Rect(colorStartX + i * colorSpacing, 4, colorWidth, TOOLBAR_HEIGHT - 8);
                    if (x >= colorRect.x && x < colorRect.x + colorRect.w && 
                        y >= colorRect.y && y < colorRect.y + colorRect.h) {
                        selectedColor = i;
                        return;
                    }
                }
            }
            // Check if clicking in the sidebar
            else if (x >= windowWidth - PANEL_WIDTH) {
                // Check sprite toggle button
                SDL_Rect spriteToggleRect = SDL_Rect(
                    windowWidth - PANEL_WIDTH + 10, 
                    TOOLBAR_HEIGHT + 10, 
                    PANEL_WIDTH - 20, 
                    30
                );
                
                if (x >= spriteToggleRect.x && x < spriteToggleRect.x + spriteToggleRect.w && 
                    y >= spriteToggleRect.y && y < spriteToggleRect.y + spriteToggleRect.h) {
                    showingSpritePanel = !showingSpritePanel;
                    return;
                }
                
                // Handle sprite selection if panel is open
                if (showingSpritePanel) {
                    int panelTop = TOOLBAR_HEIGHT + 50;
                    int spriteSize = 60;
                    int padding = 10;
                    int spritesPerRow = (PANEL_WIDTH - 20) / (spriteSize + padding);
                    
                    // Calculate which sprite was clicked
                    int relX = x - (windowWidth - PANEL_WIDTH + 10);
                    int relY = y - (panelTop + 5) - spritePanelScrollY;
                    
                    int col = relX / (spriteSize + padding);
                    int row = relY / (spriteSize + padding);
                    
                    if (col >= 0 && col < spritesPerRow) {
                        int index = row * spritesPerRow + col;
                        if (index >= 0 && index < availableSprites.length) {
                            selectedSprite = availableSprites[index]; // Use the actual sprite index
                            currentTool = ToolType.SPRITE;
                            return;
                        }
                    }
                }
            }
            // Otherwise, we're in the grid
            else if (x < windowWidth - PANEL_WIDTH && y >= TOOLBAR_HEIGHT) {
                // Convert screen coordinates to grid coordinates
                int gridX = cast(int)((x - offsetX) / (TILE_SIZE * zoomFactor));
                int gridY = cast(int)((y - TOOLBAR_HEIGHT - offsetY) / (TILE_SIZE * zoomFactor));
                
                // Check if within bounds
                if (gridX >= 0 && gridX < GRID_COLS && gridY >= 0 && gridY < GRID_ROWS) {
                    if (currentTool == ToolType.PLACE || currentTool == ToolType.ERASE) {
                        placeOrEraseTile(x, y);
                    } else if (currentTool == ToolType.FILL) {
                        fillArea(x, y);
                    } else if (currentTool == ToolType.SELECT) {
                        // Selection tool logic
                        if (!isSelecting) {
                            // First click - mark selection start point
                            isSelecting = true;
                            selectionStartX = gridX;
                            selectionStartY = gridY;
                        } else {
                            // Second click - fill the rectangle
                            fillRectangle(selectionStartX, selectionStartY, gridX, gridY);
                            isSelecting = false;
                            selectionStartX = -1;
                            selectionStartY = -1;
                        }
                    } else if (currentTool == ToolType.SPRITE) {
                        placeSprite(gridX, gridY);
                    }
                }
            }
        } else if (button == SDL_BUTTON_MIDDLE) {
            // Start panning
            isPanning = true;
            panStartX = x;
            panStartY = y;
        }
    }

    void handleMouseUp(int x, int y, ubyte button) {
    }
    
    void handleMouseMotion(int x, int y, uint state) {
        if (isPanning) {
            // Update offset based on pan distance
            offsetX += (x - panStartX);
            offsetY += (y - panStartY);
            panStartX = x;
            panStartY = y;
        } else if ((state & SDL_BUTTON_LMASK) && 
                x < windowWidth - PANEL_WIDTH && y >= TOOLBAR_HEIGHT) {
            
            // Convert screen coordinates to grid coordinates
            int gridX = cast(int)((x - offsetX) / (TILE_SIZE * zoomFactor));
            int gridY = cast(int)((y - TOOLBAR_HEIGHT - offsetY) / (TILE_SIZE * zoomFactor));
            
            // Check if within bounds
            if (gridX >= 0 && gridX < GRID_COLS && gridY >= 0 && gridY < GRID_ROWS) {
                if (currentTool == ToolType.PLACE || currentTool == ToolType.ERASE) {
                    placeOrEraseTile(x, y);
                } else if (currentTool == ToolType.SPRITE) {
                    placeSprite(gridX, gridY);
                }
            }
        }
        
        // Add scroll handling for sprite panel
        if (showingSpritePanel && x >= windowWidth - PANEL_WIDTH) {
            if (state & SDL_BUTTON_RMASK) {
                spritePanelScrollY += y - panStartY;
                panStartY = y;
            }
        }
    }
    
    void handleMouseWheel(int y) {
        // If mouse is over sprite panel, scroll it
        int mouseX, mouseY;
        SDL_GetMouseState(&mouseX, &mouseY);
        
        if (showingSpritePanel && mouseX >= windowWidth - PANEL_WIDTH) {
            spritePanelScrollY += y * 20;
        } else {
            // Zoom in/out based on scroll direction
            if (y > 0) {
                zoomFactor *= 1.1;
            } else if (y < 0) {
                zoomFactor *= 0.9;
            }
            
            // Clamp zoom
            if (zoomFactor < 0.25) zoomFactor = 0.25;
            if (zoomFactor > 4.0) zoomFactor = 4.0;
        }
    }
    
    void handleKeyPress(SDL_Keycode key) {
        switch (key) {
            case SDLK_ESCAPE:
                // Cancel selection if active, otherwise quit
                if (isSelecting) {
                    isSelecting = false;
                    selectionStartX = -1;
                    selectionStartY = -1;
                } else {
                    isRunning = false;
                }
                break;
                
            case SDLK_s:
                saveTileMap(null);
                break;
                
            case SDLK_l:
                loadTileMap(null);
                break;
                
            case SDLK_1:
                currentTool = ToolType.PLACE;
                break;
                
            case SDLK_2:
                currentTool = ToolType.ERASE;
                break;
                
            case SDLK_3:
                currentTool = ToolType.FILL;
                break;
                
            case SDLK_4:
                currentTool = ToolType.SELECT;
                break;
                
            case SDLK_5:
                currentTool = ToolType.SPRITE;
                break;
 
            case SDLK_SPACE:
                runShootout();
                break;
               
            default:
                break;
        }
    }

void runShootout() {
    // Check if the map has at least one of each player type (0 and 1)
    bool hasGreenPlayer = false;
    bool hasBluePlayer = false;
    
    // Scan the map for player characters
    foreach (row; map) {
        foreach (cell; row) {
            if (cell.spriteType == 0) hasGreenPlayer = true;
            if (cell.spriteType == 1) hasBluePlayer = true;
        }
    }
    
    // Only run shootout if we have both player types
    if (hasGreenPlayer && hasBluePlayer) {
        // Save current map
        string tempMapFile = "maps/temp_shootout_map.dat";
        saveTileMap(tempMapFile);
        
        writeln("Saving map and attempting to run shootout game...");
        
        // Try different approaches to find and run shootout.d
        
        // First, look for shootout executable in the same directory
        string[] shootoutPaths = [
            "./shootout",            // Current directory
            "../shootout",           // Parent directory
            "./bin/shootout",        // bin subdirectory
            "../bin/shootout",       // parent/bin directory
            buildPath(dirName(dirName(thisExePath())), "shootout") // Application root
        ];
        
        bool launched = false;
        
        // Try to run the compiled executable if it exists
        foreach (path; shootoutPaths) {
            if (exists(path) || exists(path ~ ".exe")) {
                string exePath = exists(path) ? path : path ~ ".exe";
                writeln("Found shootout executable at: ", exePath);
                try {
                    auto pid = spawnProcess([exePath, tempMapFile]);
                    launched = true;
                    writeln("Started shootout game with map: ", tempMapFile);
                    break;
                } catch (Exception e) {
                    writeln("Failed to launch shootout: ", e.msg);
                }
            }
        }
        
        // If no executable found, try to compile and run the D file
        if (!launched) {
            string[] shootoutSourcePaths = [
                "./shootout.d",          // Current directory
                "../shootout.d",         // Parent directory
                "./src/shootout.d",      // src subdirectory
                "../src/shootout.d"      // parent/src directory
            ];
            
            foreach (path; shootoutSourcePaths) {
                if (exists(path)) {
                    writeln("Found shootout source at: ", path);
                    try {
                        // Compile and run with rdmd (if available)
                        auto pid = spawnProcess(["rdmd", path, tempMapFile]);
                        writeln("Compiled and started shootout game with map: ", tempMapFile);
                        launched = true;
                        break;
                    } catch (Exception e) {
                        try {
                            // Try direct compilation as fallback
                            auto compileProcess = spawnProcess(["dmd", "-run", path, tempMapFile]);
                            writeln("Compiled and started shootout game with DMD and map: ", tempMapFile);
                            launched = true;
                            break;
                        } catch (Exception e2) {
                            writeln("Failed to compile and run shootout: ", e2.msg);
                        }
                    }
                }
            }
        }
        
        if (!launched) {
            writeln("Could not find or run shootout program. Please ensure shootout executable or shootout.d is in a known location.");
        }
    } else {
        writeln("Cannot start shootout: Map must have at least one green player (sprite 0) and one blue player (sprite 1)");
    }
}

// Helper function to get the executable path
string thisExePath() {
    import core.runtime;
    return Runtime.args[0];
}

    
    void handleResize(int width, int height) {
        windowWidth = width;
        windowHeight = height;
        
        // Update UI component rectangles
        toolbarRect = SDL_Rect(0, 0, windowWidth, TOOLBAR_HEIGHT);
        sidebarRect = SDL_Rect(windowWidth - PANEL_WIDTH, TOOLBAR_HEIGHT, PANEL_WIDTH, windowHeight - TOOLBAR_HEIGHT);
        gridRect = SDL_Rect(0, TOOLBAR_HEIGHT, windowWidth - PANEL_WIDTH, windowHeight - TOOLBAR_HEIGHT);
    }
    
    void placeOrEraseTile(int x, int y) {
        // Convert screen coordinates to grid coordinates with zoom/pan
        int gridX = cast(int)((x - offsetX) / (TILE_SIZE * zoomFactor));
        int gridY = cast(int)((y - TOOLBAR_HEIGHT - offsetY) / (TILE_SIZE * zoomFactor));
        
        // Check if within bounds
        if (gridX >= 0 && gridX < GRID_COLS && gridY >= 0 && gridY < GRID_ROWS) {
            if (currentTool == ToolType.PLACE) {
                map[gridY][gridX].tileType = selectedColor;
            } else if (currentTool == ToolType.ERASE) {
                map[gridY][gridX].tileType = -1; // -1 for empty/erased
                map[gridY][gridX].spriteType = -1; // Also erase sprite
            }
        }
    }
        
    void fillArea(int x, int y) {
        // Convert screen coordinates to grid coordinates with zoom/pan
        int gridX = cast(int)((x - offsetX) / (TILE_SIZE * zoomFactor));
        int gridY = cast(int)((y - TOOLBAR_HEIGHT - offsetY) / (TILE_SIZE * zoomFactor));
        
        // Check if within bounds
        if (gridX >= 0 && gridX < GRID_COLS && gridY >= 0 && gridY < GRID_ROWS) {
            int targetTileType = map[gridY][gridX].tileType;
            floodFill(gridX, gridY, targetTileType, selectedColor);
        }
    }
    
    void floodFill(int x, int y, int targetTileType, int replacementTileType) {
        // Don't do anything if target is already the replacement
        if (targetTileType == replacementTileType) return;
        
        // Check if current position is valid and has target tile type
        if (x < 0 || x >= GRID_COLS || y < 0 || y >= GRID_ROWS || 
            map[y][x].tileType != targetTileType) {
            return;
        }
        
        // Replace current tile type
        map[y][x].tileType = replacementTileType;
        
        // Recursively fill in all four directions
        floodFill(x + 1, y, targetTileType, replacementTileType);
        floodFill(x - 1, y, targetTileType, replacementTileType);
        floodFill(x, y + 1, targetTileType, replacementTileType);
        floodFill(x, y - 1, targetTileType, replacementTileType);
    }

    
    void fillRectangle(int startX, int startY, int endX, int endY) {
        // Ensure start coordinates are smaller than end coordinates
        if (startX > endX) {
            int temp = startX;
            startX = endX;
            endX = temp;
        }

        if (startY > endY) {
            int temp = startY;
            startY = endY;
            endY = temp;
        }

        // Clamp to grid boundaries
        if (startX < 0) startX = 0;
        if (startY < 0) startY = 0;
        if (endX >= GRID_COLS) endX = GRID_COLS - 1;
        if (endY >= GRID_ROWS) endY = GRID_ROWS - 1;

        // Fill the rectangle with the current color
        for (int y = startY; y <= endY; y++) {
            for (int x = startX; x <= endX; x++) {
                if (selectedColor >= 0) {
                    map[y][x].tileType = selectedColor;
                }
            }
        }
    }
    
    void render() {
        // Clear the renderer
        SDL_SetRenderDrawColor(renderer, 40, 44, 52, 255);
        SDL_RenderClear(renderer);
        
        // Render UI components
        renderToolbar();
        renderSidebar();
        renderGrid();
        
        // Add these lines to test your sheets
        //renderTileTest();
        //renderSpriteTest();
        
        // Present the renderer
        SDL_RenderPresent(renderer);
    }
    
void renderToolbar() {
    // Draw toolbar background
    SDL_SetRenderDrawColor(renderer, 60, 63, 65, 255);
    SDL_RenderFillRect(renderer, &toolbarRect);
    
    // Draw tool selection with distinctive shapes
    string[] toolNames = ["Place", "Erase", "Fill", "Select", "Sprite"];
    int buttonWidth = 50; // Make buttons slightly narrower to fit better
    int buttonHeight = TOOLBAR_HEIGHT - 8;
    int buttonY = 4;
    
    for (int i = 0; i < toolNames.length; i++) {
        SDL_Rect toolRect = SDL_Rect(10 + i * (buttonWidth + 5), buttonY, buttonWidth, buttonHeight);
        
        // Highlight selected tool
        if (currentTool == cast(ToolType)i) {
            SDL_SetRenderDrawColor(renderer, 100, 150, 255, 255);
        } else {
            SDL_SetRenderDrawColor(renderer, 80, 80, 80, 255);
        }
        
        SDL_RenderFillRect(renderer, &toolRect);
        
        // Draw border
        SDL_SetRenderDrawColor(renderer, 200, 200, 200, 255);
        SDL_RenderDrawRect(renderer, &toolRect);
        
        // Draw distinctive icon for each tool in white
        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        
        int iconX = toolRect.x + buttonWidth/2;
        int iconY = toolRect.y + buttonHeight/2;
        int iconSize = 10; // Slightly smaller icons
        
        switch(i) {
            case 0: // Place - draw a plus symbol
                SDL_RenderDrawLine(renderer, iconX - iconSize, iconY, iconX + iconSize, iconY);
                SDL_RenderDrawLine(renderer, iconX, iconY - iconSize, iconX, iconY + iconSize);
                break;
                
            case 1: // Erase - draw an X
                SDL_RenderDrawLine(renderer, iconX - iconSize, iconY - iconSize, iconX + iconSize, iconY + iconSize);
                SDL_RenderDrawLine(renderer, iconX - iconSize, iconY + iconSize, iconX + iconSize, iconY - iconSize);
                break;
                
            case 2: // Fill - draw a filled square
                SDL_Rect fillIcon = SDL_Rect(iconX - iconSize, iconY - iconSize, iconSize*2, iconSize*2);
                SDL_RenderFillRect(renderer, &fillIcon);
                break;
                
            case 3: // Select - draw rectangle outline
                SDL_Rect selectIcon = SDL_Rect(iconX - iconSize, iconY - iconSize, iconSize*2, iconSize*2);
                SDL_RenderDrawRect(renderer, &selectIcon);
                break;
                
            case 4: // Sprite - draw character icon
                SDL_Rect spriteIcon = SDL_Rect(iconX - iconSize, iconY - iconSize, iconSize*2, iconSize*2);
                SDL_RenderDrawRect(renderer, &spriteIcon);
                // Draw a simple stick figure
                SDL_RenderDrawLine(renderer, iconX, iconY - iconSize + 3, iconX, iconY + iconSize - 3); // Body
                SDL_RenderDrawLine(renderer, iconX - iconSize + 2, iconY, iconX + iconSize - 2, iconY); // Arms
                SDL_RenderDrawLine(renderer, iconX, iconY + 2, iconX - 3, iconY + iconSize - 3); // Left leg
                SDL_RenderDrawLine(renderer, iconX, iconY + 2, iconX + 3, iconY + iconSize - 3); // Right leg
                // Draw head
                SDL_Rect headRect = SDL_Rect(iconX - 3, iconY - iconSize + 1, 5, 5);
                SDL_RenderFillRect(renderer, &headRect);
                break;
                
            default:
                break;
        }
        
        // Add tool number below icon
        int numX = toolRect.x + buttonWidth/2;
        int numY = toolRect.y + buttonHeight - 6;
        
        // Draw a horizontal line and number of dots to represent the tool number
        for (int d = 0; d < i+1; d++) {
            SDL_Rect dot = SDL_Rect(numX - i*2 + d*4, numY, 3, 3);
            SDL_RenderFillRect(renderer, &dot);
        }
    }
    
    // Draw color palette with clear numbers - make it start further to the right
    int colorStartX = 5 * (buttonWidth + 5) + 20; // Start after all 5 tools with some padding
    int colorWidth = 30; // Narrower color swatches
    int colorSpacing = 35; // Less space between colors
    
    for (int i = 0; i < COLOR_COUNT; i++) {
        // Color swatch
        SDL_Rect colorRect = SDL_Rect(colorStartX + i * colorSpacing, buttonY, colorWidth, buttonHeight);
        
        // Set color for this palette entry
        setTileColor(renderer, i);
        SDL_RenderFillRect(renderer, &colorRect);
        
        // Draw selection indicator
        if (selectedColor == i) {
            SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
            SDL_RenderDrawRect(renderer, &colorRect);
            
            // Draw second highlight rect
            SDL_Rect innerRect = SDL_Rect(colorRect.x + 2, colorRect.y + 2, colorRect.w - 4, colorRect.h - 4);
            SDL_RenderDrawRect(renderer, &innerRect);
        } else {
            SDL_SetRenderDrawColor(renderer, 100, 100, 100, 255);
            SDL_RenderDrawRect(renderer, &colorRect);
        }
        
        // Add color number marker
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255); // Black for contrast
        
        // Draw dots to represent the color number
        for (int d = 0; d < i+1; d++) {
            SDL_Rect dot = SDL_Rect(colorRect.x + 4 + d*4, colorRect.y + buttonHeight - 8, 3, 3);
            SDL_RenderFillRect(renderer, &dot);
        }
    }
    
    // Add keyboard shortcuts hint - draw small row of key indicators at bottom
    int keyY = TOOLBAR_HEIGHT - 13;
    SDL_SetRenderDrawColor(renderer, 200, 200, 200, 255);
    
    // Show 1-5 key shortcuts for tools
    for (int i = 0; i < 5; i++) {
        SDL_Rect keyRect = SDL_Rect(15 + i * (buttonWidth + 5) + buttonWidth/2 - 5, keyY, 10, 10);
        SDL_RenderDrawRect(renderer, &keyRect);
        
        // Draw key number
        int numX = keyRect.x + 5;
        int numY = keyRect.y + 5;
        
        // Draw dots to represent the key number
        for (int d = 0; d < i+1; d++) {
            SDL_Rect dot = SDL_Rect(numX - i + d*2, numY, 2, 2);
            SDL_RenderFillRect(renderer, &dot);
        }
    }
}

	
    // Update renderSidebar to include sprite panel toggle and sprite panel
    void renderSidebar() {
        // Draw sidebar background
        SDL_SetRenderDrawColor(renderer, 50, 54, 57, 255);
        SDL_RenderFillRect(renderer, &sidebarRect);
        
        // Draw divider line
        SDL_SetRenderDrawColor(renderer, 100, 100, 100, 255);
        SDL_RenderDrawLine(renderer, 
            windowWidth - PANEL_WIDTH, TOOLBAR_HEIGHT, 
            windowWidth - PANEL_WIDTH, windowHeight);
        
        // Add button to toggle sprite panel
        SDL_Rect spriteToggleRect = SDL_Rect(
            windowWidth - PANEL_WIDTH + 10, 
            TOOLBAR_HEIGHT + 10, 
            PANEL_WIDTH - 20, 
            30
        );
        
        // Draw sprite toggle button
        if (showingSpritePanel) {
            SDL_SetRenderDrawColor(renderer, 80, 130, 180, 255);
        } else {
            SDL_SetRenderDrawColor(renderer, 80, 80, 80, 255);
        }
        SDL_RenderFillRect(renderer, &spriteToggleRect);
        
        // Draw border
        SDL_SetRenderDrawColor(renderer, 200, 200, 200, 255);
        SDL_RenderDrawRect(renderer, &spriteToggleRect);
        
        // Draw text "Sprites" (as a line for now)
        SDL_RenderDrawLine(renderer, 
            spriteToggleRect.x + 10, 
            spriteToggleRect.y + spriteToggleRect.h/2, 
            spriteToggleRect.x + spriteToggleRect.w - 10, 
            spriteToggleRect.y + spriteToggleRect.h/2
        );
        
        // If sprite panel is open, draw the sprite selection
        if (showingSpritePanel) {
            renderSpritePanel();
        }
    }
    

    void renderGrid() {
        // Set clip region to grid area
        SDL_RenderSetClipRect(renderer, &gridRect);
        
        // Draw checkerboard background for empty tiles
        SDL_SetRenderDrawColor(renderer, 30, 30, 30, 255);
        SDL_RenderFillRect(renderer, &gridRect);
        
        // Calculate visible grid region based on zoom/pan
        int visibleStartX = cast(int)(-offsetX / (TILE_SIZE * zoomFactor));
        int visibleStartY = cast(int)(-offsetY / (TILE_SIZE * zoomFactor));
        int visibleEndX = visibleStartX + cast(int)((windowWidth - PANEL_WIDTH) / (TILE_SIZE * zoomFactor)) + 2;
        int visibleEndY = visibleStartY + cast(int)((windowHeight - TOOLBAR_HEIGHT) / (TILE_SIZE * zoomFactor)) + 2;
        
        // Clamp to grid boundaries
        if (visibleStartX < 0) visibleStartX = 0;
        if (visibleStartY < 0) visibleStartY = 0;
        if (visibleEndX > GRID_COLS) visibleEndX = GRID_COLS;
        if (visibleEndY > GRID_ROWS) visibleEndY = GRID_ROWS;
        
        // Draw visible tiles and sprites
        for (int y = visibleStartY; y < visibleEndY; y++) {
            for (int x = visibleStartX; x < visibleEndX; x++) {
                // Calculate screen position with zoom/pan
                int screenX = cast(int)(x * TILE_SIZE * zoomFactor) + offsetX;
                int screenY = cast(int)(y * TILE_SIZE * zoomFactor) + offsetY + TOOLBAR_HEIGHT;
                int screenSize = cast(int)(TILE_SIZE * zoomFactor);
                
                // IMPORTANT: Use screenSize for both width and height
                SDL_Rect tileRect = SDL_Rect(screenX, screenY, screenSize, screenSize);
                
                // Draw tile background
                int tileType = map[y][x].tileType;
                
                // Skip empty tiles
                if (tileType >= 0) {
                    // Draw tile
                    setTileColor(renderer, tileType);
                    SDL_RenderFillRect(renderer, &tileRect);
                } else {
                    // Draw checkerboard pattern for empty tiles
                    if ((x + y) % 2 == 0) {
                        SDL_SetRenderDrawColor(renderer, 40, 40, 40, 255);
                    } else {
                        SDL_SetRenderDrawColor(renderer, 30, 30, 30, 255);
                    }
                    SDL_RenderFillRect(renderer, &tileRect);
                }
                
                // Draw grid lines
                SDL_SetRenderDrawColor(renderer, 60, 60, 60, 255);
                SDL_RenderDrawRect(renderer, &tileRect);
                
                // Draw sprite if there is one
                int spriteType = map[y][x].spriteType;
                if (spriteType >= 0) {
                    characterSheet.renderPlayerSprite(spriteType, screenX, screenY, screenSize, screenSize);
                }
            }
        }
    
        if (isSelecting) {
            // Convert grid coordinates to screen coordinates
            int screenStartX = cast(int)(selectionStartX * TILE_SIZE * zoomFactor) + offsetX;
            int screenStartY = cast(int)(selectionStartY * TILE_SIZE * zoomFactor) + offsetY + TOOLBAR_HEIGHT;
            
            // Get current mouse position for the end point of selection
            int mouseX, mouseY;
            SDL_GetMouseState(&mouseX, &mouseY);
            
            // Convert mouse position to grid coordinates
            int currentGridX = cast(int)((mouseX - offsetX) / (TILE_SIZE * zoomFactor));
            int currentGridY = cast(int)((mouseY - TOOLBAR_HEIGHT - offsetY) / (TILE_SIZE * zoomFactor));
            
            // Clamp to grid
            if (currentGridX < 0) currentGridX = 0;
            if (currentGridY < 0) currentGridY = 0;
            if (currentGridX >= GRID_COLS) currentGridX = GRID_COLS - 1;
            if (currentGridY >= GRID_ROWS) currentGridY = GRID_ROWS - 1;
            
            // Calculate screen rectangle for selection
            int screenEndX = cast(int)(currentGridX * TILE_SIZE * zoomFactor) + offsetX + cast(int)(TILE_SIZE * zoomFactor);
            int screenEndY = cast(int)(currentGridY * TILE_SIZE * zoomFactor) + offsetY + TOOLBAR_HEIGHT + cast(int)(TILE_SIZE * zoomFactor);
            
            // Draw selection rectangle
            SDL_SetRenderDrawColor(renderer, 255, 255, 255, 150);
            SDL_Rect selectionRect = SDL_Rect(
                min(screenStartX, screenEndX),
                min(screenStartY, screenEndY),
                abs(screenEndX - screenStartX),
                abs(screenEndY - screenStartY)
            );
            
            // Draw semi-transparent fill to show selection area
            SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
            SDL_SetRenderDrawColor(renderer, 100, 200, 255, 80);
            SDL_RenderFillRect(renderer, &selectionRect);
            
            // Draw selection border
            SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_NONE);
            SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
            SDL_RenderDrawRect(renderer, &selectionRect);
        }
        
        // Reset clip region
        SDL_RenderSetClipRect(renderer, null);
    }


    // method to place sprites
    void placeSprite(int gridX, int gridY) {
        if (gridX >= 0 && gridX < GRID_COLS && gridY >= 0 && gridY < GRID_ROWS) {
            map[gridY][gridX].spriteType = selectedSprite;
        }
    }


    void setTileColor(SDL_Renderer* r, int id) {
        switch (id) {
            case 0: SDL_SetRenderDrawColor(r, 255, 0, 0, 255); break;         // Red (0)
            case 1: SDL_SetRenderDrawColor(r, 0, 0, 255, 255); break;         // Blue (1)
            case 2: SDL_SetRenderDrawColor(r, 0, 255, 0, 255); break;         // Green (2)
            case 3: SDL_SetRenderDrawColor(r, 255, 255, 0, 255); break;       // Yellow (3)
            case 4: SDL_SetRenderDrawColor(r, 128, 0, 128, 255); break;       // Purple (4)
            case 5: SDL_SetRenderDrawColor(r, 0, 255, 255, 255); break;       // Cyan (5)
            case 6: SDL_SetRenderDrawColor(r, 255, 165, 0, 255); break;       // Orange (6)
            case 7: SDL_SetRenderDrawColor(r, 165, 42, 42, 255); break;       // Brown (7)
            default: SDL_SetRenderDrawColor(r, 70, 70, 70, 255); break;       // Dark gray
        }
    }
    
string getNextSaveFilename() {
    import std.file : exists;
    import std.format : format;
    import std.path : baseName, buildPath;
    import std.regex : regex, matchFirst;
    import std.conv : to;
    import std.algorithm : max;
    import std.file : dirEntries, SpanMode;

    int highestNumber = 0;
    try {
        auto filePattern = regex(r"tilemap(\d+)\.dat");
        foreach (string filename; dirEntries("maps", "tilemap*.dat", SpanMode.shallow)) {
            auto matches = matchFirst(baseName(filename), filePattern);
            if (!matches.empty) {
                int fileNumber = to!int(matches[1]);
                highestNumber = max(highestNumber, fileNumber);
            }
        }
    } catch (Exception e) {
        writeln("Warning: Error scanning for existing files: ", e.msg);
    }
    this.lastSavedFileNumber = highestNumber + 1;
    return buildPath("maps", format("tilemap%d.dat", this.lastSavedFileNumber));
}

string getMostRecentSaveFilename() {
    import std.file : exists;
    import std.format : format;
    import std.path : baseName, buildPath;
    import std.regex : regex, matchFirst;
    import std.conv : to;
    import std.algorithm : max;
    import std.file : dirEntries, SpanMode;

    int highestNumber = 0;
    try {
        auto filePattern = regex(r"tilemap(\d+)\.dat");
        foreach (string filename; dirEntries("maps", "tilemap*.dat", SpanMode.shallow)) {
            auto matches = matchFirst(baseName(filename), filePattern);
            if (!matches.empty) {
                int fileNumber = to!int(matches[1]);
                highestNumber = max(highestNumber, fileNumber);
            }
        }
    } catch (Exception e) {
        writeln("Warning: Error scanning for existing files: ", e.msg);
    }
    if (highestNumber > 0) {
        this.lastSavedFileNumber = highestNumber;
        return buildPath("maps", format("tilemap%d.dat", highestNumber));
    }
    return buildPath("maps", "tilemap1.dat");
}

void saveTileMap(string customFilename = null) {
    try {
        string filename = customFilename;
        if (filename is null) {
            filename = getNextSaveFilename();
        } else if (!filename.startsWith("maps/")) {
            filename = buildPath("maps", filename);
        }
        auto file = File(filename, "w");
        file.writefln("%d %d", GRID_ROWS, GRID_COLS);
        foreach (row; this.map) {
            foreach (cell; row) {
                file.writef("%d %d ", cell.tileType, cell.spriteType);
            }
            file.writeln();
        }
        writeln("Map saved to ", filename);
    } catch (Exception e) {
        writeln("Error saving map: ", e.msg);
    }
}

void loadTileMap(string customFilename = null) {
    try {
        string filename = customFilename;
        if (filename is null) {
            filename = getMostRecentSaveFilename();
        } else if (!filename.startsWith("maps/")) {
            filename = buildPath("maps", filename);
        }
        import std.file : exists;
        if (!exists(filename)) {
            writeln("File ", filename, " does not exist. Cannot load map.");
            return;
        }
        auto file = File(filename, "r");
        int rows, cols;
        if (file.readf("%d %d\n", &rows, &cols) != 2) {
            writeln("Error: Invalid file format - couldn't read dimensions");
            return;
        }
        if (rows <= 0 || cols <= 0 || rows > 1000 || cols > 1000) {
            writeln("Error: Invalid map dimensions in file");
            return;
        }
        map.length = rows;
        foreach (ref row; map) {
            row.length = cols;
        }
        for (int y = 0; y < rows; y++) {
            string line = file.readln();
            import std.string : split;
            auto values = line.split();
            int valueIndex = 0;
            for (int x = 0; x < cols && valueIndex + 1 < values.length; x++) {
                import std.conv : to;
                try {
                    map[y][x].tileType = values[valueIndex++].to!int;
                    map[y][x].spriteType = values[valueIndex++].to!int;
                } catch (Exception e) {
                    writeln("Error parsing data at row ", y, ", col ", x);
                }
            }
        }
        writeln("Map loaded from ", filename);
    } catch (Exception e) {
        writeln("Error loading map: ", e.msg);
    }
}

    void cleanupTempFiles() {
        import std.file : exists, remove;
        import std.stdio : writeln;
        
	string tempMapFile = "maps/temp_shootout_map.dat";
        
        // Check if the temporary map file exists and delete it
        if (exists(tempMapFile)) {
            try {
                remove(tempMapFile);
                writeln("Cleaned up temporary map file: ", tempMapFile);
            } catch (Exception e) {
                writeln("Failed to clean up temporary map file: ", e.msg);
            }
        }
    }


void renderSpriteTest() {
    // Render some character sprites as a test
    // Top row characters
    characterSheet.renderSprite(0, 0, 10, 100);  // First character
    characterSheet.renderSprite(1, 0, 60, 100);  // Second character
    characterSheet.renderSprite(2, 0, 110, 100); // Third character
    
    // Different row/column combinations
    characterSheet.renderSprite(0, 1, 10, 150);  // Character from second row
    characterSheet.renderSprite(1, 2, 60, 150);  // Different character
}
void renderTileTest() {
    // Render some test tiles to check if they're working
    tileSheet.renderTile("green_tree_large", 10, 50);
    tileSheet.renderTile("orange_panel", 100, 50);
    tileSheet.renderTile("blue_water", 300, 50);
    tileSheet.renderTile("wood_crate_large", 400, 50);
}


    ~this() {
      if (resources !is null) resources.cleanup();
      cleanupTempFiles();
      if (renderer) SDL_DestroyRenderer(renderer);
      if (window) SDL_DestroyWindow(window);
      SDL_Quit();
    }
}

void main() {
    auto app = TileEditorApp("Tile Editor");
    if (app.isRunning) {
        app.run();
    }
}