# Um tower defense para Game Boy Advance em assembly, do zero

Eu queria criar um jogo para Game Boy Advance e conseguir explicar como ele funciona. A primeira campanha cresceu até ter dez mapas, três tipos de torre, moedas, melhorias e um chefe. O resultado ficou jogável, mas começar a aprender por todos esses sistemas ao mesmo tempo exige entender muita coisa antes de modificar uma linha.

Este tutorial começa com um recorte menor: **uma estrada reta, um herói, um ponto de construção, uma torre e uma onda de quatro inimigos**. Vamos desenhar retângulos e escrever as regras em um arquivo assembly. No final, haverá uma partida completa: construir, defender, ganhar moedas, perder quando a base cai e caminhar até a saída para vencer.

O projeto original recebeu apoio de IA. O texto abaixo é uma sequência para implementar e entender o exemplo manualmente; não é uma alegação de que a campanha foi produzida toda à mão. Os trechos vêm do código executado nos testes e são conferidos automaticamente contra os arquivos do repositório.

A versão pequena está em [learn/main.s](../learn/main.s). A campanha completa continua disponível em [src/game.s](../src/game.s), com suas dez fases. Há um [guia rápido](../learn/README.md) para quem prefere primeiro abrir as quatro etapas no emulador.

## O que precisamos antes de começar

Você precisa conhecer variáveis, condições e laços. Vou explicar os registradores e as instruções usados, mas este não é um curso completo de arquitetura ARM.

