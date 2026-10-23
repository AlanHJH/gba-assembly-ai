# Evidências — Gateblade v0.1.0

Capturas e resultados de 23 de outubro de 2026. Os gráficos foram produzidos pela ROM executada no núcleo libretro do mGBA 0.10.5, construído de origem oficial com hash conferido.

## Artefato validado

| Item | Resultado |
| --- | --- |
| ROM | `gateblade.gba` |
| Tamanho | 14.456 bytes |
| SHA-256 | `567a13b74c0e0bcf0d8a302558569ecc7e686567986070467ee6d2480f7a0216` |
| Estado próprio em `.bss` | 260 bytes; não é uma medida de todo o uso de memória do console |
| Emulador | mGBA 0.10.5, núcleo libretro |
| BIOS externa fornecida | Não |
| Console físico testado | Não |

O [relatório JSON](report.json) identifica a ROM e os nove grupos de teste. O [registro da campanha](playthrough.json) preserva entradas de controle com quantidades de quadros.

O [registro de CI](ci.json) aponta para a execução bem-sucedida no Ubuntu 24.04. O log remoto foi conferido e gerou o mesmo SHA-256 da construção no macOS. A ROM, o vídeo e o artigo exportado foram distribuídos na [release v0.1.0](https://github.com/AlanHJH/gba-assembly-ai/releases/tag/v0.1.0); os downloads públicos da ROM e do artigo foram conferidos contra os arquivos locais.

## Resultados observados

- Cabeçalho de cartucho válido e regressão da identificação multiboot coberta.
- Tela inicial e uma atualização por quadro verificada.
- Limites de movimento e impossibilidade de sair com inimigos vivos.
- Pausa sem alteração das posições, vida ou contagem de ataque.
- Espada direcional, intervalo, um dano por golpe e amostras de áudio produzidas.
- Dano de contato, proteção temporária e dano maior do chefe.
- Derrota, reinício e ciclo de preparação/investida/recuperação.
- Campanha completa por controle: salas 1 a 4, dez eliminações, vitória com dois corações e reinício após vitória.

Os testes focados preparam estado em EWRAM para isolar regras. A campanha completa não faz essas escritas: somente lê o estado para decidir quais botões apertar. Ela chegou à vitória após 1.484 quadros de entrada, incluindo a apresentação inicial, e gravou mais 120 quadros na tela final.

## Capturas

| Situação | Imagem |
| --- | --- |
| Título | [title.png](title.png) |
| Ataque de espada | [combat.png](combat.png) |
| Sala limpa e saída liberada | [gate-open.png](gate-open.png) |
| Entrada da sala do chefe | [room-4.png](room-4.png) |
| Preparação da investida | [boss-windup.png](boss-windup.png) |
| Pausa | [pause.png](pause.png) |
| Derrota | [death.png](death.png) |
| Vitória | [victory.png](victory.png) |

![Campanha completa capturada no emulador](gateblade-demo.gif)

O GIF seleciona um quadro a cada seis quadros emulados. Sua duração é de aproximadamente 27 segundos, preservando o ritmo do percurso. A gravação não inclui áudio; as amostras sonoras da ROM são verificadas separadamente. O vídeo MP4 é produzido pelo mesmo comando de demonstração e distribuído junto da release.

## Repetir

Na raiz do projeto, depois de preparar as dependências:

```sh
make emulator
make verify
make demo
```

O resultado atual vai para `build/test-results/`. Esta pasta mantém uma seleção estável da primeira versão; não é sobrescrita automaticamente por novas execuções.
