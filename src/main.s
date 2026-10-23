.syntax unified
.cpu arm7tdmi
.arm
.include "src/constants.inc"

.section .header, "ax"
.global _start
_start:
    b boot
    .space 188                  @ Logo and metadata filled by tools/rom.py.
    b _start                    @ 0xC0 is not a multiboot entry: cartridge only.

.section .text
boot:
    msr cpsr_c, #0xdf            @ System mode; polling loop, IRQ/FIQ disabled.
    ldr sp, =0x03007f00          @ Stack in internal work RAM.
    ldr r0, =__bss_start
    ldr r1, =__bss_end
    mov r2, #0
1:  cmp r0, r1
    strlo r2, [r0], #4
    blo 1b
    bl video_init
    bl title_screen

main_loop:
    bl wait_vblank
    ldr r4, =frame_tick
    ldr r0, [r4]
    add r0, r0, #1
    str r0, [r4]
    bl read_keys
    bl update_game
    bl render_game
    b main_loop

wait_vblank:
    ldr r0, =REG_VCOUNT
1:  ldrh r1, [r0]
    cmp r1, #160
    bhs 1b                      @ Leave the current blank first.
2:  ldrh r1, [r0]
    cmp r1, #160
    blo 2b                      @ Start exactly one update per new VBlank.
    bx lr

read_keys:
    ldr r0, =REG_KEYS
    ldrh r0, [r0]
    mvn r0, r0
    ldr r1, =0x03ff
    and r0, r0, r1
    ldr r1, =keys
    ldr r2, [r1]
    str r0, [r1]
    bic r0, r0, r2
    ldr r1, =pressed
    str r0, [r1]
    bx lr

.include "src/game.s"
.include "src/render.s"

.section .rodata
.balign 4
bg_tiles: .incbin "build/assets/bg.bin"
bg_tiles_end:
obj_tiles: .incbin "build/assets/obj.bin"
obj_tiles_end:
bg_palette: .incbin "build/assets/bg.pal"
obj_palette: .incbin "build/assets/obj.pal"

.section .bss
.balign 4
.global game_state, room_index, player_x, player_y, player_hp, enemies
.global attack_timer, attack_id, attack_cooldown, player_iframes, facing
.global enemies_alive, frame_tick, total_kills, keys, pressed
game_state:       .space 4
room_index:       .space 4
player_x:         .space 4
player_y:         .space 4
player_hp:        .space 4
facing:           .space 4
player_iframes:   .space 4
attack_timer:     .space 4
attack_cooldown:  .space 4
attack_id:        .space 4
enemies_alive:    .space 4
frame_tick:       .space 4
keys:             .space 4
pressed:          .space 4
total_kills:      .space 4
attack_x:         .space 4
attack_y:         .space 4
enemies:          .space ENEMY_SIZE * MAX_ENEMIES
