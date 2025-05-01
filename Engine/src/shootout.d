/++
    Shootout game module implementing the main game loop.
    
    This module provides the core game functionality for the shootout game,
    handling SDL initialization, game loop, and rendering.
    
    See_Also:
        $(LINK2 gamescene.html, GameScene),
        $(LINK2 player.html, Player)
+/
module shootout;

import std.stdio;
import bindbc.sdl;
import spritesheet;
import common;
import gameobject;
import cell;
import player;
import projectile;
import gamescene;

/++
    Runs the shootout game with the specified map file.
    
    Initializes SDL, creates the game window and renderer, loads the
    specified map, and runs the main game loop until completion.
    
    Params:
        mapPath = Path to the map file to load
+/
void runGame(string mapPath) {
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        writeln("SDL_Init failed");
        return;
    }

    SDL_Window* window = SDL_CreateWindow("Shootout", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 
                                         WINDOW_WIDTH, WINDOW_HEIGHT, SDL_WINDOW_SHOWN);
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

    SpriteSheet spriteSheet = new SpriteSheet(renderer);
    spriteSheet.load("media/spritesheet.bmp", 40, 48);

    GameScene scene = new GameScene(renderer, spriteSheet);
    scene.loadMap(mapPath);

    SDL_Event event;
    bool running = true;
    while (running) {
        while (SDL_PollEvent(&event) != 0) {
            if (event.type == SDL_QUIT) running = false;
        }

        auto keystate = SDL_GetKeyboardState(null);
        scene.update(keystate);

        if (scene.isGameOver()) break;

        SDL_SetRenderDrawColor(renderer, 20, 20, 20, 255);
        SDL_RenderClear(renderer);
        scene.render();
        SDL_RenderPresent(renderer);
        SDL_Delay(1000 / 60);
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
}