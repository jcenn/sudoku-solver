package main

import "core:strings"
import "core:math"
import "core:fmt"
import rl "vendor:raylib"
// TODO:
// [ ] Draw a grid
// [ ] Iitialize wfc grid
// [ ] Allow user to input numbers and collapse wfc state

gridSize :: 9
cellSize :: 80
gridPaddingX :: 50
gridPaddingY :: 50

lineWidth :: f32(2.0)
borderLineWidth :: f32(4.0)

GameState :: enum {
    Initial,
    Solving,
    Solved,
}

init_grid :: proc(solver: ^WfcSolver) {
    collapse_to_state(solver.grid, 0, 0, 4)
    collapse_to_state(solver.grid, 0, 1, 9)
    collapse_to_state(solver.grid, 1, 1, 1)
    collapse_to_state(solver.grid, 1, 2, 8)
    collapse_to_state(solver.grid, 2, 2, 3)

    collapse_to_state(solver.grid, 0, 5, 5)
    collapse_to_state(solver.grid, 2, 5, 8)
    
    collapse_to_state(solver.grid, 1, 8, 7)
    
    collapse_to_state(solver.grid, 3, 0, 6)
    collapse_to_state(solver.grid, 5, 0, 8)
    collapse_to_state(solver.grid, 4, 1, 3)
    collapse_to_state(solver.grid, 5, 1, 2)
    collapse_to_state(solver.grid, 4, 2, 1)

    collapse_to_state(solver.grid, 3, 3, 8)
    collapse_to_state(solver.grid, 3, 4, 1)
    collapse_to_state(solver.grid, 4, 5, 7)
    collapse_to_state(solver.grid, 5, 5, 4)
    
    collapse_to_state(solver.grid, 4, 8, 9)
    collapse_to_state(solver.grid, 5, 8, 6)

    collapse_to_state(solver.grid, 6, 1, 8)
    collapse_to_state(solver.grid, 8, 1, 6)
    collapse_to_state(solver.grid, 8, 2, 2)

    collapse_to_state(solver.grid, 6, 4, 3)
    collapse_to_state(solver.grid, 8, 4, 5)

    collapse_to_state(solver.grid, 8, 6, 8)
    collapse_to_state(solver.grid, 6, 7, 2)
    collapse_to_state(solver.grid, 6, 8, 4)
    collapse_to_state(solver.grid, 8, 8, 3)
}

targetScreenHeight :: 800

is_solved :: proc (solver: ^WfcSolver) -> bool{
    // check wfc properties
    for row in solver.grid {
        for v in row {
            if !v.collapsed && v.possible_state_count == 0 {
                return false
            }
        }
    }
    
    // check with sudoku rules
    for row, y in solver.grid {
        for cell, x in row {
            // check row
            for c, x2 in row {
                if x == x2 {
                    continue
                }
                if cell.collapsed_value == c.collapsed_value {
                    return false
                }
            }
            
            // check column
            for y2 in 0..<9 {
                if y2 == y {
                    continue
                }
                c := solver.grid[y2][x]

                if cell.collapsed_value == c.collapsed_value {
                    return false
                }
            }

            // check sub_grid

            subgridStartX := x/3
            subgridStartY := y/3

            for cell_y in (subgridStartY * 3)..<(subgridStartY * 3 + 3) {
                for cell_x in (subgridStartX * 3)..<(subgridStartX * 3 + 3) {
                    if cell_y == y && cell_x == x {
                        continue
                    }
                    if solver.grid[cell_y][cell_x].collapsed_value == cell.collapsed_value {
                        return false
                    }
                }
            }
        }
    }
    return true
}

