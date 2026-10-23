.section .text
video_init:
    push {r4, lr}
    ldr r4, =REG_BASE
    mov r0, #0x80
    strh r0, [r4]               @ Forced blank during VRAM initialization.
    ldr r0, =bg_tiles
    ldr r1, =0x06000000
    ldr r2, =bg_tiles_end
    sub r2, r2, r0
    mov r2, r2, lsr #2
    bl dma_copy
    ldr r0, =obj_tiles
    ldr r1, =0x06010000
    ldr r2, =obj_tiles_end
    sub r2, r2, r0
    mov r2, r2, lsr #2
    bl dma_copy
    ldr r0, =bg_palette
    ldr r1, =0x05000000
    mov r2, #128
    bl dma_copy
    ldr r0, =obj_palette
    ldr r1, =0x05000200
    mov r2, #128
    bl dma_copy
    mov r0, #0x1f00
    strh r0, [r4, #8]           @ BG0: charblock 0, screenblock 31, 4bpp.
    bl hide_sprites
    ldr r0, =0x1140             @ Mode 0, BG0 + OBJ, 1D object tiles.
    strh r0, [r4]
    ldr r0, =0x04000084
    mov r1, #0x80
    strh r1, [r0]
    ldr r0, =0x04000080
    ldr r1, =0x1177
    strh r1, [r0]
    pop {r4, lr}
    bx lr

dma_copy:
    ldr r3, =0x040000d4
    str r0, [r3]
    str r1, [r3, #4]
    orr r2, r2, #0x84000000     @ Immediate, 32-bit DMA3; CPU waits for it.
    str r2, [r3, #8]
    bx lr

clear_map:
    ldr r0, =BG_MAP
    mov r1, #0
    mov r2, #1024
1:  strh r1, [r0], #2
    subs r2, r2, #1
    bne 1b
    bx lr

/* r0 text, r1 tile column, r2 tile row, r3 palette bank (0..3). */
print_text:
    ldr r12, =BG_MAP
    add r12, r12, r2, lsl #6
    add r12, r12, r1, lsl #1
    mov r3, r3, lsl #12
1:  ldrb r1, [r0], #1
    cmp r1, #0
    bxeq lr
    orr r1, r1, r3
    strh r1, [r12], #2
    b 1b

/* r0 number 0..99, r1 column, r2 row, r3 palette. */
print_number:
    ldr r12, =BG_MAP
    add r12, r12, r2, lsl #6
    add r12, r12, r1, lsl #1
    mov r3, r3, lsl #12
    mov r2, #0
1:  cmp r0, #10
    subge r0, r0, #10
    addge r2, r2, #1
    bge 1b
    add r2, r2, #48
    orr r2, r2, r3
    strh r2, [r12]
    add r0, r0, #48
    orr r0, r0, r3
    strh r0, [r12, #2]
    bx lr

draw_room:
    push {r4-r8, lr}
    bl clear_map
    ldr r4, =BG_MAP
    mov r5, #3
1:  mov r6, #1
2:  cmp r5, #3
    beq 3f
    cmp r5, #18
    beq 3f
    cmp r6, #1
    beq 3f
    cmp r6, #28
    beq 3f
    eor r0, r5, r6
    tst r0, #1
    moveq r0, #1
    movne r0, #8
    b 4f
3:  mov r0, #2
4:  add r1, r4, r5, lsl #6
    add r1, r1, r6, lsl #1
    strh r0, [r1]
    add r6, r6, #1
    cmp r6, #29
    blo 2b
    add r5, r5, #1
    cmp r5, #19
    blo 1b
    ldr r0, =(BG_MAP + 18*64 + 14*2)
    mov r1, #5
    strh r1, [r0]
    strh r1, [r0, #2]
    ldr r0, =txt_name
    mov r1, #1
    mov r2, #0
    mov r3, #1
    bl print_text
    ldr r0, =txt_room
    mov r1, #20
    mov r2, #0
    mov r3, #0
    bl print_text
    ldr r0, =room_index
    ldr r0, [r0]
    add r0, r0, #1
    mov r1, #25
    mov r2, #0
    mov r3, #1
    bl print_number
    ldr r0, =txt_four
    mov r1, #27
    mov r2, #0
    mov r3, #0
    bl print_text
    ldr r0, =txt_controls
    mov r1, #4
    mov r2, #19
    mov r3, #0
    bl print_text
    bl draw_hud
    pop {r4-r8, lr}
    bx lr

draw_hud:
    push {r4-r8, lr}
    ldr r4, =(BG_MAP + 64 + 2)
    ldr r0, =player_hp
    ldr r5, [r0]
    mov r6, #0
1:  cmp r6, r5
    movlt r0, #6
    movge r0, #7
    strh r0, [r4], #2
    add r6, r6, #1
    cmp r6, #MAX_HP
    blo 1b
    ldr r0, =txt_foes
    mov r1, #10
    mov r2, #1
    mov r3, #0
    bl print_text
    ldr r0, =enemies_alive
    ldr r7, [r0]
    mov r0, r7
    mov r1, #15
    mov r2, #1
    mov r3, #1
    bl print_number
    ldr r4, =(BG_MAP + 2*64)
    mov r0, #0
    mov r1, #30
2:  strh r0, [r4], #2
    subs r1, r1, #1
    bne 2b
    ldr r0, =txt_locked
    mov r1, #2
    mov r3, #0
    cmp r7, #0
    ldreq r0, =txt_open
    moveq r1, #4
    moveq r3, #3
    mov r2, #2
    bl print_text
    ldr r4, =(BG_MAP + 3*64 + 13*2)
    cmp r7, #0
    moveq r0, #4
    movne r0, #3
    strh r0, [r4]
    strh r0, [r4, #2]
    strh r0, [r4, #4]
    strh r0, [r4, #6]
    ldr r0, =room_index
    ldr r0, [r0]
    cmp r0, #LAST_ROOM
    bne 9f
    ldr r0, =txt_boss
    mov r1, #20
    mov r2, #1
    mov r3, #2
    bl print_text
    ldr r0, =enemies
    ldr r0, [r0, #EHP]
    mov r1, #26
    mov r2, #1
    mov r3, #2
    bl print_number
    ldr r0, =enemies
    ldr r1, [r0, #EHP]
    cmp r1, #0
    beq 9f
    ldr r0, [r0, #EPHASE]
    cmp r0, #1
    ldreq r0, =txt_warning
    moveq r1, #5
    moveq r3, #2
    beq 8f
    cmp r0, #3
    ldrne r0, =txt_boss_hint
    movne r1, #3
    movne r3, #1
    ldreq r0, =txt_recover
    moveq r1, #4
    moveq r3, #3
8:  mov r2, #2
    bl print_text
9:  pop {r4-r8, lr}
    bx lr

hide_sprites:
    ldr r0, =OAM
    mov r1, #0x0200
    mov r2, #128
1:  strh r1, [r0]
    add r0, r0, #8
    subs r2, r2, #1
    bne 1b
    bx lr

/* r0 OAM address, r1 x, r2 y, r3 tile|palette, r12 size bits. */
put_sprite:
    and r2, r2, #255
    strh r2, [r0]
    mov r1, r1, lsl #23        @ Keep the nine hardware position bits.
    mov r1, r1, lsr #23
    orr r1, r1, r12
    strh r1, [r0, #2]
    strh r3, [r0, #4]
    bx lr

render_game:
    push {r4-r8, lr}
    bl hide_sprites
    ldr r0, =game_state
    ldr r4, [r0]
    cmp r4, #TITLE
    beq render_title
    cmp r4, #DEAD
    beq 9f
    cmp r4, #VICTORY
    beq 9f
    cmp r4, #PLAYING
    bleq draw_hud
    ldr r0, =player_iframes
    ldr r0, [r0]
    cmp r0, #0
    beq 1f
    ldr r0, =frame_tick
    ldr r0, [r0]
    tst r0, #4
    bne 2f
1:  ldr r0, =OAM
    ldr r1, =player_x
    ldr r1, [r1]
    ldr r2, =player_y
    ldr r2, [r2]
    ldr r3, =facing
    ldr r3, [r3]
    mov r3, r3, lsl #3
    ldr r5, =keys
    ldr r5, [r5]
    tst r5, #0xf0
    beq 11f
    ldr r5, =frame_tick
    ldr r5, [r5]
    tst r5, #8
    addne r3, r3, #4
11: mov r12, #0x4000
    bl put_sprite
2:  ldr r4, =enemies
    ldr r5, =(OAM+8)
    mov r6, #MAX_ENEMIES
3:  ldr r0, [r4, #EHP]
    cmp r0, #0
    beq 7f
    ldr r7, [r4, #ETYPE]
    cmp r7, #0
    moveq r3, #32
    cmp r7, #1
    moveq r3, #40
    cmp r7, #2
    moveq r3, #48
    ldr r0, =frame_tick
    ldr r0, [r0]
    tst r0, #16
    beq 4f
    cmp r7, #2
    addeq r3, r3, #16
    addne r3, r3, #4
4:  add r8, r7, #1
    ldr r0, [r4, #EHURT]
    cmp r0, #0
    movgt r8, #5
    ldr r0, [r4, #EPHASE]
    cmp r0, #1
    bne 5f
    ldr r0, =frame_tick
    ldr r0, [r0]
    tst r0, #4
    movne r8, #5
5:  orr r3, r3, r8, lsl #12
    ldr r1, [r4, #EX]
    ldr r2, [r4, #EY]
    cmp r7, #2
    moveq r12, #0x8000
    movne r12, #0x4000
    mov r0, r5
    bl put_sprite
7:  add r4, r4, #ENEMY_SIZE
    add r5, r5, #8
    subs r6, r6, #1
    bne 3b
    ldr r0, =attack_timer
    ldr r0, [r0]
    cmp r0, #0
    beq 9f
    ldr r0, =(OAM+40)
    ldr r1, =attack_x
    ldr r1, [r1]
    ldr r2, =attack_y
    ldr r2, [r2]
    ldr r3, =facing
    ldr r3, [r3]
    mov r3, r3, lsl #4
    add r3, r3, #80
    orr r3, r3, #0x4000
    mov r12, #0x8000
    bl put_sprite
9:  pop {r4-r8, lr}
    bx lr
render_title:
    ldr r0, =OAM
    mov r1, #88
    mov r2, #76
    mov r3, #16
    mov r12, #0x4000
    bl put_sprite
    ldr r0, =(OAM+8)
    mov r1, #128
    mov r2, #68
    ldr r3, =0x3030
    mov r12, #0x8000
    bl put_sprite
    b 9b

title_screen:
    push {r4, lr}
    bl clear_map
    ldr r0, =txt_name
    mov r1, #10
    mov r2, #4
    mov r3, #1
    bl print_text
    ldr r0, =txt_tagline
    mov r1, #2
    mov r2, #6
    mov r3, #0
    bl print_text
    ldr r0, =txt_start
    mov r1, #8
    mov r2, #13
    mov r3, #3
    bl print_text
    ldr r0, =txt_keys
    mov r1, #4
    mov r2, #15
    mov r3, #0
    bl print_text
    ldr r0, =txt_credit
    mov r1, #5
    mov r2, #18
    mov r3, #1
    bl print_text
    pop {r4, lr}
    bx lr

/* Shared end-screen layout, r4 heading and r5 message. */
end_screen:
    push {r4-r6, lr}
    bl clear_map
    mov r0, r4
    mov r1, #8
    mov r2, #6
    mov r3, #1
    bl print_text
    mov r0, r5
    mov r1, #3
    mov r2, #9
    mov r3, #0
    bl print_text
    ldr r0, =txt_retry
    mov r1, #6
    mov r2, #13
    mov r3, #3
    bl print_text
    pop {r4-r6, lr}
    bx lr

death_screen:
    push {r4-r5, lr}
    ldr r4, =txt_dead
    ldr r5, =txt_dead_msg
    bl end_screen
    pop {r4-r5, lr}
    bx lr

victory_screen:
    push {r4-r5, lr}
    ldr r4, =txt_win
    ldr r5, =txt_win_msg
    bl end_screen
    pop {r4-r5, lr}
    bx lr

pause_screen:
    push {lr}
    ldr r0, =txt_pause
    mov r1, #11
    mov r2, #9
    mov r3, #1
    bl print_text
    ldr r0, =txt_resume
    mov r1, #7
    mov r2, #11
    mov r3, #0
    bl print_text
    pop {lr}
    bx lr

sound_sword:
    ldr r0, =0x86c0
    ldr r1, =0xa280
    b sound_note
sound_hurt:
    ldr r0, =0x82d0
    ldr r1, =0xc380
    b sound_note
sound_gate:
    ldr r0, =0x87b0
    ldr r1, =0xb480
sound_note:
    ldr r2, =0x04000060
    mov r3, #0
    strh r3, [r2]
    strh r1, [r2, #2]
    strh r0, [r2, #4]
    bx lr

.ltorg
.section .rodata
txt_name:      .asciz "GATEBLADE"
txt_tagline:   .asciz "A SWORD. FOUR SEALED ROOMS."
txt_start:     .asciz "PRESS START / A"
txt_keys:      .asciz "D-PAD MOVE   A SWORD"
txt_credit:    .asciz "ASSEMBLY / ARM7TDMI"
txt_room:      .asciz "ROOM"
txt_four:      .asciz "/4"
txt_controls:  .asciz "A SWORD   START PAUSE"
txt_foes:      .asciz "FOES"
txt_locked:    .asciz "DEFEAT ALL TO OPEN THE GATE"
txt_open:      .asciz "GATE OPEN - WALK NORTH"
txt_boss:      .asciz "BOSS"
txt_warning:   .asciz "WARDEN IS CHARGING!"
txt_recover:   .asciz "RECOVERING - STRIKE NOW"
txt_boss_hint: .asciz "DODGE THE CHARGE. STRIKE."
txt_pause:     .asciz "PAUSED"
txt_resume:    .asciz "START TO RESUME"
txt_dead:      .asciz "YOU HAVE FALLEN"
txt_dead_msg:  .asciz "THE GATES CLAIM ANOTHER."
txt_win:       .asciz "GATES CONQUERED"
txt_win_msg:   .asciz "THE WARDEN HAS FALLEN."
txt_retry:     .asciz "START / A TO RETRY"
.balign 4
