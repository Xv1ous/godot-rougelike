# Godot Roguelike

A roguelike dungeon crawler game built with Godot 4.5. Features procedurally generated dungeons with connected rooms, enemy combat, and exploration mechanics.

## Features

- **Procedural Dungeon Generation**: Dynamically generated dungeons with connected rooms and hallways
- **Room System**: Multiple room types including spawn rooms, intermediate rooms, special rooms, and end rooms
- **Hallway Connections**: Rooms are connected with procedurally generated hallways/corridors
- **Enemy Combat**: Fight against various enemies (slimes, goblins, flying creatures)
- **State Machine**: Character movement and combat using a state machine pattern
- **Navigation System**: Automatic navigation mesh generation for AI pathfinding

## Requirements

- Godot Engine 4.5 or later
- Windows/Linux/macOS

## Installation

1. Clone the repository:
```bash
git clone https://github.com/Xv1ous/godot-rougelike.git
cd godot-rougelike
```

2. Open the project in Godot 4.5:
   - Launch Godot Engine
   - Click "Import" and select the `project.godot` file
   - Or open Godot and navigate to the project folder

## Running the Game

1. Open the project in Godot
2. Set the main scene to `res://UI/menu.tscn` (already configured)
3. Press F5 or click the "Play" button to run the game

## Project Structure

```
Rougelike godot4/
├── Asset/                          # Game assets (sprites, tilesets, fonts)
│   └── v1.1 dungeon crawler 16X16 pixel pack/
├── Character/                     # Player and enemy characters
│   ├── player.gd                  # Player controller
│   ├── character.gd               # Base character class
│   ├── Enemies/                   # Enemy types (slime, goblin, flying creature)
│   └── States/                    # State machine for character behavior
├── Rooms/                         # Dungeon generation and room management
│   ├── rooms.gd                   # Main room generation script
│   ├── room.gd                    # Base room class
│   ├── Spawn_room.gd              # Spawn room implementation
│   ├── hallway.gd                 # Hallway/corridor generation
│   ├── dungeon_generator.gd      # Alternative dungeon generator
│   └── door.gd                    # Door mechanics
├── UI/                            # User interface
│   ├── menu.gd                    # Main menu
│   ├── ui.gd                      # Game UI
│   └── health_display.gd          # Health bar display
├── game.gd                        # Main game script
└── project.godot                  # Godot project configuration
```

## Key Scripts

### Room Generation (`Rooms/rooms.gd`)
- Generates procedural dungeons with multiple room types
- Creates hallways/corridors between connected rooms
- Manages room placement and connections

### Room System (`Rooms/room.gd`)
- Base room class with enemy spawning
- Entrance/exit management
- Door control system

### Hallway System (`Rooms/hallway.gd`)
- Generates horizontal and vertical hallways
- Creates navigation meshes for pathfinding
- Connects rooms seamlessly

## Controls

- **Arrow Keys / WASD**: Move character
- **Mouse Click**: Attack

## Room Types

- **Spawn Rooms**: Starting rooms where the player begins
- **Intermediate Rooms**: Regular combat rooms with enemies
- **Special Rooms**: Rare rooms with special features
- **End Rooms**: Final rooms in each level

## Dungeon Generation

The dungeon generator creates:
- A spawn room at the start
- Multiple intermediate rooms connected by hallways
- Special rooms randomly placed
- An end room at the final level

Rooms are connected with procedurally generated corridors that ensure proper navigation between rooms.

## Development

### Testing
- Use `Rooms/dungeon_generator_test.tscn` to test dungeon generation
- Adjust parameters in the test scene to see different dungeon layouts

### Adding New Rooms
1. Create a new room scene in the `Rooms/` folder
2. Add it to the appropriate array in `rooms.gd`:
   - `SPAWN_ROOMS` for spawn rooms
   - `INTERMEDIATE_ROOMS` for regular rooms
   - `SPECIAL_ROOMS` for special rooms
   - `END_ROOMS` for end rooms

## Assets

This project uses assets from:
- "v1.1 dungeon crawler 16X16 pixel pack" - Dungeon tiles and sprites
- Custom pixel art assets

## License

This project is open source. Please check individual asset licenses for art assets.

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests.

## Author

Xv1ous

## Acknowledgments

- Godot Engine community
- Pixel art asset creators

