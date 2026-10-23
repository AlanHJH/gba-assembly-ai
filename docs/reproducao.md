# Construção, testes e demonstração

## Ambiente validado

O desenvolvimento local usou macOS 15.6 em arm64, GNU Binutils para `arm-none-eabi` 2.44, Python 3.13.3, GNU Make 3.81, CMake 4.0.1 e SDL2 2.32.4. O mGBA 0.10.5 foi construído de uma distribuição oficial cujo SHA-256 é conferido pelo script.

As bibliotecas Python usadas pelas ferramentas do projeto pertencem à biblioteca padrão. O código executável do jogo é assembly ARM; Python, Make e o código C do emulador rodam no computador.

## Dependências no macOS

São necessários os comandos `arm-none-eabi-as`, `arm-none-eabi-ld`, `arm-none-eabi-objcopy`, `arm-none-eabi-nm`, `python3`, `make`, `cmake`, `pkg-config`, `curl` e SDL2. Para quem usa Homebrew:

```sh
HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew install arm-none-eabi-binutils cmake pkg-config sdl2
```

Neste computador, CMake, SDL2 e as ferramentas básicas já estavam presentes; a instalação adicional executada foi `brew install arm-none-eabi-binutils`. A fórmula disponível na sessão instalou Binutils 2.44. A versão obtida em outra data pode ser diferente. O primeiro comando executado não desativou o cleanup automático do Homebrew, que também limpou caches antigos; o exemplo acima desativa essa manutenção incidental.

## Construir a ROM

Na raiz do repositório:

```sh
make
```

O processo gera gráficos e paletas em `build/assets/`, monta `src/main.s`, faz a linkedição com `src/gba.ld`, converte o ELF em binário e preenche o cabeçalho de cartucho. A saída jogável é `build/gateblade.gba`; o ELF e o mapa de símbolos ficam ao lado para inspeção.

Os comandos centrais usados pelo Make são:

```sh
arm-none-eabi-as -mcpu=arm7tdmi -g -o build/gateblade.o src/main.s
arm-none-eabi-ld -T src/gba.ld -Map=build/gateblade.map -o build/gateblade.elf build/gateblade.o
arm-none-eabi-objcopy -O binary build/gateblade.elf build/gateblade.gba
python3 tools/rom.py build/gateblade.gba
```

Não é necessário instalar GCC, libgba ou um runtime C para construir esta ROM.

## Preparar o emulador local

```sh
make emulator
```

`tools/setup_emulator.sh` baixa o arquivo oficial do mGBA 0.10.5, confere seu hash e constrói dois componentes em `build/emulator/`: o programa SDL para jogar e o núcleo libretro para testes sem janela. Não instala o emulador globalmente. O download é reutilizado nas execuções seguintes.

O SHA-256 esperado do arquivo de origem é:

```text
91d6fbd32abcbdf030d58d3f562de25ebbc9d56040d513ff8e5c19bee9dacf14
```

Foram necessárias duas escolhas concretas de configuração: desativar `USE_EPOXY` para o frontend SDL sem OpenGL e impedir que a versão do emulador herdasse os metadados Git do repositório do jogo. A [decisão 0003](decisoes/0003-ferramentas-e-validacao.md) explica as correções.

## Jogar

```sh
make play
```

O executável fica em `build/emulator/sdl/mgba`. Use setas, X e Enter, conforme o [guia do jogo](como-jogar.md). Também é possível abrir a ROM em uma instalação separada do mGBA. Os testes registrados não dependem de fornecer um arquivo externo de BIOS ao emulador.

## Validar a ROM e a documentação

```sh
make verify
```

O teste carrega a ROM no mGBA, verifica o cabeçalho, o início do programa, movimento, portas, pausa, espada, dano, invulnerabilidade, derrota, reinício, fases do chefe e uma campanha completa. A revisão de Markdown confere links locais e caminhos pessoais.

Os cenários focados preparam posições e condições em EWRAM para isolar regras. A campanha completa usa apenas botões do controle, sem escrever na memória. Essa distinção é parte do teste, não uma afirmação de que todos os cenários são partidas humanas.

Saídas ficam em `build/test-results/`. O relatório principal é `report.json`. Os resultados selecionados da primeira versão estão em [evidências](evidencias/2026-10-23/README.md).

## Regravar a demonstração

Com FFmpeg disponível:

```sh
make demo
```

São gerados um registro de entradas, capturas PNG, um MP4 e um GIF. A captura seleciona um quadro a cada seis quadros emulados; a codificação preserva aproximadamente a duração do jogo. O MP4 é ampliado para 720 × 480 e o GIF para 480 × 320, com pixels preservados. Os arquivos de demonstração não incluem áudio.

## Preparar uma distribuição

```sh
make package
```

Depois de passar nos testes, a ROM e seu SHA-256 são copiados para `dist/`. Também é exportado `dist/gateblade-artigo.md`, com os links e a imagem apontando para a versão pública no GitHub, para que o texto não dependa da estrutura local de pastas ao ser copiado para um blog. O comando não publica nada por si só. A publicação de uma release usa esses artefatos, evitando reconstruir uma ROM diferente depois da validação.

`make clean` remove os resultados do jogo e dos testes, preservando a origem baixada e a construção do emulador. Saídas em `build/` e `dist/` não são versionadas; as evidências selecionadas em `docs/evidencias/` são.

## Integração contínua

O workflow `.github/workflows/check.yml` prepara Binutils no Ubuntu 24.04, constrói o mGBA sem janela usando `MGBA_BUILD_SDL=OFF make emulator` e executa `make verify`. O job usa o núcleo libretro e dispensa as dependências de interface gráfica; a construção local padrão continua incluindo SDL para jogar. O estado de cada execução pode ser consultado em [GitHub Actions](https://github.com/AlanHJH/gba-assembly-ai/actions). A existência do workflow, por si só, não comprova que uma execução remota passou; o diário registra o resultado observado.
