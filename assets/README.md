# Recursos visuais

Os tiles do cenário, letras, herói, inimigos, chefe e arcos da espada são definidos por código em [tools/assets.py](../tools/assets.py). Não há download de imagens ou fontes durante a construção.

O script escreve em `build/assets/` os gráficos 4bpp e as paletas que o assembly inclui na ROM com `.incbin`. A ordem dos sprites é um contrato com `src/render.s`: herói 0–31, slimes 32–39, sentinelas 40–47, chefe 48–79 e espada 80–143, em unidades de tiles de 32 bytes.

A ROM usa os bytes fixos de identificação exigidos pelo formato de cabeçalho de cartucho. Eles são tratados por `tools/rom.py`, separadamente dos recursos do jogo.

A licença de reutilização do projeto continua pendente de definição pelo mantenedor.
