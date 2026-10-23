# Como jogar Gateblade

Gateblade é um jogo curto de ação visto de cima. Você controla um herói com espada, entra em salas fechadas e precisa derrotar todos os inimigos para liberar a saída ao norte. Depois de três salas, enfrenta o Guardião na quarta e última sala.

## Abrir o jogo

Baixe `gateblade-v0.1.0.gba` na [página de releases](https://github.com/AlanHJH/gba-assembly-ai/releases). Abra a ROM em um emulador de Game Boy Advance. A versão testada neste projeto é o mGBA 0.10.5.

Para construir e executar a partir do código, consulte o [guia de reprodução](reproducao.md). Não é necessário acessar o site pessoal do autor.

## Controles

| Ação | Game Boy Advance | mGBA SDL construído pelo projeto |
| --- | --- | --- |
| Mover e virar o herói | Direcional | Setas |
| Atacar com a espada | A | X |
| Começar ou reiniciar | Start ou A | Enter ou X |
| Pausar ou continuar | Start | Enter |

Segurar A repete o ataque assim que o intervalo termina. O herói mantém a direção e para de andar enquanto o golpe está ativo. Para atacar um inimigo, vire-se para ele e aproxime-se até ficar ao alcance da espada. Não é preciso encostar o corpo do herói no inimigo.

## Regras da campanha

O herói começa com seis corações. Contato com inimigos comuns causa um coração de dano; contato com o chefe causa dois. Depois de ser atingido, o herói pisca e recebe proteção temporária. Ao entrar na próxima sala, recupera um coração, até o limite de seis.

| Sala | Adversários | Vida de cada adversário |
| --- | --- | --- |
| 1 | Dois slimes verdes | 2 golpes |
| 2 | Dois slimes e uma sentinela | 3 golpes |
| 3 | Dois slimes e duas sentinelas | 3 golpes |
| 4 | O Guardião | 16 golpes |

Cada golpe causa um ponto de dano. A mesma espada não acerta um adversário várias vezes durante a mesma animação. Slimes se aproximam mais devagar; sentinelas se aproximam mais depressa.

## Entradas e saídas

O herói aparece perto da entrada azul, no sul. A saída fica no centro da parede ao norte. Enquanto houver inimigos vivos, a porta permanece fechada e o texto pede que você derrote todos.

Quando o contador `FOES` chega a zero, a porta fica verde e aparece `GATE OPEN - WALK NORTH`. Alinhe o herói com o vão e caminhe para cima. A sala seguinte não é carregada automaticamente ao matar o último inimigo: você precisa chegar à saída.

## Como enfrentar o Guardião

O chefe alterna entre aproximação, preparação da investida, investida e recuperação. A preparação é sinalizada por piscadas e pelo aviso `WARDEN IS CHARGING!`.

Afaste-se durante a preparação. Depois da investida, aproveite `RECOVERING - STRIKE NOW` para voltar ao alcance da espada. Permanecer em contato e só segurar o ataque pode matar o herói antes do chefe.

Derrotar o chefe também libera uma saída. Atravesse-a para ver a tela de vitória. Se os corações acabarem, aparece a tela de derrota; Enter/Start ou X/A reinicia toda a campanha.

## Demonstração

![Campanha real executada no mGBA](evidencias/2026-10-23/gateblade-demo.gif)

O vídeo e o GIF foram capturados da ROM real, com um controlador automatizado fornecendo direções e ataques. Não são uma animação recriada. O percurso completo não altera a memória do jogo para aumentar vida, remover inimigos ou pular salas. O GIF não inclui áudio; a ROM tem efeitos sonoros para espada, dano e abertura de porta.

## Limites desta versão

São quatro salas fixas, sem salvamento, inventário, equipamento, geração procedural ou música. Há pausa e reinício. A validação registrada é em emulador, sem teste em console físico.
