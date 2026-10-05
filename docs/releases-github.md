# Releases publicos no GitHub

Workflow: `.github/workflows/release-build.yml`.

- Push na `main` com mudancas de codigo/conteudo/export/empacotamento gera
  um playtest automaticamente; tambem pode executar em Actions manualmente.
- Pull requests testam e exportam, mas nunca recebem permissao de publicar.
- Ubuntu instala Godot 4.6.3 e templates oficiais, roda a suite completa e
  exporta Windows x86_64, Linux x86_64 e macOS universal Intel/Apple Silicon.
- Pacotes independentes incluem executavel, PCK, instrucoes, engine/commit
  e hashes SHA-256. Tar Linux preserva permissao de execucao.
- Jobs nativos Windows, Linux e macOS extraem os pacotes e verificam o boot
  release fora do checkout. Qualquer falha bloqueia a publicacao.
- Somente o job de publicacao da `main` tem `contents: write`, usando o
  token temporario do GitHub, sem PAT ou credencial pessoal no codigo.
- Tags `playtest-N-T` identificam numero da execucao e tentativa. Downloads
  ficam no GitHub Releases, nao apenas nos artefatos temporarios do Actions.
  Versoes anteriores nao sao sobrescritas nem removidas automaticamente.

Links: [downloads](https://github.com/matheus013/torre-das-cem-marcas/releases),
[workflow](https://github.com/matheus013/torre-das-cem-marcas/actions/workflows/release-build.yml)
e [instrucoes de teste](playtest-publico.md).

Primeira evidencia em 2026-10-04: [playtest-2-1](https://github.com/matheus013/torre-das-cem-marcas/releases/tag/playtest-2-1)
do commit `fdc86a6`, com suite de 43 testes e boot nativo aprovado nos tres
sistemas. Downloads publicos e SHA-256 conferidos apos a publicacao.

Limites: boot headless nao certifica renderizacao, controles fisicos, co-op
externo, saves historicos nem requisitos minimos. Builds nao sao assinadas
com certificados comerciais ou notarizadas; continuam pre-releases gratuitos.
Repositorio publico torna codigo, historico e documentos acessiveis, mas
nenhuma licenca open-source nova foi escolhida pelo responsavel.
