# Gemini Project Context: UPCSG_GAMEJAM

## Project Overview

This is a 2D game project developed using the **Godot Engine (v4.5.1)**. The project sets up a basic player character with movement and dashing capabilities.

The core of the project is the `Player` scene (`scenes/Player.tscn`), which is a `CharacterBody2D`. This player is then instanced in the main game scene (`scenes/MainScene.tscn`).

The player's functionality is defined by two GDScript files:
*   `scripts/PlayerMovement.gd`: Handles standard player movement based on user input (up, down, left, right). It includes acceleration and deceleration for smooth motion. It also triggers the dash action.
*   `scripts/PlayerDash.gd`: Manages the player's dash ability, including speed, duration, and cooldown logic.

The project follows a standard Godot structure, with scenes, scripts, and assets organized into their respective directories.

## Building and Running

This is a Godot project and must be run using the Godot editor.

1.  **Download Godot:** Ensure you have **Godot Engine version 4.5.1** installed. You can get it from the [official website](https://godotengine.org/) or on [Steam](https://store.steampowered.com/app/404790/Godot_Engine/).
2.  **Import Project:**
    *   Launch the Godot application.
    *   In the Project Manager, click the "Import" button.
    *   Navigate to the root directory of this repository and select it.
3.  **Run Project:**
    *   After importing, click "Import & Edit".
    *   Once the project is open in the editor, you can run the game by pressing the "Play" button (or F5).

The main scene is configured in `project.godot` to be `scenes/Player.tscn`.

## Development Conventions

### Code and Architecture
*   **Scripting Language:** All game logic is written in **GDScript**.
*   **Component-Based Logic:** Player abilities are separated into different nodes and scripts. For example, `PlayerMovement.gd` handles basic movement, while the `PlayerDash` child node and its `PlayerDash.gd` script handle the dash mechanic. This is a good pattern to follow for adding new abilities.
*   **Input Handling:** Player inputs are managed through Godot's Input Map, as seen in `project.godot`. New actions should be added there first.

### Version Control
*   **Branching:** As per the `README.md`, developers should create branches named after their last name.
*   **Commit Messages:** Commits should follow the format: `[FeatureName][LastName]commitmessage` (e.g., `[PlayerController][Antig] Added basic player movement`).
