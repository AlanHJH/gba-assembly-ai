# Recursos visuais e mapas

Os tiles, letras, herói, Brumins, chefe, torres e espada são definidos por código em [tools/assets.py](../tools/assets.py). Não há download de imagens ou fontes durante a construção. São recursos originais do projeto, sem material de Pokémon.

O script escreve gráficos 4bpp e paletas em `build/assets/`; o assembly inclui os binários com `.incbin`. Os 128 tiles de fundo contêm grama, estrada, pontos, base, portal, árvores e fonte. Metatiles de 16 pixels usam quatro tiles de 8 pixels.

| Tiles de objeto (32 bytes cada) | Uso |
| --- | --- |
| 0–31 | Herói, quatro direções e dois passos |
| 32–39 / 40–47 | Brumins comuns / corredores |
| 48–79 | Guardião da Névoa, 32 pixels |
| 80–143 | Espada, quatro direções |
| 144–151 | BOLT, dois níveis |
| 152–159 | FROST, dois níveis |
| 160–167 | BLAST, dois níveis |
| 168–170 | Efeitos de disparo |
| 171–175 | Reservados |
| 176–179 | Cursor de célula adjacente |

`assets/stages.json` é a fonte dos dez mapas: nome, tema, ondas e vértices da rota. [tools/maps.py](../tools/maps.py) gera e valida células adjacentes, pontos fora da rota e acessibilidade antes de criar os dados usados pelo assembly. Cinco temas de paleta acompanham dez geometrias distintas. `build/assets/maps.json` permite inspecionar os dados gerados.

O cabeçalho de cartucho é tratado por `tools/rom.py`, separadamente dos recursos. A licença de reutilização do projeto continua pendente de definição pelo mantenedor.
