# 23 de outubro de 2026 — Da ideia à primeira campanha

## Objetivo e requisito recebido

Alan pediu que o jogo fosse efetivamente desenvolvido: herói com espada, inimigos que recebem dano, salas com entrada e saída, bloqueio da saída até eliminar todos e progressão até um chefe mais difícil. Reforçou que todo o processo deveria ficar descrito em Markdown, como base para publicação no blog, com explicação e demonstração do funcionamento.

O pedido substituiu a etapa anterior de apenas preparar a fundação. O projeto manteve o alvo Game Boy Advance e a exigência de assembly puro definidos na [decisão inicial](../decisoes/0001-escopo-e-metodo.md).

## Decisões adotadas

- [0002 — Regras de Gateblade](../decisoes/0002-gateblade-e-combate.md): quatro salas, espada direcional, vida, cura entre salas, portas e chefe com estados.
- [0003 — Ferramentas e validação](../decisoes/0003-ferramentas-e-validacao.md): Binutils, tiles/sprites, mGBA, testes e correções.

Os números de vida, duração dos ataques, nome e quantidade de salas foram escolhas de implementação a partir do ciclo solicitado. Não foram atribuídos ao usuário como requisitos numéricos.

## Implementação

Foram adicionados o Makefile, linker script, constantes e três arquivos de assembly para startup, lógica e renderização. O estado próprio usa 260 bytes em `.bss`; essa contagem exclui pilha, memória de vídeo e outras áreas do console.

O gerador de recursos em Python define tiles, paletas, letras e sprites originais. Outro script prepara e valida o cabeçalho da ROM. As ferramentas de teste constroem o mGBA e controlam a execução real da ROM por libretro. Não foi incluído código C/C++, engine ou runtime C no jogo.

Foram implementados título, partida, pausa, derrota, vitória e reinício, seis corações, espada com intervalo e identificação de golpe, inimigos perseguidores, saída bloqueada, cura entre salas, chefe com preparação/investida/recuperação e efeitos PSG.

## Participação da IA

A IA organizou o plano, pesquisou fontes, gerou código e recursos, executou a construção e os testes, corrigiu problemas e redigiu a documentação. As validações descritas são resultados dos comandos e do emulador, não uma estimativa de correção baseada só no texto gerado. Não foi feita comparação de produtividade com desenvolvimento sem IA.

O usuário definiu o conceito e reforçou a entrega do jogo, dos arquivos `.md` e da demonstração. A implementação não foi delegada a subagentes.

## Comandos executados

Na raiz do projeto, as etapas incluíram:

```sh
HOMEBREW_NO_AUTO_UPDATE=1 brew info --json=v2 arm-none-eabi-binutils mgba
HOMEBREW_NO_AUTO_UPDATE=1 brew install arm-none-eabi-binutils
sh tools/setup_emulator.sh
make all
python3 tools/emulator.py
make test
python3 tools/playthrough.py
build/emulator/sdl/mgba --version
arm-none-eabi-size build/gateblade.elf
```

A fórmula instalada foi Binutils 2.44. O Homebrew também realizou seu cleanup automático de caches antigos; o guia público apresenta a opção de desativá-lo em instalações futuras. A construção do emulador usou CMake 4.0.1 e SDL2 2.32.4. A implementação foi executada com Python 3.13.3; o levantamento da fundação havia registrado Python 3.11.5 em uma sessão anterior.

As primeiras codificações da demonstração foram executadas diretamente com FFmpeg; os mesmos argumentos passaram a fazer parte de `tools/demo.sh`, acionado por `make demo`. O registro de entradas está preservado com as evidências.

## Falhas e correções

1. A montagem recusou duas expressões de tamanho em instruções `ldr` e uma máscara imediata. Foram substituídas por operações compatíveis; a montagem seguinte passou.
2. O mGBA SDL não completou a linkedição por uma combinação de detecção de libepoxy e renderizadores desativados. Foi ajustada a configuração para o caminho de software, sem editar o emulador.
3. A primeira ROM montada ficou em tela vazia. O contador de quadros permaneceu zerado. A inspeção de registradores e mapas de memória mostrou início como multiboot em EWRAM, onde a limpeza de `.bss` apagava o programa.
4. Foi consultada a detecção `GBAIsMB`. Uma tentativa de desvio de +24 em `0xC0` não resolveu. Um desvio para trás, à entrada de cartucho, resolveu a classificação e foi protegido por teste.
5. A identificação de versão do mGBA herdou o Git do repositório pai. A configuração foi corrigida; o executável passou a informar 0.10.5.
6. A primeira estratégia automatizada de campanha morreu no chefe, após derrotar os nove inimigos comuns. A estratégia foi corrigida para manter distância e recuar nos estados de preparação e investida. O chefe manteve dezesseis pontos de vida e dano de dois corações.
7. Foi tentada a inspeção da janela SDL por automação nativa. O executável sem bundle não foi reconhecido pela ferramenta de seleção de aplicativos. Não se afirma uma validação manual de teclado por essa interface. A campanha e as capturas foram verificadas pelo frontend libretro executando a ROM; os atalhos SDL foram conferidos no código do frontend.
8. A revisão final identificou um caso de dano excedente do chefe: de um coração para zero, a transição de derrota não era chamada porque o valor anterior ao limite era negativo. A condição passou de igualdade para menor ou igual, e o cenário foi adicionado ao teste de derrota. A ROM e a demonstração foram reconstruídas após essa correção.

