/* Gateblade TD: all rules execute on the ARM7TDMI. */
.section .text
update_game:
    push {r4-r6, lr}
    ldr r4, =game_state
    ldr r5, [r4]
    ldr r6, =pressed
    ldr r6, [r6]
    cmp r5, #PLAYING
    beq update_play
    cmp r5, #PAUSED
    beq update_paused
    tst r6, #(KEY_START | KEY_A)
    blne new_game
    b update_return
update_paused:
    tst r6, #KEY_START
    beq update_return
    mov r0, #PLAYING
    str r0, [r4]
    bl draw_world
    b update_return
update_play:
    tst r6, #KEY_START
    beq 1f
    mov r0, #PAUSED
    str r0, [r4]
    bl pause_screen
    b update_return
1:  ldr r0, =attack_timer
    bl decrement
    ldr r0, =attack_cooldown
    bl decrement
    ldr r0, =notice_timer
    bl decrement
    bl move_player
    bl select_tower
    bl interact_tower
    bl begin_attack
    bl apply_sword
    bl begin_wave
    bl spawn_enemy
    bl update_enemies
    ldr r0, [r4]
    cmp r0, #PLAYING
    bne update_return
    bl update_towers
    bl finish_wave
    bl check_exit
update_return:
    pop {r4-r6, lr}
    bx lr

decrement:
    ldr r1, [r0]
    cmp r1, #0
    subgt r1, r1, #1
    str r1, [r0]
    bx lr

new_game:
    push {r4, lr}
    mov r1, #0
    ldr r0, =stage_index
    str r1, [r0]
    ldr r0, =selected_type
    str r1, [r0]
    ldr r0, =total_kills
    str r1, [r0]
    ldr r0, =total_leaks
    str r1, [r0]
    ldr r0, =waves_cleared
    str r1, [r0]
    ldr r0, =attack_id
    str r1, [r0]
    ldr r0, =coins
    mov r1, #60
    str r1, [r0]
    ldr r0, =game_state
    mov r1, #PLAYING
    str r1, [r0]
    bl load_stage
    pop {r4, lr}
    bx lr

