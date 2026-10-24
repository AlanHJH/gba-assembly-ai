# ADR 0004 — Campanha de tower defense em dez mapas

Data: 24 de outubro de 2026. Estado: adotada; validação detalhada no diário.

## Contexto e decisão humana

O usuário mudou a proposta para movimentação clássica por tiles e defesa de uma base. Confirmou torres **ao lado do caminho, mantendo a passagem livre**. Pediu dez fases com mapas diferentes, tutorial inicial, dificuldade crescente e moedas por eliminações para comprar torres com funções distintas. Ao terminar cada defesa, o herói deve caminhar até a saída.

A campanha anterior permanece na tag `v0.1.0`. A nova versão substitui as regras atuais sem apagar suas evidências e seu artigo histórico.

## Decisão adotada

- GBA, ARM7TDMI e executável próprio em assembly continuam. Python prepara dados e testa a ROM no computador.
- Dez mapas de 14 × 7 células de 16 pixels, com rotas autorais diferentes e oito pontos de construção fora da rota. A ferramenta valida continuidade, ausência de cruzamentos e acesso aos pontos mesmo com todas as torres construídas.
- Passos cardinais de oito frames, sem mudança de direção no meio do passo. Direção + A permite virar e construir sem andar sobre o ponto.
- Brumins são criaturas fictícias: comuns verdes e corredores laranja. O Guardião da Névoa aparece na última onda do décimo mapa.
- A primeira fase tem uma onda; as fases 2–9 têm duas; a última tem três: vinte ondas. O jogador inicia cada onda com R e pode preparar a defesa sem limite de tempo.
- BOLT custa 20 moedas, FROST 30 e BLAST 40. FROST é liberada na fase 3, BLAST na fase 6. Cada torre aceita uma melhoria por 20 moedas. L alterna o tipo disponível.
- Alvos são priorizados pelo maior avanço na rota dentro do alcance em distância Manhattan. BOLT atira mais rápido; FROST aplica lentidão; BLAST causa dano em área. O dano é instantâneo; o efeito gráfico representa o disparo, não um projétil com física.
- O herói conserva uma espada em B como ajuda. Ele não sofre dano de contato; a derrota acontece quando a vida da base chega a zero.
- A base começa cada mapa com seis pontos. Inimigos comuns causam um de dano ao escapar; o chefe causa três. Cada eliminação rende cinco moedas; escapar não rende moedas.
- Começa-se com 60 moedas. Elas persistem entre fases. Ao sair, todas as moedas investidas nas torres do mapa são devolvidas, mais 20 de bônus; as torres são desmontadas. O saldo é limitado a 999. Isso permite reconstruir em um mapa novo sem punir a troca obrigatória de cenário.
- A saída fica bloqueada até concluir todas as ondas; concluir a defesa não muda de mapa automaticamente. O herói precisa alcançar o portal.

## Alternativas e consequências

Construir sobre a rota contrariaria a escolha humana e exigiria recalcular caminhos. Torres livres em qualquer célula aumentariam o risco de bloqueios; pontos fixos tornam a regra legível e reproduzível. Reutilizar um único mapa com cores diferentes não atenderia às dez rotas distintas. Cobrar novamente todas as torres sem reembolso poderia tornar uma campanha irrecuperável mesmo após vitórias; a economia adotada explicita a desmontagem.

O controle por tiles foi inspirado no gênero, com arte e mapas originais. Não foram incorporados recursos de Pokémon. A campanha é linear, não um mundo aberto. Não há salvamento, venda individual de torres ou seleção de fases nesta versão.

## Validação prevista

Construir e executar a ROM; cenários isolados para moedas, tipos, prioridades, lentidão, área, saída, pausa e dano excedente; campanha inteira usando somente botões; capturas e hash. Resultados observados, falhas e ajustes ficam no diário e em `docs/evidencias/2026-10-24/`.
