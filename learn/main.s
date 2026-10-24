@ Um tower defense pequeno. Todo o jogo deste exemplo cabe neste arquivo.
@ LESSON e definido pelo assembler: 1=tela, 2=heroi, 3=inimigo, 4=defesa.
@ snippet: setup
.syntax unified
.cpu arm7tdmi
.arm
.ifndef LESSON
.equ LESSON, 4
.endif
.if (LESSON < 1) || (LESSON > 4)
.error "LESSON must be 1, 2, 3 or 4"
.endif
.equ VRAM,       0x06000000
.equ KEYINPUT,   0x04000130
.equ VCOUNT,     0x04000006
.equ A,          1
.equ START,      8
.equ RIGHT,      16
.equ LEFT,       32
.equ UP,         64
.equ DOWN,       128
.equ R,          256
.equ GRASS,      0x10c4      @ RGB de 5 bits: r | (g << 5) | (b << 10).
.equ ROAD,       0x2e51
.equ BLUE,       0x7e60
.equ GOLD,       0x03ff
.equ GREEN,      0x03e0
.equ RED,        0x001f
.equ GRAY,       0x318c
.equ RUNNING,    0
.equ WON,        1
.equ LOST,       2

.section .header, "ax"
.global _start
_start:
    b boot
    .space 188              @ Reserva o cabecalho, preenchido por tools/rom.py.
    b _start                @ Offset 0xC0: esta ROM e cartucho, nao multiboot.

