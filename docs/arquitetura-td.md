# Arquitetura da campanha de defesa

## Do dado autoral ao cartucho

`assets/stages.json` descreve nomes, temas, ondas, vértices das dez rotas e oito pontos de construção escritos explicitamente. `tools/maps.py` expande cada segmento em células adjacentes, sem diagonais ou cruzamentos. Valida os pontos fora da estrada e verifica por busca em largura que todos podem ser atendidos mesmo com todas as torres construídas. Também verifica acesso à saída. A seleção automática de pontos foi removida para facilitar edição manual; as posições e a ROM continuam iguais.

A construção gera mapas de 98 bytes, rotas e pontos com pares de coordenadas de 32 bits, uma tabela de fases e JSON para inspeção dos testes. Os arquivos binários entram na ROM por `.incbin`. Nenhum interpretador JSON ou Python executa no GBA.

Cada registro da tabela de fases ocupa 32 bytes: ponteiros de mapa, rota, pontos e nome, quantidade de células da rota, quantidade de ondas, vida básica do inimigo e intervalo de entrada. Os mapas têm 14 × 7 células; a origem em pixels é (8,32), e cada célula mede 16 × 16.

## Estado e atualização

`src/main.s` preserva o startup do cartucho e limpa a seção BSS em EWRAM. O laço espera VBlank, avança `frame_tick`, lê os botões, atualiza regras e renderiza. `src/game.s` implementa TITLE, PLAYING, PAUSED, DEAD e VICTORY. A pausa mantém os contadores de combate e movimento congelados; o relógio de frames continua avançando.

Em PLAYING, a ordem é: contadores, movimento, seleção/compra, espada, início/entrada da onda, movimento e chegada dos inimigos, disparos das torres, término da onda e verificação da saída. Um inimigo que alcança a base nessa atualização chega antes da próxima oportunidade de disparo. A derrota interrompe a atualização das torres.

O herói mantém célula atual, destino e pixels restantes. Avança dois pixels por atualização; um passo leva oito. A direção permanece fixa durante o passo. Direcional + A atualiza a direção sem iniciar movimento. Construções ocupam células que o herói não atravessa; todas estão fora da estrada. O portal fechado e a base são obstáculos.

## Inimigos e ondas

Há doze posições de inimigo em EWRAM, cada uma com 48 bytes:

| Offset | Campo |
| --- | --- |
| 0 / 4 | X / Y |
| 8 / 12 | Vida / tipo |
| 16 / 20 | Flash de dano / identificador do último golpe de espada |
| 24 / 28 | Próxima célula da rota / máscara de velocidade |
| 32 / 36 | Avanço em pixels / duração da lentidão |
| 40 / 44 | Tamanho lógico / reservado |

Os inimigos seguem a sequência de células, movendo-se um pixel em um eixo por vez. Não perseguem o herói nem calculam caminhos em tempo real. Comum usa `frame_tick & 1 == 0`; corredor anda sempre; lentidão usa `frame_tick & 3 == 0`. O gráfico do chefe mede 32 pixels, centrado na âncora de 16 pixels usada pela rota e pelas colisões de espada.

Com índices começando em zero, a onda tem `4 + (fase >> 1) + onda * 2` inimigos. Vida comum é `2 + (fase >> 1) + onda`. O intervalo de entrada é `80 - fase * 4` armazenado em um contador: após carregar N, a próxima entrada acontece N+1 atualizações depois. Um slot morto pode ser reutilizado, após limpar todos os seus campos. Se não houver slot, a entrada aguarda. O primeiro slot da última onda recebe o chefe com 48 de vida.

Vida zero é terminal. `damage_enemy` testa antes de aplicar dano e trata resultado menor ou igual a zero, concedendo exatamente uma recompensa de cinco moedas e decrementando o contador de vivos uma vez. Chegadas à base removem o inimigo sem recompensa. Dano excedente à vida da base também termina em zero e derrota; há regressão específica para chefe contra uma base com apenas um ponto.

## Torres e ataques

Oito posições de torre de 32 bytes guardam X, Y, nível, recarga, índice de alvo, duração do efeito de disparo, tipo e investimento acumulado. Nível zero significa ponto livre. A compra trabalha com a célula à frente; verifica presença, nível e saldo antes de debitar. O evento de borda de A evita compras repetidas ao segurar o botão.

Para cada torre pronta, o jogo percorre os doze inimigos. Calcula `abs(ex-tx) + abs(ey-ty)`, compara ao alcance e escolhe o maior avanço na rota. Empates preservam o primeiro slot. FROST escreve o contador de lentidão. BLAST percorre novamente os slots e causa dano aos que estão a até 24 pixels do alvo principal, sem duplicá-lo.

| Tipo | Dano nível 1 / 2 | Alcance nível 1 / 2 | Contador de recarga nível 1 / 2 |
| --- | --- | --- | --- |
| BOLT | 1 / 2 | 48 / 64 | 32 / 24 |
| FROST | 1 / 2 | 64 / 80 | 50 / 42 |
| BLAST | 2 / 3 | 48 / 64 | 60 / 52 |

Uma torre que acabou de disparar carrega a recarga. As atualizações seguintes decrementam esse valor e retornam; a busca é retomada na atualização seguinte ao zero. Por isso o intervalo observado é o valor da tabela mais um. Sem inimigo no alcance, a recarga fica em zero e a torre verifica novamente na próxima atualização. Melhorar zera a recarga, permitindo responder na mesma atualização.

A espada usa caixa de 32 pixels à frente do herói, nove atualizações visuais e intervalo de vinte para iniciar outro golpe. Cada inimigo guarda o identificador do golpe para não receber dano repetido durante a mesma animação. O dano é um. Movimento fica bloqueado durante a animação, preservando a direção.

## Economia e transição

São 60 moedas iniciais, cinco por eliminação, construção por 20/30/40 e melhoria por 20. A cada compra, `stage_invested` e o custo do ponto são atualizados. Ao caminhar até o portal aberto: saldo + investimento + 20, limitado a 999; próxima fase; torres e inimigos limpos; base restaurada. Na última fase, a mesma travessia exibe a vitória sem gerar outro mapa.

A onda só acaba quando não há entradas pendentes nem inimigos vivos. O índice avança; atingir o total abre o portal. A próxima onda depende de R. Não há transição automática ao matar o último inimigo.

## Vídeo e recursos

Mode 0 com BG0 em tiles 4bpp, paletas e sprites em OAM. Um metatile de cenário usa quatro tiles de 8 pixels. A arte é gerada pelo projeto e cinco temas de grama distinguem a campanha, além das dez geometrias. O HUD usa texto ASCII; seus textos de jogo estão em inglês.

Objetos usam posições fixas: herói 0, inimigos 1–12, torres 13–20, efeitos 21–28, espada 29 e cursor 30. O DMA copia recursos na inicialização e a paleta da fase na transição. O jogo não usa engine, rotinas de jogo externas ou runtime C.

## Evidência e alcance dos testes

`tools/test_game.py` executa quinze grupos no mGBA. Cenários focados escrevem EWRAM deliberadamente para isolar regras. `tools/playthrough.py` lê estado e mapas para decidir controles, mas nunca escreve no estado. Seu registro de entradas cobre dez mapas, vinte ondas e a vitória. A demonstração seleciona trechos dessa execução com cortes, sem acelerar os trechos. Teste emulador não comprova operação em console físico nem balanceamento para jogadores humanos.
