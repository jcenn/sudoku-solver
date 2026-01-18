## Simple program for solving sudoku
Implemented in [Odin](https://github.com/odin-lang/Odin) using [Raylib](https://github.com/raysan5/raylib) for the UI.

Makes use of the [wave function collapse](https://en.wikipedia.org/wiki/Model_synthesis) algorithm to solve provided sudoku puzzles.

Example solve on the hardest sudoku I could find on [sudokuoftheday.com](https://www.sudokuoftheday.com)

[sudoku_solver.webm](https://github.com/user-attachments/assets/d602a622-295c-4403-a20e-cb843f6dffdf)

Dark colored numbers represent values that are set (either by hand before running the program or by the algorithm)

Grey numbers represent how many possible states a cell has at that moment

When a grey number goes down to zero it turns red to represent an invalid state (a cell cannot have zero possible values in a correctly made sudoku) 

After encountering an invalid state program backtracks to the last choice it made and tries to pick a different path

## Dependencies
- Odin compiler
- Raylib

If you have nix installed on your system then all dependencies can be installed from the provided `flake.nix` file. To do so just run `nix develop` in the project directory.

## How to run
After cloning the repository run `odin run .` in the project directory to run the program or `odin build .` to build it.

After the application starts you will be able to input values by hovering your mouse over the desired cell and pressing one of the number keys on your keyboard.

After you inputting starting values you can press the space key to run the solver
