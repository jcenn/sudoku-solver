package main

WfcCell :: struct {
    collapsed_value: int,
    collapsed:bool,
    states: u16,
    possible_state_count: int
}

// for assigning initial values to cells
// won't check if value is legal
// won't propagate to other cells
collapse_to_state :: proc(grid: [][]WfcCell, x, y: int, value: int){
    for i in 1..=9 {
        if i == value {
            continue
        }
        collapse_cell_state(grid, x, y, uint(i))
    }
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
        cell.collapsed = true
        cell.collapsed_value = state_to_int(cell.states)
    }

    // TODO: not sure about this one
    if !cell.collapsed {
        return
    }

    // TODO: propagate state change in cell's row, column and subgrid
    collapsed_state := uint(cell.collapsed_value)
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

solve_iteration :: proc(wfc_grid: [][]WfcCell) {
    // find cell with lowest entropy

    // it will have 2 or more possible states
    // we choose one and store information about that choice in a stack-like structure
    // if we reach an unsolvable state we have to go back to last choice and pick another option
    // if we run out of options it means the initial state was unsolvable
}