Os detalhes técnicos, alternativas e fontes estão na decisão 0003. Pequenos ajustes de caminho do executável SDL, versão e contagem de quadros da demonstração foram agrupados nesta sessão.

## Verificação local

Nove grupos de teste passaram, incluindo uma campanha sem escrita no estado do jogo. A campanha chegou às quatro salas, derrotou dez adversários e terminou com dois corações. O teste também reinicia uma nova campanha depois da vitória.

O percurso usa 1.484 quadros até a vitória, incluindo a apresentação inicial. A demonstração inclui mais 120 quadros da tela final e seleciona um quadro de vídeo a cada seis quadros emulados. MP4 e GIF foram codificados sem áudio.

A ROM validada tem 14.456 bytes e SHA-256 `567a13b74c0e0bcf0d8a302558569ecc7e686567986070467ee6d2480f7a0216`. Relatório, entradas e capturas estão em [evidências](../evidencias/2026-10-23/README.md).

Foi executada uma construção limpa, seguida dos testes, revisão de links e empacotamento. O hash foi reproduzido na reconstrução. Depois da correção final de dano, os testes e a captura foram repetidos para a nova ROM. Também foi adicionada uma exportação do artigo com 22 links HTTPS públicos, independentes de caminhos locais. O resultado remoto e a release foram registrados abaixo após a execução.

## Resultado remoto e distribuição

A primeira execução de CI foi substituída antes de concluir, depois da correção de dano excedente. O job passou a construir somente o núcleo necessário aos testes, usando `MGBA_BUILD_SDL=OFF`, dispensando dependências gráficas na máquina Linux.

A [execução 39986568714](https://github.com/AlanHJH/gba-assembly-ai/actions/runs/39986568714), no commit `ab5a52135655af7227f13ac29f5078212cd0907e`, terminou com sucesso no Ubuntu 24.04. O log confirmou o mesmo SHA-256 da ROM local e os nove grupos de teste, além da checagem dos 20 documentos Markdown. O registro resumido está em [ci.json](../evidencias/2026-10-23/ci.json).

A [release pública v0.1.0](https://github.com/AlanHJH/gba-assembly-ai/releases/tag/v0.1.0) foi criada nesse commit, com a ROM, seu arquivo SHA-256, o MP4 e o artigo exportado. Foram executados:

```sh
python3 tools/package.py
gh release create v0.1.0 --repo AlanHJH/gba-assembly-ai --target ab5a52135655af7227f13ac29f5078212cd0907e --title 'Gateblade v0.1.0' --notes-file docs/releases/v0.1.0.md dist/gateblade-v0.1.0.gba dist/gateblade-v0.1.0.sha256 dist/gateblade-demo.mp4 dist/gateblade-artigo.md
gh release view v0.1.0 --repo AlanHJH/gba-assembly-ai --json tagName,url,isDraft,isPrerelease,targetCommitish,assets
```

A consulta confirmou a release publicada e os quatro arquivos enviados. Downloads sem autenticação da ROM e do artigo foram comparados byte a byte com os artefatos locais. A imagem versionada do GIF usada pelo artigo também respondeu publicamente. Não houve publicação no blog.

## Material editorial e limites

Foi escrito o [artigo em português](../../article/artigo.md), além dos guias de [jogo](../como-jogar.md) e [reprodução](../reproducao.md). O roteiro anterior permanece como registro da intenção editorial inicial; o texto completo agora é a base para revisão.

Não houve integração no site pessoal, publicação no blog, teste em console físico, salvamento, inventário ou música. A licença de reutilização permanece pendente. Melhorias propostas são identificadas no plano e no artigo, sem serem apresentadas como entregas desta versão.
