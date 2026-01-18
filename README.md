## Simple program for solving sudoku
Implemented in Odin using Raylib for UI
Makes use of the wave function collapse algorithm

Example solve on the hardest sudoku I could find on [sudokuoftheday.com](https://www.sudokuoftheday.com)

[sudoku_solver.webm](https://github.com/user-attachments/assets/d602a622-295c-4403-a20e-cb843f6dffdf)

Dark colored numbers represent values that are set (either by hand before running the program or by the algorithm)

Grey numbers represent how many possible states a cell has at that moment

When a grey number goes down to zero it turns red to represent an invalid state (a cell cannot have zero possible values in a correctly made sudoku) 

After encountering an invalid state program backtracks to the last choice it made and tries to pick a different path


## How to run
After cloning the repository run `odin run .` in the project directory to run the program or `odin build .` to build it.
