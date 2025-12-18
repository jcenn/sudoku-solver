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
cellSize :: 50
gridPaddingX :: 50
gridPaddingY :: 50

lineWidth :: f32(2.0)
borderLineWidth :: f32(4.0)

GameState :: enum {
    Initial,
    Solving,
    Solved,
}


targetScreenHeight :: 800

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

    wfc_grid := make([][]WfcCell, gridSize)
    defer delete(wfc_grid)
    
    for _, i in wfc_grid
    {
        wfc_grid[i] = make([]WfcCell, gridSize)
    }
    // cleanup of inner arrays
    defer for _, i in wfc_grid
    {
        delete(wfc_grid[i])
    }

    for row in wfc_grid {
        for &cell in row {
            cell.collapsed = false
            cell.possible_state_count = 0
            cell.states = 0
            for i in 1..=9{
                add_possible_state(&cell, uint(i))
            }
        }
    }

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
                    fmt.printfln("pressed on %.f, %.f", clicked_cell.x, clicked_cell.y)
                    // TODO: check bounds
                    collapse_to_state(wfc_grid, x, y, v)
                    break
                }
            }
            if rl.IsKeyPressed(.SPACE){
                current_state = .Solving
            }
            break
        case .Solving: 
            rl.WaitTime(1.0)
            solve_iteration(wfc_grid)

            break
        case .Solved: 

            break
        }
        rl.BeginDrawing()

        for row, y in wfc_grid {
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
    strings.write_int(&builder, value, 10)
    if value < 0 {
        rl.DrawText(strings.to_cstring(&builder), i32(x * cellSize + gridPaddingX) + cellSize/2, i32(y * cellSize + gridPaddingY) + cellSize/2, 20, rl.GREEN)
    }else {
        rl.DrawText(strings.to_cstring(&builder), i32(x * cellSize + gridPaddingX) + cellSize/2, i32(y * cellSize + gridPaddingY) + cellSize/2, 20, rl.BLACK)
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
