/++
    Base game object module defining core entity functionality.
    
    This module provides the foundation for all interactive game entities,
    implementing common features like positioning and collision detection.
    All game objects in the engine inherit from this base class.

    See_Also:
        $(LINK2 player.html, Player),
        $(LINK2 projectile.html, Projectile),
        $(LINK2 cell.html, Cell),
        $(LINK2 common.html, Position type)

    Example:
    ---
    // Creating a custom enemy
    class Enemy : GameObject {
        this(Position pos) { super(pos); }
        override void update() { /* enemy behavior */ }
    }
    ---
+/
module gameobject;

import bindbc.sdl;
import spritesheet;
import common;

/++
    Base class for all game entities.
    
    Provides core functionality that all game objects need:
    - Position tracking
    - Active state management
    - Collision detection
    - Rendering interface
    
    Derived classes should override update() and render() to implement
    specific behaviors and appearances.

    Note:
        The Position type is defined in common.d and represents
        grid coordinates, not pixel coordinates.
+/
class GameObject {
    Position pos;
    bool active = true;
    
    /++
        Creates a new game object at the specified position.
        
        Params:
            pos = Starting grid position for this object
            
        By default, objects are created in an active state.
    +/
    this(Position pos) {
        this.pos = pos;
    }
    
    /++
        Updates this object's state for the current frame.
        
        Base implementation does nothing. Derived classes should override
        this to implement their specific update logic.
        
        Called once per frame during the game loop.
    +/
    void update() { }
    
    /++
        Renders this object to the screen.
        
        Params:
            renderer = SDL rendering context
            spriteSheet = Sprite sheet containing object textures
            
        Base implementation does nothing. Derived classes must override
        this to provide visual representation.
    +/
    void render(SDL_Renderer* renderer, SpriteSheet spriteSheet) { }
    
    /++
        Checks if this object is colliding with another.
        
        Params:
            other = The other GameObject to check collision with
            
        Returns:
            true if the objects occupy the same grid position
            
        Note:
            Uses grid-based collision detection. Objects collide
            when they share the same grid cell.
    +/
    bool isColliding(GameObject other) {
        return pos == other.pos;
    }
}
