/* Game rules. No C runtime, engine, BIOS calls or imported game code. */
.section .text
update_game:
    push {r4-r8, lr}
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
    pop {r4-r8, lr}
    bx lr
update_paused:
    tst r6, #KEY_START
    beq update_return
    mov r0, #PLAYING
    str r0, [r4]
    bl draw_room
    b update_return
update_play:
    tst r6, #KEY_START
    beq 1f
    mov r0, #PAUSED
    str r0, [r4]
    bl pause_screen
    b update_return
1:  ldr r0, =player_iframes
    bl decrement
    ldr r0, =attack_timer
    bl decrement
    ldr r0, =attack_cooldown
    bl decrement
    bl move_player
    bl begin_attack
    bl apply_sword
    bl update_enemies
    ldr r0, [r4]
    cmp r0, #PLAYING
    bleq check_exit
update_return:
    pop {r4-r8, lr}
    bx lr

/* r0 points to a nonnegative countdown. */
decrement:
    ldr r1, [r0]
    cmp r1, #0
    subgt r1, r1, #1
    str r1, [r0]
    bx lr

new_game:
    push {r4, lr}
    mov r0, #0
    ldr r1, =room_index
    str r0, [r1]
    ldr r1, =total_kills
    str r0, [r1]
    ldr r1, =attack_id
    str r0, [r1]
    mov r0, #MAX_HP
    ldr r1, =player_hp
    str r0, [r1]
    mov r0, #PLAYING
    ldr r1, =game_state
    str r0, [r1]
    bl load_room
    pop {r4, lr}
    bx lr

load_room:
    push {r4-r8, lr}
    ldr r0, =player_x
    mov r1, #112
    str r1, [r0]
    ldr r0, =player_y
    mov r1, #122
    str r1, [r0]
    mov r1, #0
    ldr r0, =facing
    str r1, [r0]
    ldr r0, =attack_timer
    str r1, [r0]
    ldr r0, =attack_cooldown
    str r1, [r0]
    ldr r0, =player_iframes
    mov r1, #45
    str r1, [r0]
    ldr r0, =enemies
    mov r1, #0
    mov r2, #(ENEMY_SIZE * MAX_ENEMIES / 4)
1:  str r1, [r0], #4
    subs r2, r2, #1
    bne 1b
    ldr r0, =room_index
    ldr r4, [r0]
    cmp r4, #LAST_ROOM
    moveq r5, #1
    addne r5, r4, #2
    ldr r0, =enemies_alive
    str r5, [r0]
    ldr r6, =enemies
    ldr r7, =enemy_spawns
    mov r8, #0
