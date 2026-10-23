# Plano de desenvolvimento

Atualizado em 23 de outubro de 2026. A proposta inicial evoluiu para a primeira versão jogável de Gateblade; a mecânica foi especificada pelo usuário antes da implementação.

## Entregas concluídas localmente

- [x] Projeto separado do site e repositório público no GitHub.
- [x] Diário, decisões, referências e organização de evidências.
- [x] Toolchain GNU Binutils para ARM7TDMI e geração de ROM.
- [x] Cabeçalho de cartucho e startup próprios, sem runtime C.
- [x] Cenário por tiles, sprites e gráficos originais gerados por script.
- [x] Movimento, limites da sala e ataque de espada direcional.
- [x] Dano, vida, invulnerabilidade e reinício após derrota.
- [x] Três salas de inimigos comuns e portas condicionadas à eliminação de todos.
- [x] Chefe com preparação, investida e recuperação.
- [x] Travessia da última saída, vitória e nova campanha.
- [x] Pausa e efeitos sonoros de ações.
- [x] Nove grupos de teste na ROM real, incluindo campanha por botões sem escrita de estado.
- [x] Demonstração capturada da ROM e roteiro de reprodução.
- [x] Artigo completo em português, sujeito à revisão editorial do autor.

## Distribuição e verificação remota

A ROM e o SHA-256 são preparados por `make package`. O workflow de GitHub Actions executa construção e testes. O diário registra a publicação e o resultado remoto observado; não se infere sucesso apenas da existência do workflow.

## Próximos passos opcionais

- Testar em console físico e registrar o equipamento e a ROM utilizados.
- Fazer testes com jogadores e ajustar dificuldade a partir das observações.
- Definir licença de reutilização do código e da documentação.
- Refatorar configuração de encontros antes de aumentar o número de salas.
- Adicionar obstáculos com colisão, padrões novos, música ou mais variedade visual.
- Revisar o artigo e adaptar caminhos de imagens e título para a publicação no blog.

O jogo, a ROM e o texto permanecem independentes do repositório do site. Nenhum artigo foi integrado ou publicado no blog durante esta implementação.
