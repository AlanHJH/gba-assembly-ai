# Sessão — Gateblade TD: dez mapas, ondas e economia

Data: 24 de outubro de 2026. Projeto independente do site pessoal. Versão anterior preservada em `v0.1.0`; esta sessão desenvolve `v0.2.0`.

## Pedido e decisões

O usuário pediu movimentação clássica por células e um tower defense. Confirmou os pontos **ao lado do caminho, mantendo a passagem livre**. Acrescentou dez fases com mapas diferentes, primeiro mapa de tutorial, inimigos fictícios que rendem moedas, compra de torres com funções distintas e transição caminhando para o próximo mapa. Também manteve o pedido de documentar o processo em Markdown para redigir e publicar um artigo posteriormente.

Essas são escolhas humanas explícitas. A implementação definiu custos, tempos, vida, dimensões, pontos fixos, reembolso e tipos concretos. Não se atribui ao usuário aprovação individual desses parâmetros. A [decisão 0004](../decisoes/0004-campanha-tower-defense.md) compara as alternativas e registra as consequências.

Adotou-se BOLT rápida, FROST com lentidão e BLAST em área; desbloqueios nas fases 1, 3 e 6. O herói conserva a espada como ajuda, enquanto a vida ameaçada passa a ser a da base. A IA apoiou desenho das estruturas, assembly, geradores, bot, testes e documentação. Não houve medição de produtividade com/sem IA, nem se afirma revisão humana de cada instrução.

## Implementação

- `assets/stages.json` passou a descrever dez rotas autorais, ondas e temas.
- `tools/maps.py` expande rotas, escolhe oito pontos fora da estrada e valida acesso por busca em largura com todas as torres construídas. Emite dados binários para `.incbin` e JSON para inspeção.
- `src/constants.inc` e a BSS em `src/main.s` receberam estado de campanha, movimento por células, economia, doze inimigos e oito torres. Startup, stack, linker e proteção contra multiboot foram preservados.
- `src/game.s` implementa passos de oito atualizações, colisões, direção + A sem deslocamento, compra em borda de botão, melhorias, tipos progressivos, ondas, rotas, prioridades, lentidão, área, moedas, vida da base, pausa, saída e vitória.
- `src/render.s` compõe mapa por metatiles, paleta por fase, HUD, cursor, torres e efeitos. A espada permanece em B. Os disparos aplicam dano instantâneo; o efeito gráfico não tem física de projétil.
- `tools/assets.py` gera recursos originais: 128 tiles de fundo, 180 de objetos e paletas de dez fases com cinco temas. Não foi incorporada arte de Pokémon.
- `tools/test_game.py` executa quinze grupos na ROM real. `tools/playthrough.py` controla a campanha somente com botões e grava o registro integral. O frontend conta escritas de estado para garantir zero durante esse percurso; o teste também reproduz os mesmos botões desde um novo boot.
- `VERSION`, `tools/package.py` e `tools/export_article.py` centralizam a versão do pacote e dos links públicos.
- README, guia, arquitetura, reprodução, plano e artigo foram atualizados. `article/artigo-v0.1.0.md` preserva o texto anterior sem apagar o histórico.

O mapa possui 14 × 7 células de 16 pixels. A vida da base volta a seis no mapa seguinte. O saldo inicial é 60; cada eliminação rende cinco. O reembolso integral do investimento na saída, mais 20 de bônus, financia a reconstrução da defesa; essa economia exige avaliação com jogadores.

## Comandos realmente executados

Na raiz do repositório:

```sh
python3 tools/maps.py
make all
python3 tools/playthrough.py
make test
make demo
make verify
make clean
make verify
make demo
make package
arm-none-eabi-size build/gateblade.elf
ffprobe -v error -show_entries format=duration -show_entries stream=width,height,r_frame_rate -of json build/test-results/gateblade-demo.mp4
```

Também foram usados `arm-none-eabi-nm`, `git diff`, leitura de fontes e inspeção visual das capturas da ROM. O ambiente continua macOS 15.6 arm64, Binutils 2.44, Python 3.13.3, GNU Make 3.81, CMake 4.0.1, SDL2 2.32.4 e mGBA 0.10.5 de origem verificada. Os comandos completos de construção e preparação do emulador estão no [guia de reprodução](../reproducao.md).

## Tentativas que falharam e correções