2:  ldr r0, [r7], #4
    str r0, [r6, #EX]
    ldr r0, [r7], #4
    str r0, [r6, #EY]
    mov r0, #2
    cmp r4, #1
    moveq r0, #3
    cmp r4, #2
    moveq r0, #3
    cmp r4, #LAST_ROOM
    moveq r0, #16
    str r0, [r6, #EHP]
    mov r0, #0
    cmp r4, #0
    beq 3f
    and r0, r8, #1
    cmp r4, #LAST_ROOM
    moveq r0, #2
3:  str r0, [r6, #ETYPE]
    cmp r0, #2
    moveq r1, #32
    movne r1, #16
    str r1, [r6, #ESIZE]
    cmp r0, #2
    bne 4f
    mov r0, #104
    str r0, [r6, #EX]
    mov r0, #48
    str r0, [r6, #EY]
    mov r0, #75
    str r0, [r6, #ETIMER]
4:  add r6, r6, #ENEMY_SIZE
    add r8, r8, #1
    cmp r8, r5
    blo 2b
    bl draw_room
    pop {r4-r8, lr}
    bx lr

move_player:
    push {r4-r8, lr}
    ldr r0, =attack_timer
    ldr r0, [r0]
    cmp r0, #0
    bne 9f                       @ Keep direction stable during a swing.
    ldr r0, =keys
    ldr r4, [r0]
    ldr r5, =player_x
    ldr r6, [r5]
    ldr r7, =player_y
    ldr r8, [r7]
    mov r3, #-1
    tst r4, #KEY_LEFT
    subne r6, r6, #1
    movne r3, #LEFT
    tst r4, #KEY_RIGHT
    addne r6, r6, #1
    movne r3, #RIGHT
    tst r4, #(KEY_LEFT | KEY_RIGHT)
    bne 1f                       @ Cardinal motion, no faster diagonals.
    tst r4, #KEY_UP
    subne r8, r8, #1
    movne r3, #UP
    tst r4, #KEY_DOWN
    addne r8, r8, #1
    movne r3, #DOWN
1:  cmp r6, #16
    movlt r6, #16
    cmp r6, #208
    movgt r6, #208
    cmp r8, #128
    movgt r8, #128
    mov r2, #32
    ldr r0, =enemies_alive
    ldr r0, [r0]
    cmp r0, #0
    bne 2f
    cmp r6, #104
    blt 2f
    cmp r6, #120
    movle r2, #20               @ Only a cleared room opens the north gate.
2:  cmp r8, r2
    movlt r8, r2
    str r6, [r5]
    str r8, [r7]
    cmp r3, #0
    ldrge r0, =facing
    strge r3, [r0]
9:  pop {r4-r8, lr}
    bx lr

begin_attack:
    ldr r0, =attack_cooldown
    ldr r1, [r0]
    cmp r1, #0
    bxne lr
    ldr r1, =keys
    ldr r1, [r1]
    tst r1, #KEY_A
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

/* Melee uses a 32x32 box placed in front of the hero. */
apply_sword:
    push {r4-r11, lr}
    ldr r0, =attack_timer
    ldr r0, [r0]
    cmp r0, #0
    beq 9f
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
    ldr r10, [r0]
1:  ldr r6, [r4, #EHP]
    cmp r6, #0
    beq 8f
    ldr r0, [r4, #ELAST_HIT]
    cmp r0, r10
    beq 8f                      @ At most one hit per enemy per swing.
    ldr r0, [r4, #EX]
    ldr r1, [r4, #EY]
    ldr r7, [r4, #ESIZE]
    add r2, r0, r7
    cmp r2, r8
    ble 8f
    add r2, r8, #32
    cmp r0, r2
    bge 8f
    add r2, r1, r7
    cmp r2, r9
    ble 8f
    add r2, r9, #32
    cmp r1, r2
    bge 8f
    str r10, [r4, #ELAST_HIT]
    sub r6, r6, #1
    str r6, [r4, #EHP]
    mov r0, #12
    str r0, [r4, #EHURT]
    cmp r6, #0
    bne 8f
    ldr r0, =enemies_alive
    ldr r1, [r0]
    sub r1, r1, #1
    str r1, [r0]
    ldr r0, =total_kills
    ldr r2, [r0]
    add r2, r2, #1
    str r2, [r0]
    cmp r1, #0
    bleq sound_gate
8:  add r4, r4, #ENEMY_SIZE
    subs r5, r5, #1
    bne 1b
9:  pop {r4-r11, lr}
    bx lr

update_enemies:
    push {r4-r11, lr}
    ldr r4, =enemies
    mov r5, #MAX_ENEMIES
    ldr r0, =player_x
    ldr r8, [r0]
    ldr r0, =player_y
    ldr r9, [r0]
1:  ldr r0, [r4, #EHP]
    cmp r0, #0
    beq 8f
    ldr r0, [r4, #EHURT]
    cmp r0, #0
    subgt r0, r0, #1
    strgt r0, [r4, #EHURT]
    ble 2f
    ldr r0, [r4, #ETYPE]
    cmp r0, #2
    bne 7f                      @ Regular enemies stagger; the boss does not.
2:
    ldr r6, [r4, #EX]
    ldr r7, [r4, #EY]
    ldr r0, [r4, #ETYPE]
    cmp r0, #2
    beq 4f
    ldr r1, =frame_tick
    ldr r1, [r1]
    cmp r0, #0
    andeq r1, r1, #3
    andne r1, r1, #1
    cmp r1, #0
    bne 7f
    cmp r6, r8
    addlt r6, r6, #1
    subgt r6, r6, #1
    cmp r7, r9
    addlt r7, r7, #1
    subgt r7, r7, #1
    b 6f
4:  bl update_boss               @ r4 actor, r6/r7 position; callee preserves r8+.
6:  cmp r6, #16
    movlt r6, #16
    ldr r0, [r4, #ESIZE]
    rsb r0, r0, #224
    cmp r6, r0
    movgt r6, r0
    cmp r7, #32
    movlt r7, #32
    ldr r0, [r4, #ESIZE]
    rsb r0, r0, #144
    cmp r7, r0
    movgt r7, r0
    str r6, [r4, #EX]
    str r7, [r4, #EY]
7:  bl enemy_contact
    ldr r0, =game_state
    ldr r0, [r0]
    cmp r0, #DEAD
    beq 9f
8:  add r4, r4, #ENEMY_SIZE
    subs r5, r5, #1
    bne 1b
9:  pop {r4-r11, lr}
    bx lr

/* Boss: stalk -> telegraph -> charge -> recover. */
update_boss:
    ldr r0, [r4, #ETIMER]
    subs r0, r0, #1
    str r0, [r4, #ETIMER]
    ldr r1, [r4, #EPHASE]
    cmp r0, #0
    bgt 3f
    add r1, r1, #1
    cmp r1, #4
    moveq r1, #0
    str r1, [r4, #EPHASE]
    cmp r1, #0
    moveq r0, #70
    cmp r1, #1
    moveq r0, #40
    cmp r1, #2
    moveq r0, #24
    cmp r1, #3
    moveq r0, #50
    str r0, [r4, #ETIMER]
    cmp r1, #2
    bne 3f
    add r2, r6, #8
    cmp r8, r2
    movlt r0, #-2
    movge r0, #2
    str r0, [r4, #EVX]
    add r2, r7, #8
    cmp r9, r2
    movlt r0, #-2
    movge r0, #2
    str r0, [r4, #EVY]
3:  cmp r1, #2
    ldreq r0, [r4, #EVX]
    addeq r6, r6, r0
    ldreq r0, [r4, #EVY]
    addeq r7, r7, r0
    cmp r1, #0
    bxne lr
    ldr r0, =frame_tick
    ldr r0, [r0]
    tst r0, #3
    bxne lr
    add r2, r6, #8
    cmp r2, r8
    addlt r6, r6, #1
    subgt r6, r6, #1
    add r2, r7, #8
    cmp r2, r9
    addlt r7, r7, #1
    subgt r7, r7, #1
    bx lr

enemy_contact:
    push {r4-r7, lr}
    ldr r0, =player_iframes
    ldr r1, [r0]
    cmp r1, #0
    bne 9f
    ldr r1, [r4, #EX]
    ldr r2, [r4, #EY]
    ldr r3, [r4, #ESIZE]
    add r1, r1, #3
    add r2, r2, #3
    sub r3, r3, #6             @ Hurtboxes slightly smaller than artwork.
    add r6, r1, r3
    add r7, r8, #3
    cmp r6, r7
    ble 9f
    add r6, r8, #13
    cmp r1, r6
    bge 9f
    add r6, r2, r3
    add r7, r9, #3
    cmp r6, r7
    ble 9f
    add r6, r9, #13
    cmp r2, r6
    bge 9f
    mov r1, #75
    str r1, [r0]
    ldr r0, =player_hp
    ldr r1, [r0]
    ldr r2, [r4, #ETYPE]
    cmp r2, #2
    subeq r1, r1, #2
    subne r1, r1, #1
    cmp r1, #0
    movlt r1, #0
    str r1, [r0]
    bleq player_died
    bl sound_hurt
9:  pop {r4-r7, lr}
    bx lr

player_died:
    push {lr}
    ldr r0, =game_state
    mov r1, #DEAD
    str r1, [r0]
    bl death_screen
    pop {lr}
    bx lr

check_exit:
    push {r4, lr}
    ldr r0, =enemies_alive
    ldr r0, [r0]
    cmp r0, #0
    bne 9f
    ldr r0, =player_y
    ldr r0, [r0]
    cmp r0, #24
    bgt 9f
    ldr r0, =player_x
    ldr r0, [r0]
    cmp r0, #104
    blt 9f
    cmp r0, #120
    bgt 9f
    ldr r4, =room_index
    ldr r0, [r4]
    cmp r0, #LAST_ROOM
    beq 8f
    add r0, r0, #1
    str r0, [r4]
    ldr r0, =player_hp
    ldr r1, [r0]
    cmp r1, #MAX_HP
    addlt r1, r1, #1
    str r1, [r0]
    bl load_room
    b 9f
8:  ldr r0, =game_state
    mov r1, #VICTORY
    str r1, [r0]
    bl victory_screen
9:  pop {r4, lr}
    bx lr

.ltorg
.section .rodata
.balign 4
enemy_spawns: .word 56, 52, 168, 60, 64, 96, 176, 104
