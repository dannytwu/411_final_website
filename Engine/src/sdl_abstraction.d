/++
    SDL library initialization and management module.
    
    This module handles loading and initializing the SDL library,
    providing error handling and cleanup functionality. It ensures
    the SDL library is properly loaded before the application starts.

    See_Also:
        $(LINK2 https://www.libsdl.org/, SDL Library)
+/
module sdl_abstraction;

import std.stdio;
import std.string;

import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

/// Global variable for SDL support level
const SDLSupport ret;

/++
    Module constructor that initializes SDL.
    
    Loads the SDL library appropriate for the current platform
    and initializes all SDL subsystems. Provides error reporting
    if SDL cannot be loaded or initialized.
+/
shared static this() {
    // Load the SDL libraries from bindbc-sdl
    // on the appropriate operating system
    version(Windows){
        writeln("Searching for SDL on Windows");
        ret = loadSDL("SDL2.dll");
    }
    version(OSX){
        writeln("Searching for SDL on Mac");
        ret = loadSDL();
    }
    version(linux){ 
        writeln("Searching for SDL on Linux");
        ret = loadSDL();
    }

    // Error if SDL cannot be loaded
    if(ret != sdlSupport){
        writeln("error loading SDL library");    
        foreach( info; loader.errors){
            writeln(info.error,':', info.message);
        }
    }
    if(ret == SDLSupport.noLibrary){
        writeln("error no library found");    
    }
    if(ret == SDLSupport.badLibrary){
        writeln("Eror badLibrary, missing symbols, perhaps an older or very new version of SDL is causing the problem?");
    }
    // Initialize SDL
    if(SDL_Init(SDL_INIT_EVERYTHING) !=0){
        writeln("SDL_Init: ", fromStringz(SDL_GetError()));
    }
}

/++
    Module destructor that cleans up SDL.
    
    Ensures SDL is properly shut down when the application terminates.
+/
shared static ~this() {
    // Quit the SDL Application 
    SDL_Quit();
    writeln("Ending application--good bye!");
}
