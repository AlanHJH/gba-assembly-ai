# Gateblade — GBA em assembly com IA

Um jogo curto de ação para **Game Boy Advance**, desenvolvido em assembly ARM7TDMI com apoio de IA e documentado para um artigo no blog de Alan Henrique Jahnel.

Você é um herói com espada. Derrote todos os inimigos da sala, atravesse a saída liberada e continue até o Guardião. A campanha tem três salas de inimigos comuns e uma sala de chefe, com vida, pausa, derrota, reinício e vitória.

**Estado:** primeira versão jogável, construída e testada no mGBA 0.10.5. Ainda sem teste em console físico.

![Demonstração capturada da ROM real](docs/evidencias/2026-10-23/gateblade-demo.gif)

## Jogar

Baixe a ROM `.gba` na [página de releases](https://github.com/AlanHJH/gba-assembly-ai/releases) e abra no mGBA. O [guia do jogo](docs/como-jogar.md) explica as salas e a estratégia contra o chefe.

| Ação | GBA | mGBA SDL preparado pelo projeto |
| --- | --- | --- |
| Movimento e direção | Direcional | Setas |
| Espada | A | X |
| Iniciar ou reiniciar | Start ou A | Enter ou X |
| Pausa | Start | Enter |

## Construir e verificar

Com GNU Binutils para `arm-none-eabi`, Python, Make, CMake, pkg-config e SDL2 disponíveis:

```sh
make
make emulator
make verify
make play
```

O [guia de reprodução](docs/reproducao.md) explica dependências, versões, comandos e saídas. A ROM é `build/gateblade.gba`. `make emulator` constrói o mGBA localmente a partir de um arquivo oficial com hash conferido; não o instala globalmente.

`make demo` regrava uma campanha com entradas de controle e gera MP4/GIF, usando FFmpeg. `make package` verifica e prepara ROM, SHA-256 e uma cópia do artigo com links públicos em `dist/`.

## Artigo e documentação

| Documento | Conteúdo |
| --- | --- |
| [Artigo em português](article/artigo.md) | Relato para revisão e publicação no blog |
| [Como jogar](docs/como-jogar.md) | Regras, controles, inimigos, saída e chefe |
| [Reprodução](docs/reproducao.md) | Construção, testes, emulador e demonstração |
| [Evidências da versão](docs/evidencias/2026-10-23/README.md) | Resultados, capturas e identificação da ROM |
| [Diário de implementação](docs/diario/2026-10-23-implementacao.md) | Alterações, comandos, falhas e correções |
| [Escopo inicial](docs/decisoes/0001-escopo-e-metodo.md) | Requisito de assembly e método documental |
| [Decisão do jogo](docs/decisoes/0002-gateblade-e-combate.md) | Regras e valores escolhidos |
| [Decisão técnica](docs/decisoes/0003-ferramentas-e-validacao.md) | Toolchain, gráficos e verificação |
| [Plano e próximos passos](docs/plano.md) | Entregas e melhorias pendentes |
| [Referências](docs/referencias.md) | Fontes técnicas consultadas |

## Organização

`src/` contém startup, lógica e renderização em assembly, além do linker script. `tools/` contém geração de recursos, preparação de cabeçalho e testes no computador. `assets/` documenta o formato dos recursos originais. `docs/` preserva o desenvolvimento e as evidências. `article/` mantém o texto editorial.

O jogo não usa C/C++, engine, libgba ou runtime C dentro da ROM. Python e o código do emulador são ferramentas do computador. Os cenários isolados de teste preparam estado em RAM; a campanha completa e a demonstração usam somente botões, sem alterar vida ou pular salas.

## Compartilhamento e limites

Repositório público: [AlanHJH/gba-assembly-ai](https://github.com/AlanHJH/gba-assembly-ai). A publicação do texto no site pessoal é uma etapa editorial separada. A licença de reutilização do código e da documentação ainda será definida pelo mantenedor.

Esta versão tem quatro salas fixas. Não inclui salvamento, inventário, música ou geração procedural. Não há comparação medida de produtividade com e sem IA. O uso da IA, as correções e os resultados observados estão documentados sem transformar propostas em funcionalidades entregues.
