/++
    Test runner for the shootout game.
    
    This module provides a test harness that runs multiple maps in sequence
    to verify game functionality across different level designs.
    
    See_Also:
        $(LINK2 shootout.html, Shootout game module)
+/
module testrun;

import shootout;
import std.stdio;

/++
    Main entry point for the test runner.
    
    Runs the shootout game with multiple predefined maps in sequence,
    allowing for testing of different level layouts and configurations.
+/
void main() {
    writeln("STARTING MULTI-ROUND GAME");

    string[3] maps = ["maps/tilemap1.dat", "maps/tilemap2.dat", "maps/tilemap3.dat"];
    foreach (mapPath; maps) {
        writeln("Running: ", mapPath);
        runGame(mapPath);
    }

    writeln("ALL ROUNDS COMPLETE");
}
