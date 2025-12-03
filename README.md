# Godot Roguelike

A roguelike dungeon crawler game built with Godot 4.5. Features procedurally generated dungeons with connected rooms, enemy combat, and exploration mechanics.

## Features

- **Procedural Dungeon Generation**: Dynamically generated dungeons with connected rooms
- **Room System**: Multiple room types including spawn rooms, intermediate rooms, special rooms, and end rooms
- **Enemy Combat**: Fight against various enemies (slimes, goblins, flying creatures)
- **Pickup System**: Collect potions and items that spawn when rooms are cleared
  - Health Potions: Restore health
  - Speed Potions: Temporarily increase movement speed
  - Incivility Potions: Deal damage (poison effect)
- **Knockback System**: Dynamic knockback mechanics for both player and enemies when taking damage
- **State Machine**: Character movement and combat using a state machine pattern
- **Navigation System**: Automatic navigation mesh generation for AI pathfinding
- **Item Data System**: Centralized item definitions for easy expansion

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
2. Set the main scene to `res://UI/Scenes/menu.tscn` (already configured)
3. Press F5 or click the "Play" button to run the game

## Project Structure

```
Rougelike godot4/
├── Asset/                          # Game assets (sprites, tilesets, fonts)
│   └── v1.1 dungeon crawler 16X16 pixel pack/
├── Data/                           # Game data and configuration
│   └── item_data.gd                # Centralized item definitions (potions, effects)
├── Character/                      # Player and enemy characters
│   ├── Scenes/                     # Character scene files
│   │   ├── character.tscn          # Base character scene
│   │   ├── player.tscn             # Player scene
│   │   └── Enemies/                # Enemy scenes
│   │       ├── enemy.tscn
│   │       ├── goblin.tscn
│   │       ├── slime.tscn
│   │       ├── flying_creature.tscn
│   │       └── projectile.tscn
│   └── Scripts/                    # Character scripts
│       ├── character.gd            # Base character class
│       ├── player.gd               # Player controller
│       └── Enemies/                # Enemy scripts
│           ├── enemy.gd
│           ├── goblin.gd
│           ├── slime.gd
│           ├── flying_creature.gd
│           └── projectile.gd
│       └── States/                 # State machine for character behavior
│           ├── state_machine.gd
│           ├── state.gd
│           ├── idle.gd
│           └── walk.gd
├── Rooms/                          # Dungeon generation and room management
│   ├── Scenes/                     # Room scene files
│   │   ├── Room.tscn               # Base room scene
│   │   ├── Door.tscn               # Door scene
│   │   ├── PickupItem.tscn         # Pickup item scene
│   │   ├── Spawn_Room_A.tscn       # Spawn room variant A
│   │   └── Spawn_Room_B.tscn       # Spawn room variant B
│   └── Scripts/                    # Room scripts
│       ├── rooms.gd                # Main room generation script
│       ├── room.gd                 # Base room class
│       ├── PickupItem.gd           # Pickup item logic and effects
│       ├── Spawn_room.gd           # Spawn room implementation
│       └── door.gd                 # Door mechanics
├── UI/                             # User interface
│   ├── Scenes/                     # UI scene files
│   │   ├── menu.tscn               # Main menu scene
│   │   └── ui.tscn                 # Game UI scene
│   └── Scripts/                    # UI scripts
│       ├── menu.gd                 # Main menu script
│       ├── ui.gd                   # Game UI script
│       └── health_display.gd       # Health bar display
├── Scenes/                         # Main game scenes
│   └── game.tscn                   # Main game scene
├── Scripts/                        # Main game scripts
│   └── game.gd                     # Main game script
└── project.godot                   # Godot project configuration
```

## Key Scripts

### Room Generation (`Rooms/Scripts/rooms.gd`)
- Generates procedural dungeons with multiple room types
- Manages room placement and connections
- Handles room instantiation and navigation setup

### Room System (`Rooms/Scripts/room.gd`)
- Base room class with enemy spawning
- Entrance/exit management
- Door control system

### Character System (`Character/Scripts/character.gd`)
- Base character class with movement and knockback mechanics
- Shared properties for all characters (player and enemies)
- State machine integration

