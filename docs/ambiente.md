# Ambiente de desenvolvimento

Levantamento realizado em 23 de outubro de 2026. Este documento registra a situação encontrada; ainda não é um guia de instalação validado.

## Computador verificado

| Item | Resultado observado |
| --- | --- |
| Sistema | macOS 15.6, build 24G84 |
| Arquitetura do sistema | arm64; Darwin 24.6.0 |
| Make | GNU Make 3.81 |
| Git | 2.39.3, Apple Git-145 |
| Python | 3.11.5 |
| Clang | Apple clang 15.0.0; alvo padrão `arm64-apple-darwin24.6.0` |
| Homebrew | Comando localizado; versão não levantada nesta etapa |
| GitHub CLI | Comando disponível; acesso à conta pública do mantenedor verificado |

Comandos usados no levantamento:

```sh
uname -srm
sw_vers
make --version
git --version
python3 --version
clang --version
command -v make clang xcrun brew gh
command -v arm-none-eabi-as arm-none-eabi-ld arm-none-eabi-objcopy mgba rgbasm
```

`command -v` retorna um código diferente de zero se não localizar algum dos comandos. A presença de ferramentas Apple para o computador não comprova uma toolchain de GBA funcionando.

## Ferramentas ainda não validadas

Os comandos `arm-none-eabi-as`, `arm-none-eabi-ld`, `arm-none-eabi-objcopy`, `mgba` e `rgbasm` não foram encontrados no PATH da sessão. Também não foram encontrados `/opt/devkitpro`, `/Applications/mGBA.app` ou `/Applications/SameBoy.app`. Isso não exclui uma instalação em outro local.

Nenhuma toolchain ou aplicação de emulação foi instalada durante a fundação do projeto.

## Caminho a avaliar

- Assembler, linker e utilitários de binário para o alvo ARM7TDMI; devkitARM é uma opção a investigar.
- Ferramenta ou procedimento verificável para o cabeçalho da ROM.
- mGBA como primeiro emulador. A página oficial oferece distribuição para macOS, mas a execução local ainda não foi testada.
- Make para descrever a construção, caso seja adequado após validar as ferramentas.

As fontes estão em [referências técnicas](referencias.md). As páginas da wiki do devkitPro retornaram HTTP 403 durante a consulta inicial; o procedimento de instalação permanece pendente.

## O que registrar após a instalação

Origem e versão de cada componente, comandos realmente executados, configuração necessária, formato dos arquivos gerados, modo de execução do emulador e problemas encontrados. Só acrescentar instruções para outros sistemas depois de testá-las ou identificá-las claramente como instruções da fonte ainda não verificadas pelo projeto.
