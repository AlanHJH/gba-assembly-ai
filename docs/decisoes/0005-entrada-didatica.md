# ADR 0005 — Uma entrada menor e reproduzível para aprender do zero

Data: 24 de outubro de 2026. Estado: adotada.

## Contexto

O usuário pediu simplificar o projeto, quando possível, para alguém conseguir desenvolver algo próximo manualmente. Pediu um artigo detalhado, com snippets documentados. Depois autorizou publicar o artigo no blog para avaliar sua apresentação em produção.

## Decisão adotada

A entrada recomendada passa a ser `learn/main.s`: um mapa, uma estrada reta, um ponto de construção, um tipo de torre e quatro inimigos, um por vez. Mode 3 e retângulos removem assets, sprites, fonte, paletas e conversão de mapas desse primeiro contato. São quatro ROMs progressivas a partir da mesma fonte, selecionadas por uma constante do assembler. O conteúdo completo do assembly, linker e ferramenta de cabeçalho está no artigo, permitindo reconstrução em pasta vazia.

A campanha de dez mapas continua funcional. Seus pontos de construção deixam de ser calculados por uma heurística: são coordenadas explícitas em `assets/stages.json`. Mantêm-se validações de continuidade, pontos fora da rota e acessibilidade. As coordenadas são exatamente as anteriores; o SHA-256 da ROM completa permanece igual ao da versão 0.2.0.

Os snippets são extraídos do código e conferidos por `tools/article_snippets.py`. `tools/test_article.py` monta os blocos apresentados em uma pasta temporária com apenas três arquivos e exige uma ROM idêntica à etapa 4. `tools/test_learn.py` executa todas as etapas no mGBA, incluindo partida, derrota e reinício.

## Alternativas e consequências

Apagar fases ou recursos da campanha descartaria pedidos anteriores. Apenas reorganizar arquivos não reduziria os conceitos necessários para a primeira partida. Macros extensas esconderiam justamente as instruções a ensinar. A versão didática tem regras menores e completas, em vez de tentar explicar todos os recursos em uma primeira ROM.

Há dois renderizadores com propósitos distintos: bitmap pequeno para aprendizado e tiles/sprites para a campanha. A duplicação deliberada fica isolada; o tutorial não depende de infraestrutura de geração do jogo completo. A biblioteca do emulador é reutilizada apenas nos testes do computador.

O artigo descreve um caminho de implementação manual, mas não reescreve o desenvolvimento assistido por IA como se tivesse ocorrido todo à mão. A licença e os testes em console físico continuam pendentes.