load_stage:
    push {r4-r8, lr}
    ldr r0, =stage_index
    ldr r4, [r0]
    ldr r5, =stage_table
    add r5, r5, r4, lsl #5
    ldr r1, [r5]
    ldr r0, =map_ptr
    str r1, [r0]
    ldr r1, [r5, #4]
    ldr r0, =route_ptr
    str r1, [r0]
    ldr r1, [r5, #8]
    ldr r0, =pads_ptr
    str r1, [r0]
    ldr r1, [r5, #12]
    ldr r0, =stage_name
    str r1, [r0]
    ldr r1, [r5, #16]
    ldr r0, =route_count
    str r1, [r0]
    ldr r1, [r5, #20]
    ldr r0, =stage_waves
    str r1, [r0]
    ldr r1, [r5, #24]
    ldr r0, =base_enemy_hp
    str r1, [r0]
    ldr r1, [r5, #28]
    ldr r0, =spawn_interval
    str r1, [r0]
    mov r1, #1
    cmp r4, #2
    movge r1, #2
    cmp r4, #5
    movge r1, #3
    ldr r0, =unlocked_types
    str r1, [r0]
    mov r1, #0
    ldr r0, =wave_index
    str r1, [r0]
    ldr r0, =wave_active
    str r1, [r0]
    ldr r0, =stage_clear
    str r1, [r0]
    ldr r0, =stage_invested
    str r1, [r0]
    ldr r0, =move_left
    str r1, [r0]
    ldr r0, =attack_timer
    str r1, [r0]
    ldr r0, =attack_cooldown
    str r1, [r0]
    ldr r0, =enemies_alive
    str r1, [r0]
    ldr r0, =towers_built
    str r1, [r0]
    ldr r0, =spawn_remaining
    str r1, [r0]
    ldr r0, =spawn_timer
    str r1, [r0]
    ldr r0, =notice_timer
    str r1, [r0]
    ldr r0, =facing
    str r1, [r0]
    ldr r0, =hero_col
    mov r1, #1
    str r1, [r0]
    ldr r0, =hero_row
    mov r1, #6
    str r1, [r0]
    ldr r0, =base_hp
    str r1, [r0]
    ldr r0, =player_x
    mov r1, #24
    str r1, [r0]
    ldr r0, =player_y
    mov r1, #128
    str r1, [r0]
    ldr r0, =enemies
    ldr r2, =(ENEMY_SIZE*MAX_ENEMIES + TOWER_SIZE*MAX_TOWERS)/4
    mov r1, #0
1:  str r1, [r0], #4
    subs r2, r2, #1
    bne 1b
    ldr r0, =pads_ptr
    ldr r5, [r0]
    ldr r6, =towers
    mov r7, #MAX_TOWERS
2:  ldr r0, [r5], #4
    str r0, [r6, #TX]
    ldr r0, [r5], #4
    str r0, [r6, #TY]
    add r6, r6, #TOWER_SIZE
    subs r7, r7, #1
    bne 2b
    ldr r0, =stage_palettes
    add r0, r0, r4, lsl #5
    ldr r1, =0x05000000
    mov r2, #8
    bl dma_copy
    bl draw_world
    pop {r4-r8, lr}
    bx lr

/* r0 column, r1 row -> r0 passable. Built pads are solid, routes stay free. */
can_walk:
    cmp r0, #MAP_COLS
    bhs walk_no
    cmp r1, #MAP_ROWS
    bhs walk_no
    mov r2, #MAP_COLS
    mla r2, r1, r2, r0
    ldr r3, =map_ptr
    ldr r3, [r3]
    ldrb r2, [r3, r2]
    cmp r2, #2
    beq walk_no
    cmp r2, #3
    beq walk_no
    cmp r2, #4
    bne 1f
    ldr r2, =stage_clear
    ldr r2, [r2]
    cmp r2, #0
    beq walk_no
1:  mov r0, r0, lsl #4
    add r0, r0, #8
    mov r1, r1, lsl #4
    add r1, r1, #32
    ldr r2, =towers
    mov r12, #MAX_TOWERS
2:  ldr r3, [r2, #TLEVEL]
    cmp r3, #0
    beq 3f
    ldr r3, [r2, #TX]
    cmp r3, r0
    ldreq r3, [r2, #TY]
    cmpeq r3, r1
    beq walk_no
3:  add r2, r2, #TOWER_SIZE
    subs r12, r12, #1
    bne 2b
    mov r0, #1
    bx lr
walk_no:
    mov r0, #0
    bx lr

move_player:
    push {r4-r7, lr}
    ldr r4, =move_left
    ldr r5, [r4]
    cmp r5, #0
    bne move_advance
    ldr r0, =attack_timer
    ldr r0, [r0]
    cmp r0, #0
    bne move_done
    ldr r0, =keys
    ldr r0, [r0]
    mov r6, #-1
    tst r0, #KEY_DOWN
    movne r6, #DOWN
    tst r0, #KEY_UP
    movne r6, #UP
    tst r0, #KEY_RIGHT
    movne r6, #RIGHT
    tst r0, #KEY_LEFT
    movne r6, #LEFT
    cmp r6, #0
    blt move_done
    ldr r0, =facing
    str r6, [r0]
    ldr r0, =keys
    ldr r0, [r0]
    tst r0, #KEY_A             @ Direction + A turns and builds without stepping.
    bne move_done
    bl facing_cell
    mov r6, r0
    mov r7, r1
    bl can_walk
    cmp r0, #0
    beq move_done
    ldr r0, =target_col
    str r6, [r0]
    ldr r0, =target_row
    str r7, [r0]
    mov r5, #16
move_advance:
    ldr r0, =facing
    ldr r6, [r0]
    ldr r0, =player_x
    ldr r1, [r0]
    cmp r6, #RIGHT
    addeq r1, r1, #2
    cmp r6, #LEFT
    subeq r1, r1, #2
    str r1, [r0]
    ldr r0, =player_y
    ldr r1, [r0]
    cmp r6, #DOWN
    addeq r1, r1, #2
    cmp r6, #UP
    subeq r1, r1, #2
    str r1, [r0]
    subs r5, r5, #2
    str r5, [r4]
    bne move_done
    ldr r0, =target_col
    ldr r1, [r0]
    ldr r0, =hero_col
    str r1, [r0]
    ldr r0, =target_row
    ldr r1, [r0]
    ldr r0, =hero_row
    str r1, [r0]
move_done:
    pop {r4-r7, lr}
    bx lr

facing_cell:
    ldr r0, =hero_col
    ldr r0, [r0]
    ldr r1, =hero_row
    ldr r1, [r1]
    ldr r2, =facing
    ldr r2, [r2]
    cmp r2, #UP
    subeq r1, r1, #1
    cmp r2, #DOWN
    addeq r1, r1, #1
    cmp r2, #RIGHT
    addeq r0, r0, #1
    cmp r2, #LEFT
    subeq r0, r0, #1
    bx lr
.ltorg

select_tower:
    ldr r0, =pressed
    ldr r0, [r0]
    tst r0, #KEY_L
    bxeq lr
    ldr r0, =selected_type
    ldr r1, [r0]
    add r1, r1, #1
    ldr r2, =unlocked_types
    ldr r2, [r2]
    cmp r1, r2
    movhs r1, #0
    str r1, [r0]
    bx lr

/* Notice: 1 invalid pad, 2 insufficient coins, 3 maximum level. */
notice:
    ldr r1, =notice_code
    str r0, [r1]
    ldr r1, =notice_timer
    mov r0, #90
    str r0, [r1]
    bx lr

interact_tower:
    push {r4-r8, lr}
    ldr r0, =pressed
    ldr r0, [r0]
    tst r0, #KEY_A
    beq interact_done
    ldr r0, =move_left
    ldr r0, [r0]
    cmp r0, #0
    bne interact_done
    bl facing_cell
    mov r0, r0, lsl #4
    add r5, r0, #8
    mov r1, r1, lsl #4
    add r6, r1, #32
    ldr r4, =towers
    mov r7, #MAX_TOWERS
1:  ldr r0, [r4, #TX]
    cmp r0, r5
    ldreq r0, [r4, #TY]
    cmpeq r0, r6
    beq 2f
    add r4, r4, #TOWER_SIZE
    subs r7, r7, #1
    bne 1b
    mov r0, #1
    bl notice
    b interact_done
2:  ldr r5, [r4, #TLEVEL]
    cmp r5, #2
    bne 3f
    mov r0, #3
    bl notice
    b interact_done
3:  mov r6, #20
    cmp r5, #0
    bne 4f
    ldr r0, =selected_type
    ldr r8, [r0]
    add r6, r8, r8, lsl #2
    mov r6, r6, lsl #1
    add r6, r6, #20
4:  ldr r0, =coins
    ldr r1, [r0]
    cmp r1, r6
    bhs 5f
    mov r0, #2
    bl notice
    b interact_done
5:  sub r1, r1, r6
    str r1, [r0]
    ldr r0, =stage_invested
    ldr r1, [r0]
    add r1, r1, r6
    str r1, [r0]
    ldr r0, [r4, #TCOST]
    add r0, r0, r6
    str r0, [r4, #TCOST]
    cmp r5, #0
    bne 6f
    str r8, [r4, #TTYPE]
    ldr r0, =towers_built
    ldr r1, [r0]
    add r1, r1, #1
    str r1, [r0]
6:  add r5, r5, #1
    str r5, [r4, #TLEVEL]
    mov r0, #0
    str r0, [r4, #TCOOL]
    bl sound_gate
interact_done:
    pop {r4-r8, lr}
    bx lr

begin_attack:
    ldr r0, =move_left
    ldr r0, [r0]
    cmp r0, #0
    bxne lr
    ldr r0, =attack_cooldown
    ldr r1, [r0]
    cmp r1, #0
    bxne lr
    ldr r1, =keys
    ldr r1, [r1]
    tst r1, #KEY_B
    bxeq lr
    mov r1, #20
    str r1, [r0]
    ldr r0, =attack_timer
    mov r1, #9
    str r1, [r0]
    ldr r0, =attack_id
    ldr r1, [r0]
    add r1, r1, #1
    str r1, [r0]
    b sound_sword

apply_sword:
    push {r4-r9, lr}
    ldr r0, =attack_timer
    ldr r0, [r0]
    cmp r0, #0
    beq sword_done
    ldr r0, =player_x
    ldr r8, [r0]
    ldr r0, =player_y
    ldr r9, [r0]
    sub r8, r8, #8
    sub r9, r9, #8
    ldr r0, =facing
    ldr r0, [r0]
    cmp r0, #UP
    subeq r9, r9, #16
    cmp r0, #DOWN
    addeq r9, r9, #16
    cmp r0, #RIGHT
    addeq r8, r8, #16
    cmp r0, #LEFT
    subeq r8, r8, #16
    ldr r0, =attack_x
    str r8, [r0]
    ldr r0, =attack_y
    str r9, [r0]
    ldr r4, =enemies
    mov r5, #MAX_ENEMIES
    ldr r0, =attack_id
    ldr r6, [r0]
1:  ldr r0, [r4, #EHP]
    cmp r0, #0
    beq 2f
    ldr r0, [r4, #ELAST_HIT]
    cmp r0, r6
    beq 2f
    ldr r0, [r4, #EX]
    sub r0, r0, r8
    cmp r0, #32
    bge 2f
    cmp r0, #-16
    ble 2f
    ldr r0, [r4, #EY]
    sub r0, r0, r9
    cmp r0, #32
    bge 2f
    cmp r0, #-16
    ble 2f
    str r6, [r4, #ELAST_HIT]
    mov r0, r4
    mov r1, #1
    bl damage_enemy
2:  add r4, r4, #ENEMY_SIZE
    subs r5, r5, #1
    bne 1b
sword_done:
    pop {r4-r9, lr}
    bx lr

/* r0 actor, r1 damage. Reward exactly once, including overkill. */
damage_enemy:
    ldr r2, [r0, #EHP]
    cmp r2, #0
    bxle lr
    subs r2, r2, r1
    movle r2, #0
    str r2, [r0, #EHP]
    mov r3, #8
    str r3, [r0, #EHURT]
    cmp r2, #0
    bxne lr
    ldr r0, =coins
    ldr r1, [r0]
    add r1, r1, #5
    ldr r2, =999
    cmp r1, r2
    movhi r1, r2
    str r1, [r0]
    ldr r0, =total_kills
    ldr r1, [r0]
    add r1, r1, #1
    str r1, [r0]
    ldr r0, =enemies_alive
    ldr r1, [r0]
    sub r1, r1, #1
    str r1, [r0]
    bx lr
.ltorg

begin_wave:
    ldr r0, =pressed
    ldr r0, [r0]
    tst r0, #KEY_R
    bxeq lr
    ldr r0, =stage_clear
    ldr r0, [r0]
    cmp r0, #0
    bxne lr
    ldr r0, =wave_active
    ldr r1, [r0]
    cmp r1, #0
    bxne lr
    mov r1, #1
    str r1, [r0]
    ldr r0, =stage_index
    ldr r1, [r0]
    mov r1, r1, lsr #1
    add r1, r1, #4
    ldr r0, =wave_index
    ldr r0, [r0]
    add r1, r1, r0, lsl #1
    ldr r0, =spawn_remaining
    str r1, [r0]
    mov r1, #0
    ldr r0, =spawn_timer
    str r1, [r0]
    ldr r0, =spawn_index
    str r1, [r0]
    bx lr

spawn_enemy:
    push {r4-r8, lr}
    ldr r0, =spawn_remaining
    ldr r1, [r0]
    cmp r1, #0
    beq spawn_done
    ldr r0, =spawn_timer
    ldr r1, [r0]
    cmp r1, #0
    subne r1, r1, #1
    strne r1, [r0]
    bne spawn_done
    ldr r4, =enemies
    mov r5, #MAX_ENEMIES
1:  ldr r0, [r4, #EHP]
    cmp r0, #0
    beq 2f
    add r4, r4, #ENEMY_SIZE
    subs r5, r5, #1
    bne 1b
    b spawn_done
2:  mov r0, r4
    mov r1, #0
    mov r2, #(ENEMY_SIZE/4)
3:  str r1, [r0], #4
    subs r2, r2, #1
    bne 3b
    ldr r0, =route_ptr
    ldr r0, [r0]
    ldr r1, [r0]
    str r1, [r4, #EX]
    ldr r1, [r0, #4]
    str r1, [r4, #EY]
    mov r1, #1
    str r1, [r4, #ENODE]
    str r1, [r4, #ESPEED]
    mov r1, #16
    str r1, [r4, #ESIZE]
    ldr r0, =base_enemy_hp
    ldr r6, [r0]
    ldr r0, =wave_index
    ldr r7, [r0]
    add r6, r6, r7
    ldr r0, =stage_index
    ldr r5, [r0]
    ldr r0, =spawn_index
    ldr r8, [r0]
    cmp r5, #0
    beq 5f
    mov r1, r8
4:  cmp r1, #3
    subhs r1, r1, #3
    bhs 4b
    cmp r1, #1
    bne 5f
    mov r1, #1
    str r1, [r4, #ETYPE]
    mov r1, #0
    str r1, [r4, #ESPEED]
5:  cmp r5, #LAST_STAGE
    cmpeq r7, #2
    cmpeq r8, #0
    bne 6f
    mov r6, #48
    mov r1, #2
    str r1, [r4, #ETYPE]
    mov r1, #1
    str r1, [r4, #ESPEED]
6:  str r6, [r4, #EHP]
    add r8, r8, #1
    ldr r0, =spawn_index
    str r8, [r0]
    ldr r0, =spawn_remaining
    ldr r1, [r0]
    sub r1, r1, #1
    str r1, [r0]
    ldr r0, =enemies_alive
    ldr r1, [r0]
    add r1, r1, #1
    str r1, [r0]
    ldr r0, =spawn_interval
    ldr r1, [r0]
    ldr r0, =spawn_timer
    str r1, [r0]
spawn_done:
    pop {r4-r8, lr}
    bx lr

update_enemies:
    push {r4-r9, lr}
    ldr r4, =enemies
    mov r5, #MAX_ENEMIES
    ldr r0, =frame_tick
    ldr r6, [r0]
    ldr r0, =route_ptr
    ldr r7, [r0]
1:  ldr r0, [r4, #EHP]
    cmp r0, #0
    beq enemy_next
    ldr r0, [r4, #EHURT]
    cmp r0, #0
    subne r0, r0, #1
    str r0, [r4, #EHURT]
    ldr r0, [r4, #ESLOW]
    cmp r0, #0
    subne r0, r0, #1
    str r0, [r4, #ESLOW]
    ldr r1, [r4, #ESPEED]
    cmp r0, #0
    movne r1, #3
    tst r6, r1
    bne enemy_next
    ldr r0, [r4, #ENODE]
    add r8, r7, r0, lsl #3
    ldr r0, [r4, #EX]
    ldr r1, [r8]
    cmp r0, r1
    addlt r0, r0, #1
    subgt r0, r0, #1
    str r0, [r4, #EX]
    bne 2f
    ldr r0, [r4, #EY]
    ldr r1, [r8, #4]
    cmp r0, r1
    addlt r0, r0, #1
    subgt r0, r0, #1
    str r0, [r4, #EY]
2:  ldr r0, [r4, #EPROGRESS]
    add r0, r0, #1
    str r0, [r4, #EPROGRESS]
    ldr r0, [r4, #EX]
    ldr r1, [r8]
    cmp r0, r1
    ldreq r0, [r4, #EY]
    ldreq r1, [r8, #4]
    cmpeq r0, r1
    bne enemy_next
    ldr r0, [r4, #ENODE]
    add r0, r0, #1
    str r0, [r4, #ENODE]
    ldr r1, =route_count
    ldr r1, [r1]
    cmp r0, r1
    blo enemy_next
    mov r0, #0
    str r0, [r4, #EHP]
    ldr r0, =enemies_alive
    ldr r1, [r0]
    sub r1, r1, #1
    str r1, [r0]
    ldr r0, =total_leaks
    ldr r1, [r0]
    add r1, r1, #1
    str r1, [r0]
    ldr r0, [r4, #ETYPE]
    cmp r0, #2
    moveq r2, #3
    movne r2, #1
    ldr r0, =base_hp
    ldr r1, [r0]
    subs r1, r1, r2
    movle r1, #0
    str r1, [r0]
    cmp r1, #0
    beq base_fallen
    bl sound_hurt
 enemy_next:
    add r4, r4, #ENEMY_SIZE
    subs r5, r5, #1
    bne 1b
    b enemies_done
base_fallen:
    ldr r0, =game_state
    mov r1, #DEAD
    str r1, [r0]
    bl death_screen
 enemies_done:
    pop {r4-r9, lr}
    bx lr
.ltorg

/* Auto-target the living enemy furthest along the route, in diamond range. */
update_towers:
    push {r4-r11, lr}
    ldr r4, =towers
    mov r5, #MAX_TOWERS
 tower_loop:
    ldr r0, [r4, #TLEVEL]
    cmp r0, #0
    beq tower_next
    ldr r0, [r4, #TSHOT]
    cmp r0, #0
    subne r0, r0, #1
    str r0, [r4, #TSHOT]
    ldr r0, [r4, #TCOOL]
    cmp r0, #0
    subne r0, r0, #1
    strne r0, [r4, #TCOOL]
    bne tower_next
    ldr r0, [r4, #TTYPE]
    mov r6, #48
    cmp r0, #1
    moveq r6, #64
    ldr r1, [r4, #TLEVEL]
    cmp r1, #2
    addeq r6, r6, #16
    mov r7, #0
    mov r8, #-1
    ldr r9, =enemies
    mov r10, #0
 target_loop:
    ldr r0, [r9, #EHP]
    cmp r0, #0
    beq target_next
    ldr r0, [r9, #EX]
    ldr r1, [r4, #TX]
    sub r0, r0, r1
    cmp r0, #0
    rsblt r0, r0, #0
    ldr r1, [r9, #EY]
    ldr r2, [r4, #TY]
    sub r1, r1, r2
    cmp r1, #0
    rsblt r1, r1, #0
    add r0, r0, r1
    cmp r0, r6
    bhi target_next
    ldr r0, [r9, #EPROGRESS]
    cmp r0, r8
    movgt r8, r0
    movgt r7, r9
    strgt r10, [r4, #TTARGET]
 target_next:
    add r9, r9, #ENEMY_SIZE
    add r10, r10, #1
    cmp r10, #MAX_ENEMIES
    blo target_loop
    cmp r7, #0
    beq tower_next
    ldr r6, [r4, #TTYPE]
    ldr r8, [r4, #TLEVEL]
    mov r0, #32
    cmp r6, #1
    moveq r0, #50
    cmp r6, #2
    moveq r0, #60
    cmp r8, #2
    subeq r0, r0, #8
    str r0, [r4, #TCOOL]
    mov r0, #5
    str r0, [r4, #TSHOT]
    cmp r6, #2
    beq cannon_fire
    cmp r6, #1
    bne 1f
    mov r0, #60
    cmp r8, #2
    addeq r0, r0, #30
    str r0, [r7, #ESLOW]
1:  mov r0, r7
    mov r1, r8
    bl damage_enemy
    b tower_next
 cannon_fire:
    ldr r10, [r7, #EX]
    ldr r11, [r7, #EY]
    ldr r9, =enemies
    mov r6, #MAX_ENEMIES
2:  ldr r0, [r9, #EHP]
    cmp r0, #0
    beq 3f
    ldr r0, [r9, #EX]
    sub r0, r0, r10
    cmp r0, #0
    rsblt r0, r0, #0
    ldr r1, [r9, #EY]
    sub r1, r1, r11
    cmp r1, #0
    rsblt r1, r1, #0
    add r0, r0, r1
    cmp r0, #24
    bhi 3f
    mov r0, r9
    add r1, r8, #1
    bl damage_enemy
3:  add r9, r9, #ENEMY_SIZE
    subs r6, r6, #1
    bne 2b
 tower_next:
    add r4, r4, #TOWER_SIZE
    subs r5, r5, #1
    bne tower_loop
    pop {r4-r11, lr}
    bx lr

finish_wave:
    push {lr}
    ldr r0, =wave_active
    ldr r1, [r0]
    cmp r1, #0
    beq finish_done
    ldr r1, =spawn_remaining
    ldr r1, [r1]
    cmp r1, #0
    bne finish_done
    ldr r1, =enemies_alive
    ldr r1, [r1]
    cmp r1, #0
    bne finish_done
    mov r1, #0
    str r1, [r0]
    ldr r0, =waves_cleared
    ldr r1, [r0]
    add r1, r1, #1
    str r1, [r0]
    ldr r0, =wave_index
    ldr r1, [r0]
    add r1, r1, #1
    str r1, [r0]
    ldr r0, =stage_waves
    ldr r0, [r0]
    cmp r1, r0
    blo finish_done
    ldr r0, =stage_clear
    mov r1, #1
    str r1, [r0]
    bl draw_portal
    bl sound_gate
finish_done:
    pop {lr}
    bx lr

check_exit:
    push {r4, lr}
    ldr r0, =stage_clear
    ldr r0, [r0]
    cmp r0, #0
    beq exit_done
    ldr r0, =move_left
    ldr r0, [r0]
    cmp r0, #0
    bne exit_done
    ldr r0, =hero_col
    ldr r0, [r0]
    cmp r0, #12
    bne exit_done
    ldr r0, =hero_row
    ldr r0, [r0]
    cmp r0, #6
    bne exit_done
    ldr r4, =stage_index
    ldr r0, [r4]
    cmp r0, #LAST_STAGE
    beq campaign_won
    add r0, r0, #1
    str r0, [r4]
    ldr r0, =stage_invested
    ldr r1, [r0]
    ldr r0, =coins
    ldr r2, [r0]
    add r2, r2, r1
    add r2, r2, #20
    ldr r1, =999
    cmp r2, r1
    movhi r2, r1
    str r2, [r0]
    bl load_stage
    b exit_done
campaign_won:
    ldr r0, =game_state
    mov r1, #VICTORY
    str r1, [r0]
    bl victory_screen
exit_done:
    pop {r4, lr}
    bx lr
.ltorg
