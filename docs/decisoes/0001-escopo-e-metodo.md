# 0001 — Escopo inicial e método de documentação

**Data:** 23 de outubro de 2026.

**Estado:** adotado como ponto de partida; escolhas futuras podem revisar este registro por meio de uma nova decisão.

## Contexto

Alan propôs desenvolver um jogo com apoio de IA e usar a experiência como base para um artigo passo a passo no site pessoal. A proposta menciona Game Boy e depois Game Boy Advance, além de exigir assembly puro e documentação das decisões e mudanças. Em seguida, Alan solicitou que o projeto pudesse ser compartilhado publicamente no GitHub.

## Decisões

1. Criar `gba-assembly-ai` como projeto independente, na mesma pasta de projetos do site.
2. Usar **Game Boy Advance** como alvo inicial, por ser o console especificado por último na proposta. Não implementar dois alvos simultaneamente nesta primeira etapa.
3. Entender **assembly puro** como código próprio executado no console escrito em assembly, inclusive a inicialização necessária. Não introduzir código C/C++, runtime C ou engine como implementação do jogo. Ferramentas no computador podem usar outras linguagens. O eventual uso de chamadas da BIOS e utilitários auxiliares será documentado quando decidido.
4. Usar IA como apoio à pesquisa, explicação, implementação e depuração, registrando a revisão e os testes das sugestões relevantes. Isso não estabelece um recurso de IA dentro do jogo.
5. Documentar o desenvolvimento enquanto acontece. O diário preserva a sequência real; decisões registram alternativas e consequências; evidências sustentam os resultados.
6. Preparar e publicar um repositório público no GitHub. Isso é separado da futura publicação do artigo no site.

## Fundamentos técnicos

O GBA usa ARM7TDMI, conforme o [Tonc](https://gbadev.net/tonc/hardware.html). A [Arm identifica ARM7TDMI como Armv4T](https://developer.arm.com/community/arm-community-blogs/b/architectures-and-processors-blog/posts/arm-fundamentals-introduction-to-understanding-arm-processors). A seleção de instruções e ferramentas deve respeitar esse alvo. A documentação do [GNU assembler](https://sourceware.org/binutils/docs/as/ARM-Options.html) descreve a seleção de processador por `-mcpu=`; o comando específico do projeto ainda não foi validado.

## Alternativas consideradas

- **Começar pelo Game Boy original:** exigiria outro recorte técnico. O escopo adotado acompanha a menção explícita ao GBA e pode ser revisado se o objetivo mudar.
- **Usar C/C++ ou uma engine:** poderia alterar o esforço de implementação, mas não corresponde ao requisito inicial de assembly puro. Nenhuma comparação de produtividade foi medida.
- **Manter o jogo dentro do site:** misturaria a experiência de desenvolvimento com sua futura publicação. Projetos independentes permitem compartilhar o material sem depender do site.
- **Documentar apenas no fim:** perderia contexto das tentativas e correções, justamente o material necessário ao artigo.

## Consequências

Inicialização, memória, registradores, construção da ROM e validação terão espaço explícito no desenvolvimento e no texto. O gênero do jogo, a toolchain, o emulador efetivamente utilizado, a licença e o idioma do artigo continuam em aberto.

Esta decisão estabelece o método e o escopo. Ainda não comprova que uma ROM foi construída ou executada.