### Player Controller (`Character/Scripts/player.gd`)
- Player movement and input handling
- Combat system with sword attacks
- Health and invincibility system
- Knockback when hit by enemies

### Enemy System (`Character/Scripts/Enemies/enemy.gd`)
- Base enemy class with navigation support
- Health and invincibility system
- Knockback when hit by player

### Pickup System (`Rooms/Scripts/PickupItem.gd`)
- Pickup item spawning and collection
- Potion effects (heal, speed boost, damage)
- Automatic spawning when rooms are cleared

### Item Data System (`Data/item_data.gd`)
- Centralized item definitions
- Potion textures and effects configuration
- Easy to extend with new items

## Controls

- **Arrow Keys / WASD**: Move character
- **Mouse Click**: Attack
- **Charge Attack**: Hold mouse button for a more powerful attack

## Room Types

- **Spawn Rooms**: Starting rooms where the player begins
- **Intermediate Rooms**: Regular combat rooms with enemies
- **Special Rooms**: Rare rooms with special features
- **End Rooms**: Final rooms in each level

## Dungeon Generation

The dungeon generator creates:
- A spawn room at the start
- Multiple intermediate rooms
- Special rooms randomly placed
- An end room at the final level

Rooms are procedurally generated with proper navigation meshes for enemy pathfinding.

## Combat System

- **Player Attacks**: Click to perform basic attacks, hold for charge attacks
- **Knockback**: Both player and enemies are knocked back when taking damage
- **Invincibility Frames**: Brief invincibility after taking damage with visual feedback
- **Enemy AI**: Enemies use navigation system to chase the player

## Pickup System

When you clear a room (defeat all enemies), pickups automatically spawn at designated marker positions:

- **Health Potion** (Red): Restores 30 HP
- **Speed Potion** (Yellow): Increases movement speed by 1.5x for 10 seconds
- **Incivility Potion** (Green): Deals 20 damage (poison/toxic effect)

Pickups are spawned randomly (1-3 per cleared room) and can be collected by walking over them.

## Development

### Testing
- Run the game from the main menu to test dungeon generation
- Adjust parameters in `Rooms/Scripts/rooms.gd` to see different dungeon layouts

### Adding New Rooms
1. Create a new room scene in the `Rooms/Scenes/` folder
2. Add it to the appropriate array in `Rooms/Scripts/rooms.gd`:
   - `SPAWN_ROOMS` for spawn rooms
   - `INTERMEDIATE_ROOMS` for regular rooms
   - `SPECIAL_ROOMS` for special rooms
   - `END_ROOMS` for end rooms

### Adding New Enemies
1. Create a new enemy scene in `Character/Scenes/Enemies/`
2. Create a new enemy script in `Character/Scripts/Enemies/` that extends `Enemy`
3. Add the enemy scene to the `ENEMY_SCENES` array in `Rooms/Scripts/room.gd`

### Adding New Pickup Items
1. Add the item texture to `Data/item_data.gd` in the `PICKUP_TEXTURES` dictionary
2. Define the item's effect in the `PICKUP_EFFECTS` dictionary
3. Add pickup spawn markers to room scenes in the `PickupPosition` container
4. The pickup will automatically spawn when rooms are cleared

### Customizing Pickup Effects
Edit `Data/item_data.gd` to modify:
- Potion textures
- Heal amounts
- Speed boost multipliers and durations
- Damage values
- Add new effect types (damage boost, defense, etc.)

## Assets

This project uses assets from:
- **[Simple Dungeon Crawler 16x16 Pixel Pack](https://o-lobster.itch.io/simple-dungeon-crawler-16x16-pixel-pack)** by o-lobster - Dungeon tiles, sprites, and game assets

## License

This project is open source. Please check individual asset licenses for art assets.

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests.

## Author

Xv1ous

## Acknowledgments

- **Tutorial Series**: [Godot Roguelike Tutorial](https://www.youtube.com/watch?v=axMNUTmFEDA&list=PL2-ArCpIQtjELkyLKec8BaVVCeunuHSK9) - Followed for dungeon generation and game structure
- Godot Engine community
- Pixel art asset creators
