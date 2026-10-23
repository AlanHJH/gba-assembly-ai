# Referências técnicas

Consultadas em 23 de outubro de 2026. Os links abaixo sustentam a pesquisa inicial; não representam ferramentas já instaladas nem procedimentos já reproduzidos.

| Fonte | Uso no projeto | Limite nesta etapa |
| --- | --- | --- |
| [Arm — introdução às arquiteturas](https://developer.arm.com/community/arm-community-blogs/b/architectures-and-processors-blog/posts/arm-fundamentals-introduction-to-understanding-arm-processors) | Relacionar ARM7TDMI à arquitetura Armv4T | Não substitui o manual de instruções para cada rotina |
| [Tonc — hardware do GBA](https://gbadev.net/tonc/hardware.html) | Identificar CPU, vídeo e organização geral do console | Referência técnica comunitária, não documentação oficial da Nintendo |
| [Tonc — ARM assembly](https://gbadev.net/tonc/asm.html) | Estudar assembly ARM/Thumb e o assembler GNU | Trechos de interoperabilidade com C não definem a implementação deste projeto |
| [Tonc — primeira demonstração](https://gbadev.net/tonc/first.html) | Entender a sequência de construção até a ROM e um experimento gráfico pequeno | O exemplo usa C; não foi adotado como código do jogo |
| [GNU Binutils — opções ARM do assembler](https://sourceware.org/binutils/docs/as/ARM-Options.html) | Conferir seleção de CPU e restrição de instruções | A versão a instalar ainda não foi escolhida |
| [devkitPro — buildscripts](https://github.com/devkitPro/buildscripts) | Identificar o projeto que mantém scripts de construção das toolchains | Não foi executado nem adotado como procedimento de instalação |
| [devkitPro — gba-tools](https://github.com/devkitPro/gba-tools) | Investigar utilitários auxiliares para GBA | Nenhum utilitário foi incorporado nesta etapa |
| [mGBA — downloads oficiais](https://mgba.io/downloads.html) | Confirmar a disponibilidade de distribuição para macOS | Nenhuma versão foi instalada ou executada neste projeto |

## Consulta que não pôde ser concluída

As páginas [Getting Started](https://devkitpro.org/wiki/Getting_Started) e [devkitPro pacman](https://devkitpro.org/wiki/devkitPro_pacman) retornaram HTTP 403 na ferramenta de pesquisa. Ficam como pontos de investigação, sem afirmar que suas instruções foram lidas ou testadas.

## Como ampliar esta lista

Ao usar um fato novo, registrar a fonte correspondente e o contexto. Ao usar código de terceiros, registrar também a origem e as condições de reutilização. Para instruções, registradores e formatos de ROM, conferir o detalhe pertinente antes de transformar uma sugestão em implementação.

## Fontes usadas na implementação

Consultadas na mesma data:

- [Homebrew: arm-none-eabi-binutils](https://formulae.brew.sh/formula/arm-none-eabi-binutils) — distribuição dos utilitários; a versão realmente instalada foi 2.44.
- [GNU ld: linker scripts](https://sourceware.org/binutils/docs/ld/Scripts.html) e [objcopy](https://sourceware.org/binutils/docs/binutils/objcopy.html) — disposição de seções e conversão do ELF.
- [Tonc: backgrounds](https://gbadev.net/tonc/regbg.html), [sprites](https://gbadev.net/tonc/regobj.html), [vídeo](https://gbadev.net/tonc/video.html), [controles](https://gbadev.net/tonc/keys.html) e [DMA](https://gbadev.net/tonc/dma.html) — configuração gráfica, sincronização e entrada.
- [mGBA 0.10.5: código de carregamento](https://github.com/mgba-emu/mgba/blob/0.10.5/src/gba/gba.c) — investigação de detecção de multiboot.
- [mGBA 0.10.5: CMake](https://github.com/mgba-emu/mgba/blob/0.10.5/CMakeLists.txt), [version.cmake](https://github.com/mgba-emu/mgba/blob/0.10.5/version.cmake) e [libretro.h](https://github.com/mgba-emu/mgba/blob/0.10.5/src/platform/libretro/libretro.h) — configuração da construção e interface do frontend de testes; esses arquivos também foram lidos da distribuição verificada.

As fontes do mGBA são dependência de desenvolvimento e preservam a licença própria upstream. Não foram incorporadas como código executável da ROM nem adicionadas ao histórico Git deste projeto.
