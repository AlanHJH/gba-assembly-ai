# Comece por este jogo pequeno

Um arquivo assembly, um linker script e uma ferramenta de cabeçalho. Um mapa, uma torre e quatro inimigos que entram um por vez. Os gráficos são retângulos em Mode 3; não há assets, fonte, sprites ou geração de mapas para entender antes de jogar.

## Preparar

Para construir, instale GNU Binutils para `arm-none-eabi`, Python 3 e Make. Para abrir a ROM, use uma instalação pronta do [mGBA](https://mgba.io/downloads.html). A construção do emulador pelo projeto é opcional, usada nos testes automatizados.

Na raiz do repositório:

```sh
make learn STEP=1
make learn STEP=2
make learn STEP=3
make learn
```

| Etapa | Arquivo para abrir no mGBA | Resultado esperado |
| --- | --- | --- |
| 1 | `build/learn/step-1.gba` | Estrada, base, ponto e saída |
| 2 | `build/learn/step-2.gba` | Herói branco movido pelo direcional |
| 3 | `build/learn/step-3.gba` | R envia quatro inimigos, um de cada vez; sem defesa |
| 4 | `build/learn/step-4.gba` | A constrói; defender e caminhar até a saída vence |

Todas usam [main.s](main.s). `.if LESSON` ativa as partes correspondentes na montagem. Sem parâmetro, o arquivo também usa a etapa 4. A forma de montar sem Make e o conteúdo integral dos três arquivos estão no [tutorial manual](../article/artigo.md).

## Jogar a etapa 4

O quadrado branco começa em `(1,6)`. Ande cinco células para a direita e três para cima; ficará abaixo do ponto amarelo. Pressione cima + A para construir sem andar. A torre custa as 20 moedas iniciais. R inicia a onda; a torre elimina quatro inimigos e rende cinco moedas por eliminação. Depois caminhe seis células à direita e três para baixo para alcançar o portal verde.

Direcional move, A constrói, R inicia, Start reinicia. No frontend SDL padrão do projeto: setas, X, S e Enter. A barra inferior fica verde na vitória e vermelha na derrota. Cada marca amarela no alto representa cinco moedas; as três marcas vermelhas representam a base.

Não há texto, áudio, pausa, espada, melhorias ou animação suave nesta versão de aprendizado. A campanha completa mantém esses sistemas e dez mapas. O propósito aqui é entender cada regra antes de adicionar outras.

## Ler e experimentar

Leia primeiro `boot`, `main_loop` e `read_keys`; depois `move_hero`, `build_tower`, `update_wave`, `fire_tower` e `check_exit`. Por último, veja `fill_rect` e `draw_scene`. Os comentários explicam os registradores e as hipóteses das rotinas. O artigo apresenta todos os blocos na ordem necessária para criar o arquivo.

Experimentos pequenos: reduzir o alcance, mudar custo e saldo juntos ou criar um segundo destino para o inimigo. Execute uma mudança por vez. Quando introduzir dano variável, trate dano maior que a vida restante, como faz a campanha completa.

Para verificar as quatro etapas e reconstruir o jogo a partir dos blocos do artigo, depois de preparar o emulador com `make emulator`:

```sh
make test-learn
make snippets
```

O primeiro comando executa as ROMs e uma partida por controle, sem escrita de estado. Também monta os blocos do artigo em uma pasta vazia e compara a ROM byte a byte. O segundo confere a sincronização dos trechos com o código-fonte. [Evidências](../docs/evidencias/2026-10-24-didatico/README.md). Hardware físico ainda não testado.