main :: proc(){
    key_value_map := make(map[rl.KeyboardKey]int)
    defer delete(key_value_map)

    key_value_map[.ONE] = 1
    key_value_map[.TWO] = 2
    key_value_map[.THREE] = 3
    key_value_map[.FOUR] = 4
    key_value_map[.FIVE] = 5
    key_value_map[.SIX] = 6
    key_value_map[.SEVEN] = 7
    key_value_map[.EIGHT] = 8
    key_value_map[.NINE] = 9

    current_state := GameState.Initial

    wfc_solver := init_wfc_solver()
    
    // cleanup of inner arrays
    defer for _, i in wfc_solver.grid
    {
        delete(wfc_solver.grid[i])
    }

    for row in wfc_solver.grid {
        for &cell in row {
            cell.collapsed = false
            cell.possible_state_count = 0
            cell.states = 0
            for i in 1..=9{
                add_possible_state(&cell, uint(i))
            }
        }
    }
    // init_grid(wfc_solver)

    rl.SetConfigFlags({.WINDOW_RESIZABLE})
    rl.InitWindow(800, 800, "sudoku solver")

    rl.SetTargetFPS(60)
    for(!rl.WindowShouldClose()){
        switch current_state {
        case .Initial: 
            // if users presses a number key write that number into cell under mouse cursor
            for k,v in key_value_map {
                if rl.IsKeyPressed(k){
                    mousePos := rl.GetMousePosition()
                    clicked_cell := world_to_cell(mousePos)
                    x := int(clicked_cell.x)
                    y := int(clicked_cell.y)

                    if x < 0 || x >= gridSize {
                        break
                    }
                    if y < 0 || y >= gridSize {
                        break
                    }
                    // TODO: check bounds
                    if x < 0 || y < 0 || x >= 9 || y >= 9 {
                        continue
                    }
                    collapse_to_state(wfc_solver.grid, x, y, v)
                    break
                }
            }
            if rl.IsKeyPressed(.SPACE){
                current_state = .Solving
            }
            break
        case .Solving: 
            res := solve_iteration(wfc_solver)
            // artificial delay for more interesting visual presentation
            // rl.WaitTime(0.2)
            if res == false {
                // check if solved
                if is_solved(wfc_solver) {
                    // we cooked
                    fmt.println("We cooked")
                    current_state = .Solved
                    break
                }

                choice_count := len(wfc_solver.choices)
                if choice_count == 0 {
                    // we're cooked
                    fmt.println("Couldn't solve")
                    current_state = .Solved
                    break
                }else{
                    // backtrack
                    fmt.printfln("Backtracking: choices left %d", len(wfc_solver.choices))
                    choice := &wfc_solver.choices[choice_count-1]
                    picked_state := state_to_int(choice.possible_states)
                    
                    choice.possible_states &= ~(1 << uint(picked_state))

                    cell_x := choice.cell_x
                    cell_y := choice.cell_y
                    fmt.printfln("backtracked and picked %d for %d %d ", picked_state, cell_x, cell_y)
                    rebuild_grid_from_choice(wfc_solver, choice^)
                    

                    if choice.possible_states == 0 {
                        pop(&wfc_solver.choices)
                    }
                    collapse_to_state(wfc_solver.grid, cell_x, cell_y, picked_state)
                }
            }

            break
        case .Solved: 

            break
        }
        rl.BeginDrawing()

        for row, y in wfc_solver.grid {
            for cell, x in row {
                if cell.collapsed {
                    draw_cell_value(x, y, int(cell.collapsed_value))
                }else{
                    draw_cell_value(x, y, -int(cell.possible_state_count))
                }
            }
        }
        rl.ClearBackground(rl.RAYWHITE)
        rl.DrawFPS(0,0)

        draw_grid()

        rl.EndDrawing()
    }
    rl.CloseWindow()
}


world_to_cell :: proc(pos: rl.Vector2) -> rl.Vector2{
    gridPos := pos - rl.Vector2{gridPaddingX, gridPaddingY}

    cell := gridPos / cellSize
    cell = rl.Vector2{math.floor(cell.x), math.floor(cell.y)}
    return cell
}

draw_cell_value :: proc(x, y: int, value: int){
    builder := strings.builder_make()
    defer strings.builder_destroy(&builder)
    if value < 0 {
        strings.write_int(&builder, -value, 10)
    }else {
        strings.write_int(&builder, value, 10)
    }
    if value < 0 {
        rl.DrawText(strings.to_cstring(&builder), i32(x * cellSize + gridPaddingX) + cellSize/2, i32(y * cellSize + gridPaddingY) + cellSize/2, 20, rl.LIGHTGRAY)
    }else if value == 0 {
        rl.DrawText(strings.to_cstring(&builder), i32(x * cellSize + gridPaddingX) + cellSize/2, i32(y * cellSize + gridPaddingY) + cellSize/2, 20, rl.RED)
    }else {
        rl.DrawText(strings.to_cstring(&builder), i32(x * cellSize + gridPaddingX) + 35, i32(y * cellSize + gridPaddingY) + 30 , 28, rl.BLACK)
    }
}

draw_grid :: proc(){
    scale := rl.GetScreenHeight() / targetScreenHeight
    // TODO: add scale into the equation

    // Horizontal lines
    startPoint := rl.Vector2{gridPaddingX, gridPaddingY}
    endPoint := rl.Vector2{startPoint.x + gridSize * cellSize, startPoint.y}
    for i in 0..=gridSize {
        width := lineWidth
        if i % 3 == 0{
            width = borderLineWidth
        }
        rl.DrawLineEx(startPoint, endPoint, width, rl.BLACK)
        startPoint.y += cellSize
        endPoint.y += cellSize
    }

    // Vertical lines
    startPoint = rl.Vector2{gridPaddingX, gridPaddingY}
    endPoint = rl.Vector2{startPoint.x, startPoint.y + gridSize * cellSize}
    for i in 0..=gridSize {
        width := lineWidth
        if i % 3 == 0{
            width = borderLineWidth
        }
        rl.DrawLineEx(startPoint, endPoint, width, rl.BLACK)
        startPoint.x += cellSize
        endPoint.x += cellSize
    }


}
