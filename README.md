# Xonix for Ada

A classic implementation of the arcade game Xonix, written in Ada using the `ncurses` library.

<img width="991" height="768" alt="ksnip_20260425-211026_result" src="https://github.com/user-attachments/assets/06eb83a0-6135-4fda-9aac-4a9567ad351d" />

## Game Description

The goal of Xonix is to capture a certain percentage of the game field (standardly 75% or more) while avoiding enemies.

- **Player**: Controlled with arrow keys or WASD.
- **Balls**: Bounce inside the empty area. If a ball hits your trace while you are drawing, you lose a life.
- **Land Enemies**: Move along the edges of the captured area. If they hit you, you lose a life.
- **Capture**: Move from the "safe" captured area into the empty area to draw a trace. Returning to the captured area closes the trace and fills the enclosed territory that doesn't contain any balls.

- **Level Selection**: Choose your starting level (1-10) before the game begins. Use arrow keys to change and Enter/LF to confirm.
- **Improved Navigation**: After completing a level or losing all lives, simply press any key to proceed.
- **Dynamic Animations**: Includes blinking effects for death and victory states.
- **Centralized Settings**: All game constants are centralized in `src/settings.ads`.
- **CI/CD Integrated**: Automated build and release workflow via GitHub Actions.

## Build and Run

### Prerequisites

- GNAT (Ada compiler)
- `libncursesada-dev` library

### Building

To build the project, use `gprbuild`:

```bash
gprbuild xonix.gpr
```

The executable will be placed in the `bin/` directory.

### Running

```bash
./bin/xonix
```

## Controls

- **Arrows / WASD**: Move the player
- **Enter**: Confirm level selection
- **R**: Restart current level (during game)
- **Q**: Quit to menu (during game) / Quit level selection
- **Any Key**: Proceed after level completion or game over
