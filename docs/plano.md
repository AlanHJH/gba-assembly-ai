# Plano de desenvolvimento

Atualizado em 24 de outubro de 2026.

## Estado atual: Gateblade TD 0.2.0

- [x] Projeto independente do site, público no GitHub.
- [x] Startup e regras próprias em assembly ARM7TDMI.
- [x] Dez mapas com rotas autorais distintas e pontos fora da estrada.
- [x] Movimento cardinal por tiles, colisões e cursor de construção.
- [x] Tutorial inicial e vinte ondas na campanha.
- [x] Brumins comuns, corredores e chefe na última onda.
- [x] Moedas por eliminação e saldo entre fases.
- [x] Três tipos de torre e melhoria até nível 2.
- [x] Desbloqueios progressivos, lentidão e dano em área.
- [x] Base com vida, derrota, pausa e reinício.
- [x] Portal condicionado ao término da defesa e travessia pelo herói.
- [x] Quinze grupos de teste no mGBA, incluindo campanha só por botões.
- [x] Guia, arquitetura, decisão, diário e artigo em Markdown.
- [x] Capturas e demonstração da ROM real, com cortes identificados.

Os comandos `make verify`, `make demo` e `make package` são o processo de validação e distribuição. O resultado remoto da release e da integração contínua é registrado no diário, com hash da ROM, sem inferir sucesso da existência de um workflow.

## Histórico preservado

A tag e a release [v0.1.0](https://github.com/AlanHJH/gba-assembly-ai/releases/tag/v0.1.0) mantêm o primeiro jogo de ação em quatro salas, com seu [artigo](../article/artigo-v0.1.0.md) e [evidências](evidencias/2026-10-23/README.md). A nova direção foi solicitada pelo usuário e registrada na [decisão 0004](decisoes/0004-campanha-tower-defense.md).

## Próximos passos

- Testar com pessoas: legibilidade do tutorial, controles, dificuldade e economia.
- Avaliar se o reembolso integral e o bônus de transição deixam as últimas fases fáceis demais.
- Testar em GBA físico, registrando equipamento e hash.
- Definir licença de reutilização.
- Avaliar salvamento, novas animações, áudio de torres e mais mapas depois do feedback.
- Revisar editorialmente o artigo e integrá-lo ao blog em etapa separada.

A campanha é um protótipo funcional; não foi medida a dificuldade para jogadores humanos. O artigo não foi publicado automaticamente no site pessoal.
