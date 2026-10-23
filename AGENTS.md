# Instruções do projeto

Estas instruções se aplicam a todo este repositório.

## Objetivo e escopo

- Desenvolver um jogo de Game Boy Advance com código executável próprio em assembly, incluindo a inicialização que vier a ser necessária.
- Usar IA para apoiar o desenvolvimento e registrar como suas sugestões foram avaliadas e corrigidas.
- Manter o projeto independente do site pessoal. A redação final e a integração do artigo no site pertencem a etapas posteriores.
- Escrever notas de desenvolvimento em português. O idioma final do artigo ainda está em aberto.

## Documentação durante o desenvolvimento

- Antes de uma mudança significativa, leia `README.md`, `docs/plano.md` e os registros de decisão pertinentes.
- Ao concluir uma mudança significativa, crie ou atualize uma entrada em `docs/diario/`, usando o modelo de sessão. Agrupe ajustes triviais na mesma sessão.
- Registre motivo, arquivos alterados, comandos realmente executados, resultado observado, erros encontrados e próximos passos.
- Para escolhas de arquitetura, formato de ROM, ferramentas ou convenções de assembly, registre alternativas e consequências em `docs/decisoes/`. Use numeração sequencial e o modelo de decisão.
- Preserve tentativas que falharam e explique a correção. Não reescreva o histórico como se a primeira proposta já estivesse correta.
- Identifique separadamente: proposta, decisão adotada, informação de referência e resultado validado localmente.
- Registre as contribuições relevantes da IA: pedido ou contexto, sugestão, revisão humana e resultado. Só informe modelo ou versão se houver confirmação; não copie conversas inteiras sem necessidade.

## Verificação técnica

- Use documentação da arquitetura, das ferramentas e referências mantidas por seus autores. Registre os links e a data de consulta.
- Verifique a compatibilidade com ARM7TDMI/Armv4T ao avaliar instruções e opções de ferramentas.
- Não trate montagem bem-sucedida como prova de funcionamento do jogo. Distinga montagem, linkedição, geração da ROM, execução no emulador e teste em hardware.
- Quando houver ROM, registre os comandos de construção, versões das ferramentas e identificação do artefato validado. Capture resultados relevantes em `docs/evidencias/`.
- Execute as verificações adequadas à mudança. Não declare suporte a sistemas, emuladores ou hardware que não foram testados.

## Repositório público

- Mantenha exemplos e instruções reproduzíveis sem caminhos pessoais absolutos, credenciais ou dependência de arquivos privados.
- Identifique a origem de recursos e trechos de terceiros antes de incorporá-los. A licença do projeto ainda está em aberto.
- Guarde resultados temporários de construção em `build/` ou `dist/`.
- Não invente desempenho, prazos, economia de tempo ou capacidade da IA. Afirmações do artigo devem apontar para evidência ou fonte.
