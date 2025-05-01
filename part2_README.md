# Part 2

The **key** components for your project are:

1. The Dlang based engine that does the heavy lifting and management of game objects and resources -- this is likely similar to your PSETS 07-09.
2. An editor or supporting tools for building games
   - (e.g. A GUI editor that shows your scene and game objects, a GUI-based tile editor, a GUI-based world editor, a sprite animation tool, etc.)
   - i.e. You should have some 'tooling' that otherwise generates data for your engine. Someone should be able to build or layout scenes for your game using tooling (i.e. your engine should not just be D code, but some tooling supporting the engine).
4. A game built in your engine (i.e. a classic or original game) with 3 'scenes'.

## Technical Requirements

The following are the technical requirements of your game engine. There is significant freedom in how you achieve them, but I would like you to apply these techniques in your engine.

- [ ] Implement a resource manager
- [ ] Implement a GUI-based editor/environment for assisting building a game (e.g. A tilemap editor, 2D animation preview tool, etc.)
	- This tool need not be implemented in Dlang, but should otherwise generate data that your Dlang engine can use.
- [ ] Your engine must be data-driven
  - [ ] Scripts of some kind should be loaded for the gameplay logic (e.g. hot reloaded from DLang, using PyD, or perhaps something eles)
  - [ ] Other configuration files (e.g. levels, scenes, etc.) should be loaded at run-time.
- [ ] Your engine should be component-based **or** use some other logical pattern for organizing game objects (At a minimum you should have a gameobject class).
- [ ] Something **extra** that gives your engine a 'wow' factor to show off to the TA's and instructors. Highlight this in your video (could be engineering, could be a gameplay mechanic that you designed your engine around, the goal is that it is something non-trivial)

## Gameplan

Given the above requirements, you may use this space to write some notes in. I suggest coming up with a timeline with your team members.

For example:

1. Week 1 - Start brainstorming, gather resources, from previous assignments and start planning
3. Week 2 - Implementation of Editor and main components of engine
4. Week 3 - Continue iterating on engine, and build prototype of game.
5. Week 4 to finish - Put together website and polish off bugs

### Timeline

*edit if you like*

1. *week 1 goals, and who will work on what*
2. *week 2 goals, and who will work on what*
3. *week 3 goals, and who will work on what*
4. *week 4 goals, and who will work on what*

## Inspiration!

### Previous Years Student Projects
For some inspiration, here are a few projects that are part of the "Hall of Fame" for this course. The best projects from this course will also be added to this list.

* Spring 2018
	* Tiny Engine
		* https://www.youtube.com/watch?v=TnI-HnQDgd8
	* Team gamecastle 
		* https://www.youtube.com/watch?v=iLSId4Tx2jk
	* Hop Man (Single person team)
	 	* https://www.youtube.com/watch?v=X2uWwe0J-KM
	* Eternal Engine
	 	* https://zilby.github.io/GameBuildingEngine/Website_Media/Pong.mp4
* Spring 2019
	* Game Engine -- with tools
		* https://cs5850-final.firebaseapp.com/media/final.webm
	* This was an asteroids game engine which focused on spatial partioning.
		* I liked the editor and the application of the spatial partioning with debug mode.
		* https://www.youtube.com/watch?v=4rWz3QXzrjA
	* This is a really clean example of how editing while the game plays is done
		* https://www.youtube.com/watch?v=pu8Gnf25rqk
* Spring 2021
	* Ninja Frogs -- https://www.youtube.com/watch?v=5u7iUSrOjEE
		* Nice demonstration of editor and game running. 
	* Ubihard Engine -- https://www.youtube.com/watch?v=5DtXk1N2WQM
		* Good demonstration of integrating tooling with editor.
	* Bubble Bobble Engine - https://www.youtube.com/watch?v=NZA6Ytb3WXg
		* Another nice enigne pulling together components.
	* Very polished game/engine
		* https://cottagelord.github.io/CS5850_Final_project_MoYuGamers/webpage/video/trailer.MP4
	* Few other examples
		* https://www.youtube.com/watch?v=qceC6PEyCpQ&t=8s
* Spring 2023
	* Ad Astra - https://www.youtube.com/watch?v=qceC6PEyCpQ&t=8s
		* Incorporated editors nicely, polished game, nice sprite animation -- video just needs some sound :)
	* LCX https://www.youtube.com/watch?v=sExL7KMcpvI
   		* Plished game, nice editor
* Spring 2024
	* Mario game
 		* editor https://www.youtube.com/watch?v=0qX9PpphhSE
		* Website example: https://bruggles718.github.io/
  		* **This is an A+ project that has everything needed, you may use this as a reference**
  	* Kev Engine
  		* https://www.youtube.com/watch?v=0gSlU9fl7Ug
  	 	* Nice video, nice engine, and nice editor that you can draw inspiration from (pauses game loop nicely when editing).
	* BoboTron Engine
  		* https://www.youtube.com/watch?v=-Ss1Ex8J2Ok
  	    	* Well produced, and nice engine   
* Fall 2024
  	* *Will your team be here in the future??*


