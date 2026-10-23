# 0002 — Gateblade e o ciclo de combate por salas

**Data:** 23 de outubro de 2026.

**Estado:** adotada e implementada na primeira versão.

## Contexto e requisito do usuário

Alan especificou um herói com espada que causa dano em inimigos. Cada fase tem entrada e saída; a saída só pode ser usada depois que todos os inimigos forem derrotados. O ciclo se repete até um chefe mais difícil. Também pediu o desenvolvimento completo e a documentação em Markdown como base para publicar no blog, incluindo uma explicação ou demonstração do funcionamento.

## Decisão de implementação

Criar Gateblade, um jogo de ação visto de cima com quatro salas fixas. O nome, o número de salas e os valores abaixo são escolhas desta implementação; não foram apresentados como requisitos numéricos do usuário.

- Herói de 16 × 16 pixels, seis corações e movimento cardinal.
- Golpe direcional com área de 32 × 32, dano de um ponto, nove quadros ativos e intervalo de vinte quadros entre ataques.
- Um identificador por golpe impede múltiplos danos ao mesmo inimigo na mesma animação.
- Dois slimes na primeira sala; três inimigos na segunda; quatro na terceira; um chefe na quarta.
- Inimigos comuns com dois ou três pontos de vida e dano de um coração.
- Chefe de 32 × 32, dezesseis pontos de vida e dano de dois corações.
- Proteção de 75 quadros depois do dano e cura de um coração ao trocar de sala.
- Porta ao norte condicionada ao contador de inimigos vivos e à chegada física do herói ao vão.
- Estados de título, partida, pausa, derrota e vitória, com reinício completo.
- Efeitos sonoros simples para espada, dano e abertura da porta.

## Chefe

O Guardião alterna aproximação, preparação sinalizada, investida e recuperação. O dano da espada produz uma indicação visual, mas não congela seu ciclo. Isso evita que ataques repetidos impeçam indefinidamente a investida.

## Alternativas

Um mapa grande, inventário e geração procedural ampliariam o trabalho sem serem necessários ao ciclo pedido. Um único inimigo sem telegráficos distinguiria pouco o chefe. Uma saída ativada imediatamente após a última morte eliminaria o requisito de alcançar a saída. Foram mantidas salas fixas, uma máquina de estados para o chefe e travessia explícita da porta.

## Validação e consequências

Os testes e a campanha completa estão descritos em [evidências](../evidencias/2026-10-23/README.md). A primeira estratégia automatizada morreu no chefe. A revisão passou a manter distância de espada e fugir durante preparação/investida, sem enfraquecer o chefe nem alterar a vida durante a partida.

Não há salvamento, obstáculos internos, música, inventário ou aleatoriedade. Expandir o número de salas requer uma configuração de encontros mais geral: aumentar apenas `LAST_ROOM` pode exceder o arranjo atual de quatro adversários. Isso é melhoria futura, não uma funcionalidade já entregue.
