# Gateblade TD — GBA em assembly com IA

Um tower defense para **Game Boy Advance**, com herói controlável, dez mapas originais e código executável próprio em assembly ARM7TDMI. O processo foi documentado em português para um artigo no blog de Alan Henrique Jahnel.

Caminhe pelo mapa, construa torres nos pontos dourados **ao lado da rota**, defenda a base azul e ganhe moedas derrotando Brumins. Novas torres são liberadas ao longo da campanha. Quando todas as ondas terminarem, caminhe até o portal para seguir à próxima fase.

**Versão 0.3.0:** entrada didática em quatro etapas e campanha preservada, executada no mGBA 0.10.5; testes de hardware físico continuam pendentes. A [v0.1.0](https://github.com/AlanHJH/gba-assembly-ai/releases/tag/v0.1.0), de combate por salas, permanece disponível.

![Trechos da campanha real, com cortes e sem áudio](docs/evidencias/2026-10-24/gateblade-demo.gif)

## Começar do zero

A entrada recomendada é o [tutorial manual](article/artigo.md). Ele apresenta todo o código para criar um jogo menor em três arquivos: assembly, linker e cabeçalho. São quatro etapas executáveis, sem assets ou gerador de mapas:

```sh
make learn STEP=1
make learn STEP=2
make learn STEP=3
make learn
```

Abra `build/learn/step-1.gba` até `step-4.gba` no mGBA. Para construir, bastam Binutils ARM, Python e Make; uma instalação pronta do emulador é suficiente para jogar. O [guia didático](learn/README.md) detalha controles e resultados esperados. O tutorial também mostra como montar os mesmos três arquivos em uma pasta vazia, sem Make.

A etapa final tem um mapa, uma torre, uma onda e vitória/derrota. Depois disso, estude a campanha de dez mapas abaixo. `make verify` testa os dois caminhos e exige que os snippets do artigo produzam a mesma ROM do exemplo.

## Jogar

Baixe a ROM na [release v0.2.0](https://github.com/AlanHJH/gba-assembly-ai/releases/tag/v0.2.0) e abra no mGBA. O [guia](docs/como-jogar.md) explica a economia, as torres, as fases e a estratégia.

| Ação | GBA | mGBA SDL preparado pelo projeto |
| --- | --- | --- |
| Andar um tile / virar | Direcional | Setas |
| Construir / melhorar ponto à frente | A | X |
| Virar e construir sem andar | Direcional + A | Seta + X |
| Espada | B | Z |
| Alternar tipo disponível | L | A do teclado |
| Enviar próxima onda | R | S do teclado |
| Iniciar / reiniciar | Start ou A | Enter ou X |
| Pausar / retomar | Start | Enter |

Comece com três BOLT de 20 moedas. A fase 1 funciona como tutorial. FROST é liberada na fase 3 e BLAST na fase 6. Cada torre admite uma melhoria por 20 moedas. Prepare-se antes de apertar R: as ondas começam por decisão do jogador.

## Construir e verificar

Com GNU Binutils para `arm-none-eabi`, Python, Make, CMake, pkg-config e SDL2 disponíveis:

```sh
make
make emulator
make verify
make play
```

O [guia de reprodução](docs/reproducao.md) detalha ferramentas, versões e saídas. `make emulator` constrói localmente o mGBA a partir do arquivo oficial com hash conferido. `make demo` gera trechos MP4/GIF da campanha real; requer FFmpeg. `make package` prepara a ROM, checksum e artigo com links públicos em `dist/`.

## Documentação

| Documento | Conteúdo |
| --- | --- |
| [Tutorial manual](article/artigo.md) | Código completo comentado, em quatro etapas |
| [Guia didático](learn/README.md) | Primeiro jogo, dependências mínimas e controles |
| [Evidências do tutorial](docs/evidencias/2026-10-24-didatico/README.md) | Quatro ROMs e reconstrução pelos snippets |
| [Artigo 0.2.0](article/artigo-v0.2.0.md) | Relato da campanha antes da entrada didática |
| [Guia do jogo](docs/como-jogar.md) | Controles, tutorial, dez mapas e regras completas |
| [Arquitetura da defesa](docs/arquitetura-td.md) | Estruturas, algoritmos e valores do assembly |
| [Reprodução](docs/reproducao.md) | Construção, testes e demonstração |
| [Evidências 0.2.0](docs/evidencias/2026-10-24/README.md) | Relatório, capturas e hash da ROM |
| [Diário da evolução](docs/diario/2026-10-24-tower-defense.md) | Pedidos, decisões, comandos, falhas e validação |
| [Decisão 0004](docs/decisoes/0004-campanha-tower-defense.md) | Nova campanha, torres fora da rota e economia |
| [Plano](docs/plano.md) | Entregas e próximos passos |
| [Referências](docs/referencias.md) | Fontes técnicas |
| [Artigo da primeira versão](article/artigo-v0.1.0.md) | Histórico do jogo anterior, de quatro salas |
| [Evidências 0.1.0](docs/evidencias/2026-10-23/README.md) | Validação preservada da versão anterior |

## Organização e limites

`src/` contém startup, lógica e renderização em assembly e o linker script. `assets/stages.json` descreve os mapas; `tools/maps.py` valida e converte esses dados. `tools/assets.py` cria os gráficos originais. As ferramentas Python e o emulador executam no computador; a ROM não usa engine, libgba, C/C++ ou runtime C.

Os cenários isolados preparam condições na RAM do emulador. A campanha completa e a demonstração usam somente botões, sem conceder moedas ou pular mapas. Quinze grupos verificam a ROM real, incluindo a campanha de vinte ondas.

O jogo é um protótipo linear, sem salvamento, mundo aberto, venda individual de torres ou música. O balanceamento inicial foi verificado por uma estratégia automatizada e precisa de testes com pessoas. Não foi medida produtividade com e sem IA. A licença de reutilização ainda será definida pelo mantenedor.

Repositório público: [AlanHJH/gba-assembly-ai](https://github.com/AlanHJH/gba-assembly-ai). O artigo continua separado do site pessoal; publicá-lo no blog é uma etapa editorial posterior.
