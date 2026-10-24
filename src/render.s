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

/* r0 top-left BG address, r1 first of four consecutive metatile tiles. */
draw_meta:
    strh r1, [r0]
    add r1, r1, #1
    strh r1, [r0, #2]
    add r1, r1, #1
    strh r1, [r0, #64]
    add r1, r1, #1
    strh r1, [r0, #66]
    bx lr

/* r0 logical column, r1 row -> map address. */
cell_address:
    ldr r2, =(BG_MAP+4*64+2)
    add r2, r2, r0, lsl #2
    add r0, r2, r1, lsl #7
    bx lr

draw_world:
    push {r4-r8, lr}
    bl clear_map
    mov r4, #0
    ldr r0, =map_ptr
    ldr r5, [r0]
    mov r6, #0
1:  mov r7, #0
2:  ldrb r8, [r5, r4]
    mov r0, r7
    mov r1, r6
    bl cell_address
    mov r1, #1
    cmp r8, #0
    beq 3f
    cmp r8, #4
    beq 3f
    cmp r8, #1
    moveq r1, #9
    cmp r8, #2
    moveq r1, #28
    cmp r8, #3
    moveq r1, #20
    bl draw_meta
    b 4f
3:  strh r1, [r0]
    mov r1, #8
    strh r1, [r0, #2]
    strh r1, [r0, #64]
    mov r1, #1
    strh r1, [r0, #66]
4:  add r4, r4, #1
    add r7, r7, #1
    cmp r7, #MAP_COLS
    blo 2b
    add r6, r6, #1
    cmp r6, #MAP_ROWS
    blo 1b
    ldr r0, =pads_ptr
    ldr r4, [r0]
    mov r5, #MAX_TOWERS
5:  ldr r0, [r4], #4
    sub r0, r0, #8
    mov r0, r0, lsr #4
    ldr r1, [r4], #4
    sub r1, r1, #32
    mov r1, r1, lsr #4
    bl cell_address
    mov r1, #16
    bl draw_meta
    subs r5, r5, #1
    bne 5b
    ldr r0, =(BG_MAP+3*64)
    ldr r1, =(BG_MAP+18*64)
    mov r2, #30
    mov r3, #2
6:  strh r3, [r0], #2
    strh r3, [r1], #2
    subs r2, r2, #1
    bne 6b
    bl draw_portal
    bl draw_hud
    pop {r4-r8, lr}
    bx lr

draw_portal:
    push {lr}
    mov r0, #12
    mov r1, #6
    bl cell_address
    ldr r1, =stage_clear
    ldr r1, [r1]
    cmp r1, #0
    movne r1, #24
    blne draw_meta
    bne 1f
    mov r1, #3
    strh r1, [r0]
    strh r1, [r0, #2]
    strh r1, [r0, #64]
    strh r1, [r0, #66]
1:  pop {lr}
    bx lr

print_gold:
    push {r4, lr}
    mov r4, #0
1:  cmp r0, #100
    subge r0, r0, #100
    addge r4, r4, #1
    bge 1b
    push {r0}
    mov r0, r4
    add r0, r0, #48
    orr r0, r0, r3, lsl #12
    ldr r12, =BG_MAP
    add r12, r12, r2, lsl #6
    add r12, r12, r1, lsl #1
    strh r0, [r12]
    pop {r0}
    add r1, r1, #1
    bl print_number
    pop {r4, lr}
    bx lr

draw_hud:
    push {r4-r6, lr}
    ldr r0, =txt_name
    mov r1, #1
    mov r2, #0
    mov r3, #1
    bl print_text
    ldr r0, =txt_map
    mov r1, #19
    mov r2, #0
    mov r3, #0
    bl print_text
    ldr r0, =stage_index
    ldr r0, [r0]
    add r0, r0, #1
    mov r1, #23
    mov r2, #0
    mov r3, #1
    bl print_number
    ldr r0, =txt_ten
    mov r1, #25
    mov r2, #0
    mov r3, #0
    bl print_text
    ldr r4, =(BG_MAP+64+2)
    ldr r0, =base_hp
    ldr r5, [r0]
    mov r6, #0
1:  cmp r6, r5
    movlt r0, #6
    movge r0, #7
    strh r0, [r4], #2
    add r6, r6, #1
    cmp r6, #BASE_HP_MAX
    blo 1b
    ldr r0, =txt_gold
    mov r1, #8
    mov r2, #1
    mov r3, #1
    bl print_text
    ldr r0, =coins
    ldr r0, [r0]
    mov r1, #9
    mov r2, #1
    mov r3, #1
    bl print_gold
    ldr r0, =txt_wave
    mov r1, #14
    mov r2, #1
    mov r3, #0
    bl print_text
    ldr r0, =wave_index
    ldr r0, [r0]
    add r0, r0, #1
    ldr r1, =stage_waves
    ldr r1, [r1]
    cmp r0, r1
    movhi r0, r1
    mov r1, #15
    mov r2, #1
    mov r3, #0
    bl print_number
    ldr r0, =txt_slash
    mov r1, #17
    mov r2, #1
    mov r3, #0
    bl print_text
    ldr r0, =stage_waves
    ldr r0, [r0]
    mov r1, #18
    mov r2, #1
    mov r3, #0
    bl print_number
    ldr r0, =txt_foes
    mov r1, #22
    mov r2, #1
    mov r3, #0
    bl print_text
    ldr r0, =enemies_alive
    ldr r0, [r0]
    ldr r1, =spawn_remaining
    ldr r1, [r1]
    add r0, r0, r1
    mov r1, #23
    mov r2, #1
    mov r3, #2
    bl print_number
    ldr r4, =(BG_MAP+2*64)
    ldr r5, =(BG_MAP+19*64)
    mov r0, #0
    mov r1, #30
2:  strh r0, [r4], #2
    strh r0, [r5], #2
    subs r1, r1, #1
    bne 2b
    ldr r0, =txt_prep
    ldr r1, =wave_active
    ldr r1, [r1]
    cmp r1, #0
    ldrne r0, =txt_defend
    ldr r1, =stage_index
    ldr r1, [r1]
    cmp r1, #0
    bne 3f
    ldr r1, =towers_built
    ldr r1, [r1]
    cmp r1, #0
    ldreq r0, =txt_tutorial
3:  ldr r1, =stage_clear
    ldr r1, [r1]
    cmp r1, #0
    ldrne r0, =txt_open
    ldr r1, =notice_timer
    ldr r1, [r1]
    cmp r1, #0
    beq 4f
    ldr r1, =notice_code
    ldr r1, [r1]
    cmp r1, #1
    ldreq r0, =txt_invalid
    cmp r1, #2
    ldreq r0, =txt_poor
    cmp r1, #3
    ldreq r0, =txt_max
4:  mov r1, #1
    mov r2, #2
    mov r3, #0
    bl print_text
    ldr r0, =selected_type
    ldr r4, [r0]
    ldr r0, =txt_bolt
    cmp r4, #1
    ldreq r0, =txt_frost
    cmp r4, #2
    ldreq r0, =txt_cannon
    mov r1, #1
    mov r2, #19
    mov r3, #1
    bl print_text
    ldr r0, =txt_controls
    mov r1, #12
    mov r2, #19
    mov r3, #0
    bl print_text
    pop {r4-r6, lr}
    bx lr
.ltorg

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
    mov r1, r1, lsl #23
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
    beq render_done
    cmp r4, #VICTORY
    beq render_done
    cmp r4, #PLAYING
    bleq draw_hud
    ldr r0, =OAM
    ldr r1, =player_x
    ldr r1, [r1]
    ldr r2, =player_y
    ldr r2, [r2]
    ldr r3, =facing
    ldr r3, [r3]
    mov r3, r3, lsl #3
    ldr r5, =move_left
    ldr r5, [r5]
    cmp r5, #0
    beq 1f
    ldr r5, =frame_tick
    ldr r5, [r5]
    tst r5, #4
    addne r3, r3, #4
1:  mov r12, #0x4000
    bl put_sprite
    ldr r4, =enemies
    ldr r5, =(OAM+8)
    mov r6, #MAX_ENEMIES
2:  ldr r0, [r4, #EHP]
    cmp r0, #0
    beq 5f
    ldr r7, [r4, #ETYPE]
    mov r3, #32
    cmp r7, #1
    moveq r3, #40
    cmp r7, #2
    moveq r3, #48
    ldr r0, =frame_tick
    ldr r0, [r0]
    tst r0, #16
    beq 3f
    cmp r7, #2
    addeq r3, r3, #16
    addne r3, r3, #4
3:  add r8, r7, #1
    ldr r0, [r4, #EHURT]
    cmp r0, #0
    movgt r8, #5
    orr r3, r3, r8, lsl #12
    ldr r1, [r4, #EX]
    ldr r2, [r4, #EY]
    cmp r7, #2
    subeq r1, r1, #8
    subeq r2, r2, #8
    moveq r12, #0x8000
    movne r12, #0x4000
    mov r0, r5
    bl put_sprite
5:  add r4, r4, #ENEMY_SIZE
    add r5, r5, #8
    subs r6, r6, #1
    bne 2b
    ldr r4, =towers
    mov r5, #0
6:  ldr r6, [r4, #TLEVEL]
    cmp r6, #0
    beq 8f
    ldr r7, [r4, #TTYPE]
    add r3, r7, #6
    mov r3, r3, lsl #12
    add r3, r3, #144
    add r3, r3, r7, lsl #3
    cmp r6, #2
    addeq r3, r3, #4
    ldr r0, =(OAM+13*8)
    add r0, r0, r5, lsl #3
    ldr r1, [r4, #TX]
    ldr r2, [r4, #TY]
    mov r12, #0x4000
    bl put_sprite
    ldr r0, [r4, #TSHOT]
    cmp r0, #0
    beq 8f
    ldr r0, [r4, #TTARGET]
    mov r1, #ENEMY_SIZE
    mul r2, r0, r1
    ldr r0, =enemies
    add r0, r0, r2
    ldr r1, [r0, #EX]
    ldr r2, [r0, #EY]
    ldr r0, [r4, #TX]
    add r1, r1, r0
    mov r1, r1, lsr #1
    add r1, r1, #4
    ldr r0, [r4, #TY]
    add r2, r2, r0
    mov r2, r2, lsr #1
    add r2, r2, #4
    add r3, r7, #168
    orr r3, r3, #0x4000
    ldr r0, =(OAM+21*8)
    add r0, r0, r5, lsl #3
    mov r12, #0
    bl put_sprite
8:  add r4, r4, #TOWER_SIZE
    add r5, r5, #1
    cmp r5, #MAX_TOWERS
    blo 6b
    ldr r0, =attack_timer
    ldr r0, [r0]
    cmp r0, #0
    beq 9f
    ldr r0, =(OAM+29*8)
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
9:  ldr r0, =move_left
    ldr r0, [r0]
    cmp r0, #0
    bne render_done
    bl facing_cell
    cmp r0, #MAP_COLS
    bhs render_done
    cmp r1, #MAP_ROWS
    bhs render_done
    mov r2, r1, lsl #4
    add r2, r2, #32
    mov r1, r0, lsl #4
    add r1, r1, #8
    ldr r0, =(OAM+30*8)
    ldr r3, =0x40b0
    mov r12, #0x4000
    bl put_sprite
render_done:
    pop {r4-r8, lr}
    bx lr
render_title:
    ldr r0, =OAM
    mov r1, #48
    mov r2, #72
    mov r3, #16
    mov r12, #0x4000
    bl put_sprite
    ldr r0, =(OAM+8)
    mov r1, #96
    mov r2, #72
    ldr r3, =0x6090
    mov r12, #0x4000
    bl put_sprite
    ldr r0, =(OAM+16)
    mov r1, #136
    mov r2, #72
    ldr r3, =0x7098
    mov r12, #0x4000
    bl put_sprite
    ldr r0, =(OAM+24)
    mov r1, #176
    mov r2, #72
    ldr r3, =0x80a0
    mov r12, #0x4000
    bl put_sprite
    b render_done
.ltorg

title_screen:
    push {lr}
    bl clear_map
    ldr r0, =txt_name
    mov r1, #9
    mov r2, #3
    mov r3, #1
    bl print_text
    ldr r0, =txt_tagline
    mov r1, #3
    mov r2, #5
    mov r3, #0
    bl print_text
    ldr r0, =txt_start
    mov r1, #8
    mov r2, #12
    mov r3, #3
    bl print_text
    ldr r0, =txt_keys
    mov r1, #1
    mov r2, #14
    mov r3, #0
    bl print_text
    ldr r0, =txt_keys2
    mov r1, #2
    mov r2, #16
    mov r3, #0
    bl print_text
    ldr r0, =txt_credit
    mov r1, #5
    mov r2, #18
    mov r3, #1
    bl print_text
    pop {lr}
    bx lr

end_screen:
    push {r4-r6, lr}
    bl clear_map
    mov r0, r4
    mov r1, #5
    mov r2, #6
    mov r3, #1
    bl print_text
    mov r0, r5
    mov r1, #2
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
txt_name: .asciz "GATEBLADE TD"
txt_tagline: .asciz "TEN MAPS. GUARD THE BASE."
txt_start: .asciz "PRESS START / A"
txt_keys: .asciz "D-PAD MOVE  A BUILD  B SWORD"
txt_keys2: .asciz "L TOWER TYPE  R SEND WAVE"
txt_credit: .asciz "ASSEMBLY / ARM7TDMI"
txt_map: .asciz "MAP"
txt_ten: .asciz "/10"
txt_gold: .asciz "G"
txt_wave: .asciz "W"
txt_slash: .asciz "/"
txt_foes: .asciz "F"
txt_controls: .asciz "L TYPE  R WAVE"
txt_bolt: .asciz "BOLT 20G"
txt_frost: .asciz "FROST 30G"
txt_cannon: .asciz "BLAST 40G"
txt_tutorial: .asciz "FACE A GOLD PAD. A BUILDS"
txt_prep: .asciz "BUILD OR UPGRADE. R: WAVE"
txt_defend: .asciz "DEFEND THE BLUE BASE"
txt_open: .asciz "ALL WAVES CLEAR - EXIT >"
txt_invalid: .asciz "FACE AN ADJACENT GOLD PAD"
txt_poor: .asciz "NOT ENOUGH GOLD"
txt_max: .asciz "TOWER ALREADY AT LEVEL 2"
txt_pause: .asciz "PAUSED"
txt_resume: .asciz "START TO RESUME"
txt_dead: .asciz "THE BASE HAS FALLEN"
txt_dead_msg: .asciz "TRY A DIFFERENT DEFENSE."
txt_win: .asciz "TEN BASES DEFENDED"
txt_win_msg: .asciz "THE TEN ROADS ARE SAFE."
txt_retry: .asciz "START / A TO RETRY"
.balign 4
