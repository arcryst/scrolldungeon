# ScrollDungeon

A unique dungeon crawler where you scroll through procedurally generated layers, each presenting different challenges and rewards.

## Game Features

- Procedurally generated dungeon layers
- Different layer types: Combat, Loot, Shop, and Events
- Touch/mouse controls for scrolling through layers
- Dynamic difficulty scaling with depth
- Resource management (Health and Gold)

## Development Setup

This game is built with Godot 4.x. To set up the development environment:

1. Install [Godot 4.x](https://godotengine.org/download)
2. Clone this repository
3. Open the project in Godot
4. Run the game from the main scene

## Project Structure

- `scenes/`: Game scenes and level layouts
  - `main/`: Main game scene
  - `ui/`: UI scenes
  - `layers/`: Layer templates
- `scripts/`: Game logic and systems
  - `game/`: Core game systems
  - `ui/`: UI controllers
  - `utils/`: Utility scripts
- `assets/`: Game assets
  - `audio/`: Sound effects and music
  - `textures/`: Images and sprites

## Controls

- Swipe Up/Down or use Arrow Keys to navigate layers
- Click/Tap the action button to interact with layers
- Space to quick-test layers (debug) 