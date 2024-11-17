# Turn-Based-System-Plugin
 
A flexible Turn Based System for Godot version 4.x

## 🌟 Highlights
- 2D and 3D Support
- Different turn based combat systems:
	- classic
	- value based
	- dynamic

## 🚀 Usage
### <img src="addons/Turn_Based_System/assets/icons/groupControl.png" width="16"/> TurnBasedController - Add it to your main scene to activate the Turn Based System


### <img src="addons/Turn_Based_System/assets/icons/agent.png" width="16"/> TurnBasedAgent - Add it to your Character (Player or Enemy)
The Agent needs the character resource where the Commands (attack/skill/item resources) are saved.
The TurnOrderValue will be checked in the character Resource too. <br />
Like this:<br />
<img src="documentation/images/Character_resource_example.png" width="400" />
<br />

### <img src="addons/Turn_Based_System/assets/icons/VBoxContainer.svg" width="16"/> Command Menu - Add it in a Canvas Layer at the end of the main scene
The main command list have to be filled to get the Commands in the menu. It's a little complicated
In this List you set a Dictonary with the shown Command name (dict key) and the reference to your character resource (dict value)<br />
Example: [{"Attack": "basicAttack"}, {"Skills": "skills"}, {"Items": "items"}]<br />
<img src="documentation/images/CommandMenu_MainCommandList_example.png" width="200"/>

### <img src="addons/Turn_Based_System/assets/icons/sort.png" width="16"/> Turn Order Bar *optional* - Add it in a Canvas Layer at the end of the main scene<br />

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
https://github.com/derdrache/DragAndDrop3D/issues

Let's discuss wishes and improvements:
https://github.com/derdrache/DragAndDrop3D/discussions

or with a pull request to extend the code (there are no guidelines)