Para construir a ROM, bastam GNU Binutils para `arm-none-eabi`, Python 3 e um terminal. Make é uma conveniência para quem clonou o projeto. Para jogar, uma instalação pronta do [mGBA](https://mgba.io/downloads.html) é suficiente. Não é necessário construir o emulador, instalar CMake ou gerar sprites para seguir este exemplo. A [reprodução do projeto](../docs/reproducao.md) mantém o caminho completo para testes automatizados.

Confira os comandos disponíveis:

```sh
arm-none-eabi-as --version
arm-none-eabi-ld --version
arm-none-eabi-objcopy --version
python3 --version
```

Os testes deste artigo usam Binutils 2.44, Python 3.13.3 e mGBA 0.10.5 no macOS. A evidência de Linux será registrada separadamente após a execução remota. Teste em GBA físico continua pendente.

## O primeiro objetivo: terminar uma partida pequena

O tabuleiro tem 14 colunas e sete linhas. Cada célula ocupa 16 pixels; sua origem é `(8,32)`. A estrada fica na linha 3. A base está na célula `(13,3)`, a torre em `(6,2)` e a saída em `(12,6)`. Portanto, a torre fica ao lado da estrada e nunca bloqueia o inimigo.

| Elemento | Representação no exemplo |
| --- | --- |
| Herói | Quadrado branco controlado pelo direcional |
| Inimigo | Quadrado vermelho que segue à direita |
| Base | Quadrado azul no fim da estrada |
| Ponto de construção | Quadrado amarelo; fica azul após construir |
| Saída | Cinza enquanto fechada, verde após a onda |
| Vida da base | Três quadrados vermelhos no alto |
| Moedas | Cada quadrado amarelo no alto vale cinco |
| Resultado | Barra inferior azul jogando, verde vitória, vermelha derrota |

A começa uma compra; R inicia a onda; Start reinicia. Segurar o direcional repete passos a cada oito atualizações. É um salto entre células, sem a animação de deslocamento suave da campanha completa. Também não teremos espada, melhorias, texto na tela ou áudio nesta versão pequena.

## 1. Criar os três arquivos

Crie uma pasta vazia. Nela, vamos escrever `main.s`, `gba.ld` e `rom.py`. Os blocos de assembly deste artigo, na ordem em que aparecem, formam `main.s`. Os dois últimos arquivos têm blocos próprios mais adiante. Assim você pode digitar, conferir e montar sem depender do restante do repositório.

```sh
mkdir meu-tower-defense
cd meu-tower-defense
```

No ARM, `r0` a `r12` são registradores de uso geral. `sp` é a pilha, `lr` guarda o retorno de uma chamada e `pc` indica a execução. `ldr r0, =nome` coloca um endereço ou constante no registrador; `ldr r1, [r0]` lê a palavra nesse endereço; `str r1, [r0]` a escreve. `bl rotina` chama uma função e `bx lr` retorna.

Comece `main.s` com as constantes e o ponto de entrada:

<!-- code: learn/main.s#setup -->
```asm
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
```
<!-- /code -->

`.cpu arm7tdmi` restringe a arquitetura. `LESSON` seleciona quais partes serão ativadas; sem parâmetro, vale 4, o jogo completo deste tutorial. As diretivas `.if` são decisões do assembler, tomadas no computador, não condições avaliadas pelo jogo.

O cabeçalho reserva os primeiros 192 bytes da ROM. O salto em `0xC0` preserva a entrada de cartucho usada pelo projeto. `boot` configura a pilha, inicia os controles e chama a preparação da partida.

Escolhi o **Mode 3**, que permite escrever a cor de cada pixel diretamente na memória de vídeo. O formato e a relação entre coordenadas e memória são descritos no [Tonc: bitmap modes](https://gbadev.net/tonc/bitmaps.html). Isso elimina tiles, paletas, sprites e conversão de imagens desta primeira implementação. O valor `0x0403` habilita o modo e BG2.

## 2. Separar entrada, regras e desenho

Acrescente o laço principal e a leitura dos botões:

<!-- code: learn/main.s#loop -->
```asm
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
```
<!-- /code -->

A sequência é sempre a mesma: esperar o próximo quadro, ler controles, atualizar regras e desenhar. `cmp` atualiza condições; sufixos como `eq`, `ne`, `lo` e `hs` fazem a instrução seguinte depender do resultado. Labels numéricos como `1:` podem se repetir: `1b` procura para trás; `1f`, para a frente.

Os botões do GBA são ativos em zero; por isso usamos `mvn` e limitamos aos dez bits relevantes. `keys` guarda o estado atual, enquanto `pressed = atual & ~anterior` guarda apenas novas pressões. A explicação do registrador está no [Tonc: keypad](https://gbadev.net/tonc/keys.html). O movimento usa `keys` para repetir passos; comprar usa `pressed` para não gastar várias vezes ao segurar A.

`wait_vblank` primeiro sai do intervalo atual e só então espera o seguinte. Essa ordem evita executar várias atualizações no mesmo intervalo. Não estamos usando interrupções; o programa consulta o registrador de contagem de linhas.

## 3. Inicializar um estado que possa ser reiniciado

Agora acrescente a preparação da partida:

<!-- code: learn/main.s#state -->
```asm
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
```
<!-- /code -->

As variáveis começam na seção BSS, definida ao fim do arquivo. A rotina zera o estado a partir de `game_state`, preservando o relógio e o histórico dos botões. Isso permite pressionar Start sem provocar reinícios repetidos enquanto ele estiver segurado.

A partida começa com 20 moedas e três pontos de vida. O herói aparece em `(1,6)`. `fill_rect`, que escreveremos adiante, preenche o fundo. Esse preenchimento completo ocorre somente no início e no reinício; durante a partida restauramos áreas menores.

`push` salva valores na pilha e `pop` os recupera. Como `new_game` chama outra rotina com `bl`, precisa preservar o próprio retorno. `r4` também é restaurado porque a função o usa para passar a cor.

## 4. Mover o herói por células

Acrescente a rotina de movimento:

<!-- code: learn/main.s#movement -->
```asm
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
```
<!-- /code -->

As direções são números: cima 0, direita 1, baixo 2 e esquerda 3. Um passo altera uma coordenada em uma célula. O contador bloqueia outros sete frames; no oitavo, outro passo pode começar.

Comparações sem sinal rejeitam tanto coordenadas grandes quanto `-1`, representado como um número sem sinal grande. Depois verificamos a base, a torre construída e a saída fechada. Não há busca de caminho para o herói: ele só precisa saber se a célula vizinha é permitida.

Direção + A atualiza a orientação sem iniciar um passo. Isso resolve uma interação concreta: apontar para o ponto amarelo e construir ao lado dele, sem caminhar para cima do ponto no mesmo instante.

## 5. Comprar uma torre sem duplicar a cobrança

Acrescente a construção:

<!-- code: learn/main.s#construction -->
```asm
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
```
<!-- /code -->

A ordem é importante: houve uma nova pressão? A torre já existe? A célula à frente é o ponto certo? Há pelo menos 20 moedas? Somente depois dessas verificações o saldo é debitado.

Aqui existe apenas uma posição e um tipo. `tower_built` substitui uma lista de estruturas. Isso é suficiente para aprender a regra. A campanha completa transforma o mesmo raciocínio em oito posições de torre por mapa.

## 6. Fazer uma onda chegar à base

Acrescente a onda e o movimento do inimigo:

<!-- code: learn/main.s#wave -->
```asm
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
```
<!-- /code -->

R inicia uma única onda de quatro inimigos. Eles entram **um por vez**, e o próximo aparece depois que o anterior morreu ou chegou à base. Com isso, bastam `enemy_x` e `enemy_hp`; não precisamos ainda de um vetor de inimigos ou algoritmo para escolher alvos.

Como a estrada é reta, o movimento é `x = x + 1`. Chegar a `216` remove o inimigo e retira um ponto de vida. A terceira chegada provoca derrota. Nenhuma moeda é concedida por inimigo que escapou.

Em um mapa com curvas, o próximo passo seria substituir esse destino fixo por uma lista de pontos `(x,y)`, avançando o índice a cada ponto alcançado. É isso que a campanha completa faz; o caminho não precisa de recalculação porque as torres estão fora dele.

## 7. Atacar, pagar a recompensa e liberar a saída

Acrescente o disparo e a condição de vitória:

<!-- code: learn/main.s#combat -->
```asm
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
```
<!-- /code -->

A distância até a torre é `abs(x_inimigo - 104) + 16`. O termo 16 representa a diferença vertical, constante nesta estrada. Esse é um alcance em losango. Dentro de 48 pixels, a torre causa um de dano e carrega a recarga.

O contador de 24 é decrementado nas atualizações seguintes; um novo tiro fica disponível na atualização posterior ao zero. Portanto, o intervalo entre tiros é 25 atualizações. O inimigo tem dois pontos de vida.

Só pagamos cinco moedas quando o dano transforma um inimigo vivo em morto. Como `enemy_hp == 0` retorna antes do ataque seguinte, ele não volta a render recompensa.

A saída depende de três condições: a onda começou, não há entradas restantes e o inimigo atual não está vivo. Ainda assim o jogo só termina quando o herói alcança `(12,6)`. Na campanha, essa mesma condição carrega o mapa seguinte.

## 8. Desenhar usando uma única operação

Acrescente as duas primitivas de desenho:

<!-- code: learn/main.s#pixels -->
```asm
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
```
<!-- /code -->

`fill_rect` recebe posição, tamanho e cor. O endereço é `VRAM + 2 * (y * 240 + x)`. `strh` escreve dois bytes por pixel. Ao terminar uma linha do retângulo, pulamos o restante da linha da tela. Essa rotina pressupõe retângulos de tamanho positivo e dentro da tela; todos os seus chamadores usam limites fixos ou coordenadas previamente verificadas.

`paint_cell` converte a célula em pixels com deslocamento à esquerda de quatro bits, equivalente a multiplicar por 16. Tanto o herói quanto torre, base e portal podem ser desenhados com essa função.

Agora componha a cena:

<!-- code: learn/main.s#drawing -->
```asm
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
```
<!-- /code -->

Essa é a parte visual completa do exemplo. Primeiro apagamos a antiga posição do herói e restauramos a estrada, removendo o desenho anterior do inimigo. Depois redesenhamos os elementos fixos e os atores atuais.

Vida e dinheiro usam quadrados em vez de números. Cada marca de dinheiro vale cinco moedas; marcas vazias ficam cinza. A barra inferior indica o resultado. O desenho permanece deliberadamente simples para que nenhum sistema de fonte ou sprite seja necessário para entender a partida.

## 9. Reservar as variáveis

Termine `main.s` com este bloco:

<!-- code: learn/main.s#variables -->
```asm
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
```
<!-- /code -->

Cada `.space 4` reserva uma palavra de 32 bits. Os três primeiros campos são relógio e botões; o restante pode ser limpo ao reiniciar. Nomes globais facilitam a inspeção pelos testes e pelo depurador. O arquivo inclui todas as rotinas do jogo, não apenas pseudocódigo.

## 10. Dizer onde o código e o estado ficam

Crie `gba.ld` com:

<!-- code: learn/gba.ld -->
```ld
OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)
MEMORY {
  ROM (rx) : ORIGIN = 0x08000000, LENGTH = 32M
  RAM (rw) : ORIGIN = 0x02000000, LENGTH = 256K
}
SECTIONS {
  .text : { KEEP(*(.header)) *(.text*) *(.rodata*) . = ALIGN(4); } > ROM
  .bss (NOLOAD) : {
    . = ALIGN(4); __bss_start = .; *(.bss*) *(COMMON)
    . = ALIGN(4); __bss_end = .;
  } > RAM
  /DISCARD/ : { *(.comment) *(.note*) }
}
ASSERT(SIZEOF(.bss) < 0x3F000, "Game state exceeds EWRAM")
```
<!-- /code -->

O linker coloca instruções e constantes no cartucho, a partir de `0x08000000`. A BSS fica na RAM externa em `0x02000000` e não precisa ocupar bytes no arquivo da ROM. A pilha foi posicionada na RAM interna pelo startup.

As regras de organização por seções pertencem ao [GNU ld](https://sourceware.org/binutils/docs/ld/Scripts.html). Aqui usamos somente o necessário para este programa; não há runtime C, heap ou biblioteca de jogo.

## 11. Preencher o cabeçalho do cartucho

Crie `rom.py` com a ferramenta abaixo. Ela preenche os bytes fixos do cabeçalho e seu checksum; não gera regras do jogo nem traduz Python para ARM.

<!-- code: tools/rom.py -->
```python
"""Fill the standard GBA cartridge header; no game code is generated here."""
import hashlib
from pathlib import Path
import sys

# Fixed cartridge identification bytes, specified by the GBA boot format.
LOGO = bytes.fromhex(
    '24ffae51699aa2213d84820a84e409ad11248b98c0817f21a352be199309ce20'
    '10464a4af82731ec58c7e83382e3cebf85f4df94ce4b09c194568ac01372a7fc'
    '9f844d73a3ca9a615897a327fc039876231dc7610304ae56bf38840040a70efd'
    'ff52fe036f9530f197fbc08560d68025a963be03014e38e2f9a234ffbb3e0344'
    '780090cb88113a9465c07c6387f03cafd625e48b380aac7221d4f807'
)


def validate(data):
    assert len(LOGO) == 156
    assert data[4:160] == LOGO, 'Invalid logo identification'
    assert data[0xB2] == 0x96, 'Invalid fixed header byte'
    assert (sum(data[0xA0:0xBE]) + 0x19) & 255 == 0, 'Invalid header checksum'
    assert data[3] == 0xEA, 'Entry must branch in ARM state'


def fix(filename):
    data = bytearray(Path(filename).read_bytes())
    assert len(data) >= 0xC0
    data[4:160] = LOGO
    data[0xA0:0xAC] = b'GATEBLADE   '
    data[0xAC:0xB0] = b'AGBE'
    data[0xB0:0xB2] = b'00'
    data[0xB2] = 0x96
    data[0xB3:0xBD] = bytes(10)
    data[0xBD] = (-sum(data[0xA0:0xBD]) - 0x19) & 255
    data[0xBE:0xC0] = bytes(2)
    data.extend(bytes((-len(data)) % 4))
    validate(data)
    Path(filename).write_bytes(data)
    print(f'{filename}: {len(data)} bytes; SHA-256 {hashlib.sha256(data).hexdigest()}')


if __name__ == '__main__':
    fix(sys.argv[1])
```
<!-- /code -->

A constante longa é a identificação fixa do formato de cartucho, separada da arte do jogo. O título ocupa 12 bytes. `fix` preenche os campos, calcula a soma exigida, valida e grava. A instrução de entrada que escrevemos no assembly permanece no começo.

Essa ferramenta é igual à usada no projeto completo. Você pode digitá-la ou usar a [cópia do repositório](../tools/rom.py); ela só depende da biblioteca padrão do Python.

## 12. Montar e abrir a primeira partida

Com os três arquivos na pasta vazia, execute:

```sh
arm-none-eabi-as -mcpu=arm7tdmi --defsym LESSON=4 -g -o main.o main.s
arm-none-eabi-ld -T gba.ld -o main.elf main.o
arm-none-eabi-objcopy -O binary main.elf meu-tower-defense.gba
python3 rom.py meu-tower-defense.gba
```

Abra `meu-tower-defense.gba` no mGBA. A construção termina em uma ROM de **2.112 bytes** nesta versão. O hash e o ambiente usados para verificar esse resultado estão nas [evidências didáticas](../docs/evidencias/2026-10-24-didatico/README.md).

Para experimentar as etapas menores, altere `LESSON=4` para `1`, `2` ou `3` no primeiro comando e repita os outros. A etapa 1 desenha a cena; a 2 acrescenta o herói; a 3 permite enviar inimigos, mas ainda não defender; a 4 fecha a partida.

Se clonou o repositório, os atalhos equivalentes são:

```sh
make learn STEP=1
make learn STEP=2
make learn STEP=3
make learn
```

As saídas ficam em `build/learn/step-1.gba` até `step-4.gba`. Esses comandos não geram assets nem constroem o emulador.

## 13. Conferir o resultado antes de aumentar o jogo

Na etapa 4, saia da célula `(1,6)`, caminhe cinco células para a direita e três para cima. Você estará em `(6,3)`, logo abaixo do ponto de construção. Use cima + A para virar e comprar a torre sem andar. As quatro marcas amarelas do saldo ficam cinza: as 20 moedas foram gastas.

Pressione R e espere os quatro inimigos. A torre deve eliminá-los, manter os três pontos de vida e devolver 20 moedas por eliminações. A saída fica verde. Caminhe seis células para a direita e três para baixo: ao chegar ao portal, a barra inferior fica verde. Start reinicia. Para testar derrota, inicie outra onda sem construir: a terceira chegada à base deixa a barra vermelha.

![Defesa pequena concluída: base intacta, moedas e saída verde](../docs/evidencias/2026-10-24-didatico/defended.png)

Os testes executaram as quatro ROMs no mGBA. A partida pequena foi concluída usando somente botões; também foi verificada a derrota sem torre e o reinício. O artigo ainda passou por uma prova específica: seus blocos foram reunidos em três arquivos em uma pasta temporária e produziram a mesma ROM, byte a byte.

Esse teste evita um problema comum em tutoriais: um trecho parecer correto, mas depender de funções ou arquivos que nunca foram mostrados. Ele não comprova operação em console físico nem substitui o aprendizado de depurar um registrador ou um acesso à memória.

## 14. Evoluir para algo próximo da campanha completa

Depois de entender a versão pequena, faça uma mudança por vez:

| Primeiro experimento | Evolução usada na campanha |
| --- | --- |
| Dois pontos de construção | Lista de oito torres, cada uma com posição, nível e recarga |
| Dois inimigos simultâneos | Vetor de doze slots e escolha de alvo mais adiantado |
| Uma curva na estrada | Lista de células e índice do próximo destino |
| Segunda fase | Tabela de dez mapas carregada ao atravessar o portal |
| Segunda torre | Campo de tipo e parâmetros de alcance, dano e efeito |
| Desenho mais elaborado | Mode 0, tiles e sprites, mantendo as regras separadas |

A campanha está em [src/main.s](../src/main.s), [src/game.s](../src/game.s) e [src/render.s](../src/render.s). Sua organização é explicada na [arquitetura](../docs/arquitetura-td.md). A primeira experiência com o Mode 3 serve para aprender as regras; migrar os gráficos exige aprender o hardware de tiles e sprites como outra etapa.

Os mapas completos também ficaram mais diretos de editar. Agora a rota e os oito pontos de construção são coordenadas escritas em `assets/stages.json`. A ferramenta valida os dados, mas não decide mais onde colocar as torres. Um exemplo real do primeiro mapa:

```json
{
  "name": "FIRST WATCH",
  "route": [[0, 3], [13, 3]],
  "waves": 1,
  "theme": "green",
  "pads": [[1, 2], [2, 4], [4, 2], [5, 4], [7, 2], [8, 4], [10, 2], [11, 4]]
}
```

A [decisão de simplificação](../docs/decisoes/0005-entrada-didatica.md) registra a escolha de preservar o jogo completo e oferecer uma entrada menor. A remoção da seleção automática de pontos produziu exatamente a mesma ROM da campanha anterior, conferida por SHA-256.

## Exercícios e próximos passos

Experimente reduzir o alcance de 48 para 32 e observar onde os inimigos escapam. Depois, mude o custo da torre e o saldo inicial juntos. Para criar uma curva, comece por duas coordenadas de destino e mantenha apenas um inimigo: assim você testa o movimento sem acrescentar ao mesmo tempo a complexidade de uma lista de atores.

Ao pedir apoio a uma IA, um pedido útil é: “explique o que esta rotina lê e escreve, preserve ARM7TDMI e proponha uma alteração pequena com um teste observável”. Confira a instrução, execute a ROM e registre o que aconteceu. Uma explicação plausível não substitui essa execução.

As [referências](../docs/referencias.md), o [diário da simplificação](../docs/diario/2026-10-24-didatico.md) e as evidências ficam junto do código. A campanha de dez mapas continua com seus testes e sua demonstração. O artigo anterior foi preservado como [relato da versão 0.2.0](artigo-v0.2.0.md). A licença de reutilização do projeto permanece pendente de definição pelo mantenedor.