.section .text
boot:
    msr cpsr_c, #0xdf        @ Modo System, sem interrupcoes; usaremos polling.
    ldr sp, =0x03007f00      @ Pilha na RAM interna.
    ldr r0, =frame_tick
    mov r1, #0
    str r1, [r0]
    str r1, [r0, #4]         @ keys e pressed tambem comecam zerados.
    str r1, [r0, #8]
    bl new_game
    ldr r0, =0x04000000
    ldr r1, =0x0403          @ Mode 3 e BG2: pixels diretos, sem tiles ou sprites.
    strh r1, [r0]
@ end: setup

@ snippet: loop
main_loop:
    bl wait_vblank
    ldr r0, =frame_tick
    ldr r1, [r0]
    add r1, r1, #1
    str r1, [r0]
    bl read_keys
    ldr r0, =pressed
    ldr r0, [r0]
    tst r0, #START
    blne new_game           @ Start recomeca, inclusive durante a partida.
    ldr r0, =hero_col
    ldr r0, [r0]
    ldr r1, =old_col
    str r0, [r1]
    ldr r0, =hero_row
    ldr r0, [r0]
    ldr r1, =old_row
    str r0, [r1]
    ldr r0, =game_state
    ldr r0, [r0]
    cmp r0, #RUNNING
    bne render
.if LESSON >= 2
    bl move_hero
.endif
.if LESSON >= 4
    bl build_tower
.endif
.if LESSON >= 3
    bl update_wave
.endif
.if LESSON >= 4
    bl fire_tower
    bl check_exit
.endif
render:
    bl draw_scene
    b main_loop

wait_vblank:
    ldr r0, =VCOUNT
1:  ldrh r1, [r0]
    cmp r1, #160
    bhs 1b                 @ Primeiro, sair do VBlank atual.
2:  ldrh r1, [r0]
    cmp r1, #160
    blo 2b                 @ Depois, esperar o proximo.
    bx lr

read_keys:
    ldr r0, =KEYINPUT
    ldrh r1, [r0]
    mvn r1, r1             @ Hardware: zero significa pressionado. Invertemos.
    ldr r0, =0x03ff
    and r1, r1, r0
    ldr r0, =keys
    ldr r2, [r0]
    str r1, [r0]
    bic r1, r1, r2         @ Agora pressionado E antes solto.
    ldr r0, =pressed
    str r1, [r0]
    bx lr
@ end: loop

@ snippet: state
new_game:
    push {r4, lr}
    ldr r0, =game_state      @ Preservar relogio e botoes durante um reinicio.
    ldr r1, =__bss_end
    mov r2, #0
1:  cmp r0, r1
    strlo r2, [r0], #4
    blo 1b
    ldr r0, =hero_col
    mov r1, #1
    str r1, [r0]
    ldr r0, =hero_row
    mov r1, #6
    str r1, [r0]
    ldr r0, =coins
    mov r1, #20
    str r1, [r0]
    ldr r0, =base_hp
    mov r1, #3
    str r1, [r0]
    mov r0, #0
    mov r1, #0
    mov r2, #240
    mov r3, #160
    ldr r4, =GRASS
    bl fill_rect
    pop {r4, lr}
    bx lr
.ltorg
@ end: state

@ snippet: movement
.if LESSON >= 2
move_hero:
    ldr r0, =move_cooldown
    ldr r1, [r0]
    cmp r1, #0
    subne r1, r1, #1
    strne r1, [r0]
    bxne lr
    ldr r0, =keys
    ldr r3, [r0]
    mov r2, #-1
    tst r3, #DOWN
    movne r2, #2
    tst r3, #UP
    movne r2, #0
    tst r3, #RIGHT
    movne r2, #1
    tst r3, #LEFT
    movne r2, #3
    cmp r2, #0
    bxlt lr
    ldr r0, =facing
    str r2, [r0]
    tst r3, #A              @ Direcao + A apenas vira, para construir ao lado.
    bxne lr
    @ Calcular a celula de destino usando a direcao em r2.
    ldr r0, =hero_col
    ldr r0, [r0]
    ldr r1, =hero_row
    ldr r1, [r1]
    cmp r2, #0
    subeq r1, r1, #1
    cmp r2, #1
    addeq r0, r0, #1
    cmp r2, #2
    addeq r1, r1, #1
    cmp r2, #3
    subeq r0, r0, #1
    cmp r0, #14
    bxhs lr                @ Comparacao sem sinal tambem rejeita -1.
    cmp r1, #7
    bxhs lr
    cmp r0, #13
    cmpeq r1, #3
    bxeq lr                @ Nao entrar na base.
    cmp r0, #6
    cmpeq r1, #2
    bne 1f
    ldr r2, =tower_built
    ldr r2, [r2]
    cmp r2, #0
    bxne lr                @ A torre ocupa o ponto (6,2), fora da estrada.
1:  cmp r0, #12
    cmpeq r1, #6
    bne 2f
    ldr r2, =wave_started
    ldr r2, [r2]
    cmp r2, #0
    bxeq lr
    ldr r2, =remaining
    ldr r2, [r2]
    ldr r3, =enemy_hp
    ldr r3, [r3]
    orrs r2, r2, r3
    bxne lr                @ Portal bloqueado ate terminar a onda.
2:  ldr r2, =hero_col
    str r0, [r2]
    ldr r2, =hero_row
    str r1, [r2]
    ldr r0, =move_cooldown
    mov r1, #7             @ Um salto de celula a cada oito atualizacoes.
    str r1, [r0]
    bx lr
.endif
@ end: movement

@ snippet: construction
.if LESSON >= 4
build_tower:
    ldr r0, =pressed
    ldr r0, [r0]
    tst r0, #A
    bxeq lr
    ldr r0, =tower_built
    ldr r0, [r0]
    cmp r0, #0
    bxne lr                @ Neste exemplo so existe uma torre, sem melhoria.
    ldr r0, =hero_col
    ldr r0, [r0]
    ldr r1, =hero_row
    ldr r1, [r1]
    ldr r2, =facing
    ldr r2, [r2]
    cmp r2, #0
    subeq r1, r1, #1
    cmp r2, #1
    addeq r0, r0, #1
    cmp r2, #2
    addeq r1, r1, #1
    cmp r2, #3
    subeq r0, r0, #1
    cmp r0, #6
    cmpeq r1, #2
    bxne lr                @ A celula a frente precisa ser o ponto dourado.
    ldr r0, =coins
    ldr r1, [r0]
    cmp r1, #20
    bxlo lr
    sub r1, r1, #20
    str r1, [r0]
    ldr r0, =tower_built
    mov r1, #1
    str r1, [r0]
    bx lr
.endif
@ end: construction

@ snippet: wave
.if LESSON >= 3
update_wave:
    ldr r0, =wave_started
    ldr r1, [r0]
    cmp r1, #0
    bne 1f
    ldr r1, =pressed
    ldr r1, [r1]
    tst r1, #R
    bxeq lr
    mov r1, #1
    str r1, [r0]
    ldr r0, =remaining
    mov r1, #4
    str r1, [r0]
1:  ldr r0, =enemy_hp
    ldr r1, [r0]
    cmp r1, #0
    bne march
    ldr r0, =remaining
    ldr r1, [r0]
    cmp r1, #0
    bxeq lr                @ Onda terminada: nao criar outro inimigo.
    sub r1, r1, #1
    str r1, [r0]
    ldr r0, =enemy_x
    mov r1, #8
    str r1, [r0]
    ldr r0, =enemy_hp
    mov r1, #2
    str r1, [r0]
    bx lr
march:
    ldr r0, =enemy_x
    ldr r1, [r0]
    add r1, r1, #1          @ Estrada reta: apenas o X muda, um pixel por frame.
    str r1, [r0]
    cmp r1, #216
    bxlo lr
    ldr r0, =enemy_hp
    mov r1, #0
    str r1, [r0]
    ldr r0, =base_hp
    ldr r1, [r0]
    subs r1, r1, #1
    str r1, [r0]
    bxne lr
    ldr r0, =game_state
    mov r1, #LOST
    str r1, [r0]
    bx lr
.endif
@ end: wave

@ snippet: combat
.if LESSON >= 4
fire_tower:
    ldr r0, =tower_built
    ldr r0, [r0]
    cmp r0, #0
    bxeq lr
    ldr r0, =shot_cooldown
    ldr r1, [r0]
    cmp r1, #0
    subne r1, r1, #1
    strne r1, [r0]
    bxne lr
    ldr r0, =enemy_hp
    ldr r1, [r0]
    cmp r1, #0
    bxeq lr
    ldr r2, =enemy_x
    ldr r2, [r2]
    sub r2, r2, #104        @ Torre em (104,64); inimigo sempre na linha Y=80.
    cmp r2, #0
    rsblt r2, r2, #0
    add r2, r2, #16         @ |dx| + |dy|: distancia Manhattan.
    cmp r2, #48
    bxhi lr
    sub r1, r1, #1
    str r1, [r0]
    ldr r0, =shot_cooldown
    mov r2, #24
    str r2, [r0]
    cmp r1, #0
    bxne lr
    ldr r0, =coins
    ldr r1, [r0]
    add r1, r1, #5          @ Recompensa apenas na passagem de vivo para morto.
    str r1, [r0]
    bx lr

check_exit:
    ldr r0, =game_state
    ldr r0, [r0]
    cmp r0, #RUNNING
    bxne lr
    ldr r0, =wave_started
    ldr r0, [r0]
    cmp r0, #0
    bxeq lr
    ldr r0, =remaining
    ldr r0, [r0]
    ldr r1, =enemy_hp
    ldr r1, [r1]
    orrs r0, r0, r1
    bxne lr
    ldr r0, =hero_col
    ldr r0, [r0]
    cmp r0, #12
    ldr r0, =hero_row
    ldreq r0, [r0]
    cmpeq r0, #6
    bxne lr
    ldr r0, =game_state
    mov r1, #WON
    str r1, [r0]
    bx lr
.endif
.ltorg
@ end: combat

@ snippet: pixels
@ r0=X, r1=Y, r2=largura, r3=altura, r4=cor. So usamos areas dentro da tela.
fill_rect:
    push {r5-r8, lr}
    mov r5, #240
    mul r6, r1, r5
    add r6, r6, r0
    ldr r5, =VRAM
    add r5, r5, r6, lsl #1   @ Dois bytes por pixel no Mode 3.
    rsb r7, r2, #240
    mov r7, r7, lsl #1      @ Distancia do fim desta linha ao inicio da proxima.
    mov r6, r3
1:  mov r8, r2
2:  strh r4, [r5], #2
    subs r8, r8, #1
    bne 2b
    add r5, r5, r7
    subs r6, r6, #1
    bne 1b
    pop {r5-r8, lr}
    bx lr

@ r0=coluna, r1=linha, r4=cor. Cada celula e 16x16; origem em (8,32).
paint_cell:
    push {lr}
    mov r0, r0, lsl #4
    add r0, r0, #8
    mov r1, r1, lsl #4
    add r1, r1, #32
    mov r2, #16
    mov r3, #16
    bl fill_rect
    pop {lr}
    bx lr
@ end: pixels

@ snippet: drawing
draw_scene:
    push {r4-r8, lr}
    ldr r0, =old_col
    ldr r0, [r0]
    ldr r1, =old_row
    ldr r1, [r1]
    ldr r4, =GRASS
    bl paint_cell           @ Apagar a posicao anterior do heroi.
    mov r0, #8
    mov r1, #80
    mov r2, #224
    mov r3, #16
    ldr r4, =ROAD
    bl fill_rect           @ Restaurar a estrada apaga o inimigo anterior.
    mov r0, #13
    mov r1, #3
    ldr r4, =BLUE
    bl paint_cell
    mov r0, #6
    mov r1, #2
    ldr r4, =GOLD
    ldr r2, =tower_built
    ldr r2, [r2]
    cmp r2, #0
    ldrne r4, =BLUE
    bl paint_cell
    mov r0, #12
    mov r1, #6
    ldr r4, =GRAY
    ldr r2, =wave_started
    ldr r2, [r2]
    cmp r2, #0
    beq 1f
    ldr r2, =remaining
    ldr r2, [r2]
    ldr r3, =enemy_hp
    ldr r3, [r3]
    orrs r2, r2, r3
    ldreq r4, =GREEN
1:  bl paint_cell
.if LESSON >= 2
    ldr r0, =hero_col
    ldr r0, [r0]
    ldr r1, =hero_row
    ldr r1, [r1]
    ldr r4, =0x7fff
    bl paint_cell
.endif
.if LESSON >= 3
    ldr r0, =enemy_hp
    ldr r0, [r0]
    cmp r0, #0
    beq 2f
    ldr r0, =enemy_x
    ldr r0, [r0]
    mov r1, #82
    mov r2, #12
    mov r3, #12
    ldr r4, =RED
    bl fill_rect
2:
.endif
    mov r5, #0
3:  mov r0, r5, lsl #4
    add r0, r0, #8
    mov r1, #8
    mov r2, #8
    mov r3, #8
    ldr r4, =GRAY
    ldr r6, =base_hp
    ldr r6, [r6]
    cmp r5, r6
    ldrlo r4, =RED
    bl fill_rect
    add r5, r5, #1
    cmp r5, #3
    blo 3b
    ldr r0, =coins
    ldr r6, [r0]
    mov r5, #0
4:  mov r0, r5, lsl #4
    add r0, r0, #64
    mov r1, #8
    mov r2, #8
    mov r3, #8
    ldr r4, =GRAY
    cmp r6, #5
    ldrhs r4, =GOLD
    subhs r6, r6, #5
    bl fill_rect
    add r5, r5, #1
    cmp r5, #8
    blo 4b
    mov r0, #8
    mov r1, #152
    mov r2, #224
    mov r3, #4
    ldr r4, =BLUE
    ldr r0, =game_state
    ldr r0, [r0]
    cmp r0, #WON
    ldreq r4, =GREEN
    cmp r0, #LOST
    ldreq r4, =RED
    mov r0, #8
    bl fill_rect           @ Barra: azul=jogando, verde=vitoria, vermelho=derrota.
    pop {r4-r8, lr}
    bx lr
.ltorg
@ end: drawing

@ snippet: variables
.section .bss
.balign 4
.global game_state, frame_tick, keys, pressed, hero_col, hero_row, facing
.global coins, base_hp, tower_built, enemy_x, enemy_hp, remaining, wave_started
frame_tick:     .space 4
keys:           .space 4
pressed:        .space 4
game_state:     .space 4
hero_col:       .space 4
hero_row:       .space 4
old_col:        .space 4
old_row:        .space 4
facing:         .space 4
move_cooldown:  .space 4
coins:          .space 4
base_hp:        .space 4
tower_built:    .space 4
shot_cooldown:  .space 4
enemy_x:        .space 4
enemy_hp:       .space 4
remaining:      .space 4
wave_started:   .space 4
@ end: variables
