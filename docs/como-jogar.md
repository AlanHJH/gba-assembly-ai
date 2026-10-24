# Como jogar Gateblade TD

## Objetivo

Defenda dez bases em dez mapas diferentes. Os Brumins chegam pela estrada de pedras e seguem até a base azul. Construa torres nos oito pontos dourados ao lado da estrada, mantendo a passagem livre. O herói pode caminhar pela grama e pela estrada e usar a espada para ajudar.

A movimentação é feita em células de 16 pixels, em quatro direções, com passos de oito frames. Um passo iniciado precisa terminar antes de virar. Árvores, a base, torres construídas e o portal fechado bloqueiam o herói. Inimigos não causam dano por contato ao herói.

## Controles

| Ação | Botão do GBA | Tecla padrão do mGBA SDL deste projeto |
| --- | --- | --- |
| Andar / escolher direção | Direcional | Setas |
| Construir ou melhorar o ponto à frente | A | X |
| Virar e construir sem andar | Direcional + A | Seta + X |
| Espada | B | Z |
| Alternar tipo de torre | L | A |
| Iniciar próxima onda | R | S |
| Iniciar / reiniciar | Start ou A | Enter ou X |
| Pausar / continuar | Start | Enter |

A construção exige um ponto adjacente à frente do herói. A moldura amarela indica essa célula. Segurar A não compra várias vezes: solte e aperte novamente para melhorar. Direção + A é útil para apontar ao ponto sem entrar nele. Não se constrói no meio de um passo. A espada pode ser mantida pressionada, com intervalo entre golpes.

## Primeira fase: tutorial

1. Pressione Start na tela inicial. O herói começa no canto inferior esquerdo; a base está à direita da estrada e a saída fica no canto inferior direito.
2. Você possui 60 moedas. Aproxime-se de um ponto dourado, vire para ele e pressione A. Uma BOLT custa 20 moedas. É possível começar com três torres.
3. Pressione R para iniciar a única onda. As torres atiram automaticamente. B permite ajudar com a espada quando um inimigo estiver à frente.
4. Observe a vida da base e as moedas. Cada eliminação rende cinco moedas. Espalhe a defesa para cobrir diferentes trechos do caminho.
5. Terminada a onda, o portal fica verde. Caminhe até ele para seguir à fase 2. Não há troca automática de mapa.

Na faixa superior, os seis corações representam a base, G é o saldo, W indica onda atual/total e F conta inimigos vivos mais os que ainda vão entrar. O rodapé mostra o tipo selecionado e seu preço de construção; melhorar uma torre existente sempre custa 20, independentemente do tipo selecionado. Durante a defesa, use Start para pausar.

## Moedas e torres

| Torre | Disponível a partir da fase | Construção | Função no nível 1 |
| --- | --- | --- | --- |
| BOLT | 1 | 20 | Dano 1, alcance 48 pixels, intervalo de 33 atualizações |
| FROST | 3 | 30 | Dano 1, alcance 64, intervalo de 51; lentidão por 60 atualizações |
| BLAST | 6 | 40 | Dano 2, alcance 48, intervalo de 61; área de 24 pixels ao redor do alvo |

L alterna somente os tipos já liberados. Cada torre pode chegar ao nível 2 pagando mais 20 moedas: ganha um de dano e 16 pixels de alcance; o contador de recarga diminui em oito. FROST também aumenta sua lentidão para 90 atualizações. Não há venda ou troca do tipo de uma torre construída.

O alcance e a área usam distância Manhattan: somam-se as diferenças horizontal e vertical, formando um losango. A prioridade é o inimigo mais adiantado na rota dentro do alcance. O dano é aplicado no disparo; o pequeno efeito visual não é um projétil que precisa atingir fisicamente o alvo. FROST faz o alvo andar um pixel a cada quatro atualizações enquanto durar o efeito. A BLAST pode acertar vários inimigos, uma vez cada por disparo.

Moedas por eliminações ficam disponíveis imediatamente para novas compras. O saldo acompanha o herói. Ao passar para outro mapa, as torres anteriores são desmontadas e devolvem **todo o valor investido**, incluindo melhorias, mais um bônus de 20 moedas. A base seguinte volta a seis pontos de vida. O saldo máximo é 999.

## Inimigos e derrota

Brumins verdes avançam um pixel a cada duas atualizações. Os corredores laranja, presentes a partir da fase 2, avançam a cada atualização. A partir das fases seguintes, as ondas têm mais inimigos, mais vida e entradas mais próximas. O Guardião da Névoa aparece como primeiro inimigo da terceira onda da fase 10, com 48 pontos de vida.

Um inimigo comum que chega à base retira um ponto; o Guardião retira três. Inimigos que escapam não concedem moedas. Se a base chegar a zero, aparece a derrota. Start ou A reinicia a campanha na fase 1 com 60 moedas.

Para liberar o portal, todos os inimigos de todas as ondas precisam ter sido resolvidos, por eliminação ou chegada à base, e a base deve continuar de pé. Portanto, sobreviver a alguns escapes é permitido. O chefe não possui as investidas da versão 0.1.0: nesta versão ele segue a estrada e ameaça a base.

## Campanha

| Fase | Mapa | Ondas | Inimigos nas ondas | Novidade |
| --- | --- | --- | --- | --- |
| 1 | First Watch | 1 | 4 | Tutorial, estrada reta e BOLT |
| 2 | River Bend | 2 | 4 / 6 | Primeira curva e corredores |
| 3 | Frost Pass | 2 | 5 / 7 | FROST e rota de retorno |
| 4 | Bramble Way | 2 | 5 / 7 | Curvas alternadas |
| 5 | Amber Road | 2 | 6 / 8 | Mais vida e mudança de lado |
| 6 | Ember Steps | 2 | 6 / 8 | BLAST e caminho em degraus |
| 7 | Moon Cross | 2 | 7 / 9 | Nova distribuição de cobertura |
| 8 | Glass Maze | 2 | 7 / 9 | Caminho longo em zigue-zague |
| 9 | Ashen Trail | 2 | 8 / 10 | Entradas mais próximas |
| 10 | Warden Keep | 3 | 8 / 10 / 12 | Chefe na última onda |

São 146 inimigos no total, incluindo o chefe. O mapa muda de geometria, não apenas de paleta. As fases usam cinco temas de cores. Os nomes aparecem na documentação e nos dados; o HUD identifica o número do mapa.

## Estratégia inicial e limitações

Comece cobrindo trechos diferentes da estrada. Em curvas, uma torre pode alcançar o inimigo antes e depois da mudança de direção. Melhore torres entre ondas e combine FROST com BOLT ou BLAST. A preparação é livre: R só inicia a próxima onda quando a atual terminou.

A vitória acontece ao atravessar o décimo portal. Start ou A começa outra campanha. Não há salvamento, seleção de fases ou manutenção das moedas após reiniciar. A validação foi feita no mGBA 0.10.5; ainda não foi realizado teste em GBA físico. O mapeamento de teclas pode mudar em outra configuração do emulador.
