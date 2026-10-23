# 0003 — Ferramentas, gráficos e validação da ROM

**Data:** 23 de outubro de 2026.

**Estado:** adotada; construção e execução verificadas localmente.

## Toolchain e código executável

Usar GNU Binutils para `arm-none-eabi`, sem compilar código C do jogo. `as` monta ARM7TDMI, `ld` aplica o script de memória e `objcopy` gera o binário. O startup, a lógica e a renderização estão em assembly. Python executa tarefas de preparação e teste no computador.

devkitARM continua sendo uma alternativa possível. Para este recorte, os utilitários Binutils já cobrem as etapas necessárias, sem introduzir runtime C ou cabeçalhos de libgba. A seleção da CPU pelo assembler também restringe instruções inadequadas ao alvo.

## Organização e gráficos

Usar modo 0, um background de tiles 4bpp e objetos de hardware para herói, inimigos e espada. O mapa usa screenblock 31; sprites usam mapeamento 1D. Um script gera os recursos visuais originais, paletas e letras, dispensando downloads de imagens ou fontes.

As primeiras notas mencionavam um bitmap como experimento possível, não como decisão adotada. Tiles e sprites foram escolhidos já para o jogo pedido, permitindo mover os personagens sem redesenhar uma tela inteira em pixels.

O loop consulta `VCOUNT` e faz uma atualização por novo VBlank. As interrupções permanecem desativadas; não há chamadas da BIOS nem runtime externo. DMA3 carrega tiles e paletas durante a inicialização. A renderização posterior atualiza o mapa e a OAM conforme as rotinas do projeto.

## Emulador e testes

Construir o mGBA 0.10.5 de um arquivo oficial com hash conferido. Usar seu frontend SDL para execução interativa e seu núcleo libretro para executar testes determinísticos e capturar quadros da mesma ROM.

O frontend de teste em Python implementa a interface libretro. Usa o mapa de memória fornecido pelo emulador para ler símbolos do ELF. Cenários isolados podem preparar estado em EWRAM; o teste da campanha completa fornece somente botões. A demonstração usa esse mesmo percurso, sem modificar vida, inimigos ou progressão.

## Problemas encontrados e correções

1. O assembler rejeitou a expressão de diferença de símbolos usada diretamente em `ldr =...` e uma máscara imediata incompatível com a codificação ARM. As quantidades de DMA passaram a usar dois endereços e subtração; as coordenadas dos objetos passaram a ser limitadas por deslocamentos de bits.
2. O frontend SDL falhou na linkedição ao detectar libepoxy enquanto os renderizadores OpenGL estavam desativados. `USE_EPOXY=OFF` alinhou a seleção ao caminho de software. O código de terceiros não foi modificado.
3. O mGBA inicialmente classificou a ROM pequena como multiboot e a iniciou em EWRAM. A limpeza de `.bss` apagava o próprio programa carregado ali. Foi inspecionado `GBAIsMB` no código do emulador; a posição `0xC0` recebeu um desvio de volta à entrada de cartucho. O ponto de entrada principal continua no endereço de ROM. A ROM é para cartucho, não para multiboot. O teste conserva essa condição como regressão.
4. Uma tentativa com desvio de +24 em `0xC0` ainda acionou a análise heurística de referências de memória do mGBA; não resolveu o problema. O desvio para trás adotado foi então validado por execução e pela presença do contador de quadros em andamento.
5. A identificação de versão do mGBA extraído herdou o Git do projeto pai. `SKIP_GIT` e um limite de busca de repositório impediram essa identificação incorreta; o executável passou a informar 0.10.5.
6. A primeira estratégia do controlador automatizado andava para dentro do chefe e morreu. O controlador foi corrigido para atacar à distância e recuar durante a preparação e a investida. A campanha posterior terminou com dois corações.
7. Na revisão final, a condição de derrota tratava vida exatamente zero, mas não dano que passasse abaixo de zero antes de ser limitado. Um herói com um coração atingido pelo chefe poderia ficar com zero sem morrer. A condição foi corrigida para menor ou igual a zero, e um cenário específico de dano excedente foi acrescentado ao teste de derrota.

## Fontes

[GNU assembler](https://sourceware.org/binutils/docs/as/ARM-Options.html), [GNU ld](https://sourceware.org/binutils/docs/ld/Scripts.html), [objcopy](https://sourceware.org/binutils/docs/binutils/objcopy.html), [Tonc: backgrounds](https://gbadev.net/tonc/regbg.html), [Tonc: sprites](https://gbadev.net/tonc/regobj.html), [Tonc: vídeo](https://gbadev.net/tonc/video.html), [Tonc: teclas](https://gbadev.net/tonc/keys.html), [Tonc: DMA](https://gbadev.net/tonc/dma.html) e [mGBA 0.10.5: origem e detecção de ROM](https://github.com/mgba-emu/mgba/blob/0.10.5/src/gba/gba.c). Consultadas em 23 de outubro de 2026.

## Limites

O emulador e suas bibliotecas são ferramentas externas; não estão embutidos no jogo. Não há medição comparativa de produtividade da IA, certificação de compatibilidade ou teste em console físico. A licença de reutilização do projeto ainda depende de definição do mantenedor.
