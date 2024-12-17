# Turn-Based-System-Plugin
A flexible Turn Based System for Godot version 4.x

⚠️ Version 1.0 is still in progress (planned for the end of the year) ⚠️

<img src="documentation/images/full_system_3D.png" width="400"/>  <img src="documentation/images/full_system_2D.png" width="387"/>


## 🌟 Highlights
- 2D and 3D Support
- Full system:
  	- Turn Combat Control
	- Targeting System
	- Command menu
	- Player Status Container
   	- Turn Order Bar
- Different turn based combat systems:
	- classic
	- value based
	- dynamic

## 🚀 Quick start
1. Add <img src="addons/Turn_Based_System/assets/icons/groupControl.png" width="16"/> **_TurnBasedController Node_** to your main scene to activate the Turn Based System
2. Add <img src="addons/Turn_Based_System/assets/icons/agent.png" width="16"/> **_[TurnBasedAgent Node](#agent)_** to your Characters (Player & Enemy)<br />
3. Add **_classic_command_menu Scene_** as a child of a canvas layer in your main scene
4. **optional** Add **_classic_turn_order_bar Scene_** as a child of a canvas layer in your main scene 
5. **optional** Add **_classic_status_container Scene_** as a child of a canvas layer in your main scene 

<img src="documentation/images/scene_structure_example.png" width="200" />

## 📖 More Information
### Agent
The Agent needs the character resource where the Commands (attack/skill/item resources) are saved.
The TurnOrderValue will be checked in the character Resource too. <br />
<br />
<img src="documentation/images/Character_resource_example.png" width="400" />

### Command / Skill Resource:
For the targeting system and the command menu to work, the skill resource must have certain variables.<br />
There are 2 options for this:

1. you extend your skill with the CommandResource:
<img src="documentation/images/setup_own_skills_1.png" width="400"/>
2. you put the variables in your skill resource:
<img src="documentation/images/setup_own_skills_2.png" width="400"/>

### Classic Command Menu Scene
This is a scene and have to add with "instantiate child scene" (not with "add child node")

### Turn Order Bar Scene *optional*
This is a scene and have to add with "instantiate child scene" (not with "add child node")

### Classic Player Stats Container *optional*
This is a scene and have to add with "instantiate child scene" (not with "add child node")

### Character Setup:<br />
<img src="documentation/images/Character_code_example.png" width="400"/>

## ⬇️ Installation
If you don't have a "addons" folder in your project tree:

	copy the "addons" folder in your project tree
	
elif you have a "addons" folder already:

	copy the "Turn_Based_System" folder in your "addons" folder

At the end it should look like this:

<img src="res://documentation/images/plugin_installation_screen.png"/>

## 💭 Feedback and Contributing
You are always welcome to open issues for improvements or bugs:
https://github.com/derdrache/Turn-Based-System-Plugin/issues

Let's discuss wishes and improvements:
https://github.com/derdrache/Turn-Based-System-Plugin/discussions

or with a pull request to extend the code (there are no guidelines)
