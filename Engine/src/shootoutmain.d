/++
    Main entry point for the standalone shootout game.
    
    This module provides the entry point for running the shootout game
    directly, parsing command line arguments to determine which map to load.
    
    See_Also:
        $(LINK2 shootout.html, Shootout game module)
+/
module shootoutmain;
import std.stdio;
import shootout;

/++
    Main entry point for the shootout game.
    
    Parses command line arguments to determine which map file to load
    and passes it to the runGame function.
    
    Params:
        args = Command line arguments (first is executable path, second is map path)
+/
void main(string[] args) {
    if (args.length < 2) {
        writeln("Usage: shootout <tilemap.dat>");
        return;
    }
    runGame(args[1]);
}