1. **Premissa errada na primeira travessia do bot.** O jogo abriu o portal e carregou o mapa seguinte, mas o bot exigia continuar na coordenada do portal. Corrigiu-se a verificação para aceitar a transição e a nova posição inicial. Não era uma falha da transição da ROM.
2. **Bot tentava andar durante a animação de espada.** Depois de uma onda, o controle B ainda havia iniciado um golpe; o bot assumia que os oito frames seguintes seriam um passo completo. Ele passou a soltar o ataque e aguardar seu término antes de navegar. A regra do jogo que mantém a direção do golpe foi preservada.
3. **Cenário de lentidão mal posicionado.** O teste iniciou o inimigo exatamente sobre o nó que ele ainda deveria alcançar. A primeira atualização útil avançava o índice de rota, comprometendo a medição de quatro pixels em dezesseis atualizações. A preparação foi corrigida para a célula anterior; o teste então observou a velocidade prevista sem modificar a regra.
4. **Erro de indentação em limpeza do gerador.** Remover uma variável não usada deixou o `for offset` com nível incorreto. `make demo` parou em `IndentationError`. A indentação foi corrigida e a geração completa foi repetida.
5. **Verificação de documentação antes de terminar os arquivos.** A primeira execução de `make verify` passou na ROM, mas apontou os links do diário e do índice de evidências ainda não criados. Os documentos foram concluídos e a checagem foi repetida antes da distribuição.

6. **Revisão final da paleta de disparo.** O efeito de FROST referenciava uma entrada de paleta preenchida com preto. Foi trocada pela cor azul já definida no banco de efeitos. A correção é visual; ROM, demonstração e testes foram reconstruídos para identificar o artefato correto.

Essas tentativas fazem parte da sessão e não foram reescritas como se todas as premissas iniciais estivessem corretas.

## Validação observada

A ROM iniciou no mGBA e executou o tutorial, as dez fases e a vitória. Quinze grupos passaram, cobrindo movimento, bloqueios, construção, saldo insuficiente, botão mantido, melhoria máxima, desbloqueios, criação de ondas, chefe, prioridade, alcance, recompensa única, lentidão, área, espada, áudio, escapes, derrota por dano excedente, reinício, pausa e transições.

O percurso por controle chegou à vitória após **15.907 frames**, com **vinte ondas, 146 eliminações, zero escapes e 590 moedas** no final. As seis vidas de cada base foram mantidas nesse percurso. O bot não concedeu moedas, não moveu atores diretamente e não pulou fases. Isso demonstra uma estratégia viável; não comprova dificuldade adequada para pessoas.

A captura inspecionada inclui tela inicial, mapas 1, 3, 6 e 10, defesa em andamento, Guardião e vitória. O vídeo tem 626 quadros selecionados, 720 × 480, duração aproximada de 62,886 segundos. Há cortes entre trechos, sem aceleração dentro deles e sem faixa de áudio. O registro completo de botões e os intervalos dos trechos acompanham a evidência.

A BSS própria ocupa 1.008 bytes; isso não mede todo o uso de memória do console. A identificação final da ROM e as comprovações remotas ficam no [índice de evidências](../evidencias/2026-10-24/README.md).

## Limites e próximos passos

Não foi testado em console físico. Não houve sessão manual de teclado ou teste com pessoas nesta etapa; os controles foram exercitados programaticamente pelo mGBA. A campanha é linear e não possui salvamento, venda individual ou música. A licença continua pendente. O site pessoal não foi alterado nem o artigo publicado automaticamente.

Revisar o tutorial e a economia com jogadores, testar em hardware e fazer revisão editorial antes do blog. O possível excesso de capital nas fases finais está explicitamente registrado no plano.

## Construção limpa e pacote final local

`make clean` foi seguido de nova geração dos recursos e montagem. A campanha e a reprodução integral dos botões passaram. Depois da inclusão dos JSONs no índice de evidências, `make package` passou nos quinze grupos e na verificação dos 25 documentos Markdown. ROM: 22.520 bytes, SHA-256 `96e8e02ae5e066ed0765a75814b7d418a0ea0dbbf9a2527318679e3141e3a3aa`. O pacote copiou essa mesma ROM para `dist/gateblade-v0.2.0.gba` e exportou `dist/gateblade-artigo.md` com links da tag v0.2.0.
