package main

import "core:fmt"
import "core:slice"
WfcCell :: struct {
    collapsed_value: int,
    collapsed:bool,
    states: u16,
    possible_state_count: int
}

WfcChoice :: struct {
    grid_state: [][]WfcCell,
    cell_x:int,
    cell_y:int,
    possible_states: u16
}

WfcSolver :: struct {
    grid: [][]WfcCell,
    choices: [dynamic]WfcChoice
}

init_wfc_solver :: proc() -> ^WfcSolver {
    solver := new(WfcSolver)
    solver.choices = make([dynamic]WfcChoice)
    solver.grid = make([][]WfcCell, 9)
    for _, i in solver.grid
    {
        solver.grid[i] = make([]WfcCell, gridSize)
        for &cell in solver.grid[i] {
            cell.possible_state_count = 9
            cell.collapsed = false
            
            for i in 1..=9{
                add_possible_state(&cell, uint(i))
            }
        }
    }
    return solver
}
destroy_wfc_solver :: proc(solver: ^WfcSolver) {
    // TODO: implement cleanup
    // Tbh it's going to get cleaned automatically either way
    free(solver)
}

rebuild_grid_from_choice :: proc(solver : ^WfcSolver, choice: WfcChoice){
    for _, y in solver.grid {
        for _, x in solver.grid[y] {
            solver.grid[y][x] = choice.grid_state[y][x]
        }
    }
}

collapse_to_state :: proc(grid: [][]WfcCell, x, y: int, state: int){
    // tried to assign invalid state to this cell
    if !has_state(&grid[y][x], uint(state)) {
        return
    }
    for i in 1..=9 {
        if i == state {
            continue
        }
        collapse_cell_state(grid, x, y, uint(i))
    }
    grid[y][x].collapsed = true
}

add_possible_state :: proc(cell: ^WfcCell, state: uint){
    // check if cell doesn't already have that possible state
    if has_state(cell, state) {
        return
    }

    cell.states |= 1 << state      
    cell.possible_state_count += 1
    if cell.possible_state_count > 1 {
        cell.collapsed = false
    }
}

has_state :: proc(cell: ^WfcCell, state: uint) -> bool {
    return (cell.states & (1 << state)) != 0
}

// if there's multiple states in the bitmask returns the lowest one
state_to_int :: proc(state: u16) -> int {
    for i in 1..=9 {
        if (state & (1 << uint(i))) != 0 {
            return i
        }
    }
    return -1
}

collapse_cell_state:: proc(wfc_grid: [][]WfcCell, x, y: int, state: uint){
    cell := &wfc_grid[y][x]
    if cell.collapsed {
        return
    }

    // check if cell even has that possible state
    if !has_state(cell, state) {
        return
    }
    // remove state from cell
    cell.states &= ~(1 << state)
    cell.possible_state_count -= 1
    if cell.possible_state_count == 1 {
        cell.collapsed_value = state_to_int(cell.states)
    }

    collapsed_state := uint(cell.collapsed_value)
    // collapse_to_state(wfc_grid, x, y, state_to_int(cell.states))
    // row
    for &cell, cell_x in wfc_grid[y]{
        if cell_x != x && !cell.collapsed && has_state(&cell, collapsed_state) {
            collapse_cell_state(wfc_grid, cell_x, y, collapsed_state)
        }
    }
    // column
    for row, cell_y in wfc_grid{
        if cell_y == y {
            continue
        }
        for &cell, cell_x in row{
            if cell_x != x {
                continue
            }
            if !cell.collapsed && has_state(&cell, collapsed_state) {
                collapse_cell_state(wfc_grid, cell_x, cell_y, collapsed_state)
            }
        }
    }
    // subgrid
    subgridStartX := x/3
    subgridStartY := y/3

    for cell_y in (subgridStartY * 3)..<(subgridStartY * 3 + 3) {
        for cell_x in (subgridStartX * 3)..<(subgridStartX * 3 + 3) {
            cell := &wfc_grid[cell_y][cell_x]
            if (cell_x == x && cell_y == y) || !has_state(cell, collapsed_state){
                continue
            }

            collapse_cell_state(wfc_grid, cell_x, cell_y, collapsed_state)
        }
    }
}

add_choice ::proc(solver: ^WfcSolver, cell_x, cell_y: int, states: u16){
    choice := WfcChoice{
        grid_state = [][]WfcCell{},
        possible_states = states,
        cell_x = cell_x,
        cell_y = cell_y
    }
    choice.grid_state = make([][]WfcCell, len(solver.grid))
    for row, i in solver.grid {
        choice.grid_state[i] = slice.clone(row)
    }
    append(&solver.choices, choice)
} 

solve_iteration :: proc(solver: ^WfcSolver) -> bool{
    // find cell with lowest entropy
    cell: ^WfcCell = nil
    min_states := 9
    min_x := 0
    min_y := 0
    for row, y in solver.grid{
        for &c, x in row {
            if !c.collapsed && c.possible_state_count == 0 {
                // we reached a board state that's impossible to solve
                // and we need to backtrack
                return false
            }
            if !c.collapsed && c.possible_state_count <= min_states {
                cell = &c
                min_x = x
                min_y = y
                min_states = c.possible_state_count
            }
        }
    }
    if cell == nil {
        // we finished filling all cells
        // if there are choices stored in the list we have to check if our solution is correct
        // and backtrack if it isn't
        return false
    }
    // x := min_x
    // y := min_y
    if min_states == 1 {
        collapse_to_state(solver.grid, min_x, min_y, state_to_int(cell.states))
        return true
    }
    // we have more than 1 possible state for each cell and have to check all possible choices
    picked_state := state_to_int(cell.states)
    fmt.printfln("picked %d for %d %d", picked_state, min_x, min_y)
    add_choice(solver, min_x, min_y, cell.states & ~(1 << uint(picked_state)))
    collapse_to_state(solver.grid, min_x, min_y, picked_state)

    return true
}
