# Plano de desenvolvimento

Atualizado em 23 de outubro de 2026. As etapas abaixo são uma proposta de execução; somente a fundação documental está concluída.

## 0. Fundação — concluída

- [x] Separar o projeto do site pessoal.
- [x] Registrar o objetivo, o alvo inicial e o significado de assembly puro.
- [x] Preparar diário, decisões, evidências e roteiro do artigo.
- [x] Levantar o ambiente local e consultar referências iniciais.
- [x] Publicar e verificar o repositório público no GitHub.

## 1. Ambiente reproduzível — pendente

Avaliar ferramentas GNU para ARM, inclusive a distribuição devkitARM, e o mGBA como emulador inicial. A escolha e o procedimento de instalação ainda precisam ser validados neste computador.

**Critério de conclusão:** registrar origem e versões das ferramentas, executar assembler, linker e conversor de binário e documentar como abrir uma ROM no emulador. Verificar a forma de preparar e validar o cabeçalho do cartucho. Não criar um tutorial de instalação a partir de comandos não testados.

## 2. Primeira ROM visual — pendente

Preparar cabeçalho, ponto de entrada, inicialização necessária, script de linkedição e geração do arquivo `.gba`. Como experimento inicial, considerar um preenchimento de tela ou uma pequena figura em modo bitmap. A escolha do modo de vídeo ainda é uma proposta.

**Critério de conclusão:** reconstruir a ROM, inspecionar o resultado e observar no emulador a imagem esperada. Preservar os comandos, a identificação da ROM e uma captura. Registrar o que foi necessário para a inicialização, sem esconder isso em um runtime C.

## 3. Entrada e atualização de tela — pendente

Ler botões, definir uma atualização ligada ao quadro de vídeo e mover um elemento na tela. Investigar e documentar sincronização e limites de memória conforme forem necessários.

**Critério de conclusão:** interação observável, comportamento previsível nos limites da tela e explicação das rotinas em assembly usadas nessa etapa.

## 4. Jogo mínimo — pendente

Escolher uma mecânica pequena que permita demonstrar objetivo, controle, condição de fim e reinício. Gênero, nome, arte, áudio, pontuação e uso de sprites ainda não foram definidos.

**Critério de conclusão:** uma partida curta completa, com os controles e as limitações documentados. Separar o que foi testado em emulador de eventual teste em console físico.

## 5. Reprodução e artigo — pendente

Refazer o caminho com as instruções documentadas, revisar a origem dos recursos, escolher a licença e escrever o artigo a partir do diário e das decisões.

**Critério de conclusão:** cada afirmação técnica e cada resultado descrito têm referência ou evidência; os comandos correspondem ao projeto publicado; as melhorias propostas aparecem como trabalho futuro. A integração no site ocorre depois da redação e revisão.

## Escolhas ainda em aberto

Toolchain e versões; sintaxe e organização dos arquivos; preparação do cabeçalho; uso de chamadas da BIOS; modo de vídeo; convenções de registradores e pilha; mecânica do jogo; recursos visuais e áudio; licença; idioma e extensão do artigo.
