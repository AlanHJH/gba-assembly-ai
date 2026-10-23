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
