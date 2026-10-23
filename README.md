# Game Boy Advance em assembly com IA

Um projeto de aprendizado para desenvolver um jogo de **Game Boy Advance (GBA) em assembly**, usando IA como apoio à pesquisa, à implementação e à depuração. O desenvolvimento será registrado passo a passo para sustentar um artigo que outras pessoas consigam reproduzir.

**Estado atual:** fundação documental. Ainda não há código do jogo, ROM gerada ou execução em emulador validada.

## Objetivo

Construir um exemplo pequeno e compreensível, explicar como ele funciona e preservar as decisões e correções que levaram ao resultado. O artigo será escrito a partir dessas evidências, incluindo o que precisou ser corrigido e o que ficou como melhoria.

O alvo inicial é o GBA, com CPU ARM7TDMI. A referência de hardware está no [Tonc](https://gbadev.net/tonc/hardware.html), e a relação com a arquitetura Armv4T é descrita pela [Arm](https://developer.arm.com/community/arm-community-blogs/b/architectures-and-processors-blog/posts/arm-fundamentals-introduction-to-understanding-arm-processors). O escopo e o significado de assembly puro estão registrados na [decisão inicial](docs/decisoes/0001-escopo-e-metodo.md).

## Como acompanhar

| Documento | Finalidade |
| --- | --- |
| [Plano de desenvolvimento](docs/plano.md) | Etapas, critérios de conclusão e escolhas pendentes |
| [Ambiente](docs/ambiente.md) | Ferramentas encontradas, lacunas e futura instalação reproduzível |
| [Decisões](docs/decisoes/0001-escopo-e-metodo.md) | Escolhas, alternativas e consequências |
| [Diário inicial](docs/diario/2026-10-23-fundacao.md) | O que foi feito e verificado em cada etapa |
| [Referências técnicas](docs/referencias.md) | Fontes consultadas e limites de cada uma |
| [Evidências](docs/evidencias/README.md) | Logs, capturas e resultados que sustentam o relato |
| [Roteiro do artigo](article/roteiro.md) | Estrutura provisória e correspondência entre afirmações e evidências |

`src/` receberá o assembly do jogo; `assets/`, seus recursos; e `tools/`, os utilitários executados no computador. Essas pastas ainda não contêm implementação.

## Método de trabalho

Cada mudança significativa deve registrar o problema, a proposta, os arquivos alterados, os comandos executados e o resultado observado. Decisões de arquitetura recebem um registro próprio; experimentos e correções entram no diário. Sugestões da IA precisam ser verificadas em fontes técnicas e na execução apropriada.

Os modelos de [sessão](docs/modelos/sessao.md) e [decisão](docs/modelos/decisao.md) ajudam a manter esse histórico. As instruções para colaboradores e agentes estão em [AGENTS.md](AGENTS.md).

## Compartilhamento

O projeto está no repositório público [AlanHJH/gba-assembly-ai](https://github.com/AlanHJH/gba-assembly-ai), separado do repositório do site pessoal. A publicação do artigo no site será uma etapa posterior.

Para acompanhar os arquivos localmente:

```sh
git clone https://github.com/AlanHJH/gba-assembly-ai.git
cd gba-assembly-ai
```

Comece pelo plano e pelo diário. Ainda não há comando de construção do jogo validado.

A licença de reutilização do código e da documentação ainda será definida. O projeto está em fase inicial e ainda não oferece um jogo pronto para baixar.

## Próximo marco

Selecionar e validar a instalação da toolchain e do emulador, registrar suas versões e produzir uma primeira ROM que mostre um resultado visual simples. A mecânica do jogo será definida depois dessa base.
