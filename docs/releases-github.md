# Releases publicos no GitHub

Workflow: `.github/workflows/release-build.yml`.

- Push na `main` com mudancas de codigo/conteudo/export/empacotamento calcula
  a proxima versao com semantic-release; tambem pode executar Actions manualmente.
- Pull requests testam e exportam, mas nunca recebem permissao de publicar.
- Ubuntu instala Godot 4.6.3 e templates oficiais, roda a suite completa e
  exporta Windows x86_64, Linux x86_64 e macOS universal Intel/Apple Silicon.
- Pacotes independentes incluem executavel, PCK, instrucoes, engine/commit
  e hashes SHA-256. Tar Linux preserva permissao de execucao.
- Jobs nativos Windows, Linux e macOS extraem os pacotes e verificam o boot
  release fora do checkout. Qualquer falha bloqueia a publicacao.
- Somente os jobs de planejamento/publicacao da `main` tem `contents: write`, usando o
  token temporario do GitHub, sem PAT ou credencial pessoal no codigo.
- Tags `vX.Y.Z` identificam versoes SemVer. Downloads ficam no GitHub Releases,
  nao apenas nos artefatos temporarios do Actions. Todos continuam marcados
  como pre-release de playtest. Versoes anteriores nao sao sobrescritas.

## Versoes e changelog

- `feat: ...` aumenta MINOR; `fix: ...` e `perf: ...` aumentam PATCH.
- `ci: ...` e `build: ...` aumentam PATCH para entregar ajustes de distribuicao.
- `feat!: ...` ou rodape `BREAKING CHANGE: ...` aumenta MAJOR.
- `docs: ...`, `test: ...`, `chore: ...` isolados nao publicam nova versao.
- O maior incremento entre os commits desde a ultima tag prevalece.
- A base `v0.1.0` aponta para o commit do antigo `playtest-2-1`, preservado.
- O job de planejamento nao cria tags: gera versao, notas e manifesto usados
  na exportacao. O menu le `VERSION`; todos os runners conferem essa versao.
- Apos testes, o bot grava apenas `VERSION` e `CHANGELOG.md` em um commit
  `chore(release): X.Y.Z [skip ci]`, evitando ciclos infinitos, e cria a tag.
  O manifesto registra o commit de gameplay realmente exportado/testado;
  o commit da tag adiciona somente a documentacao da versao.
- Publicacao exige que plano, commit e versao dos downloads coincidam.
  Pacotes incluem changelog, manifesto, versao e hashes; nenhum pacote npm
  e publicado. Reexecutar sem novos commits publicaveis nao aumenta a versao.
- Atualize seu checkout depois da publicacao (`git pull --ff-only`). Use
  Conventional Commits tambem no titulo de squash de pull requests.

Validacao local da automacao: `npm ci --ignore-scripts` e
`npm run test:release` (Node 24.10+). Essas dependencias sao ferramentas de CI,
nao requisitos para jogar e nao entram no PCK. `npm run release:plan` gera
uma previa e pode atualizar o changelog local; use em checkout descartavel.

## Dependencias e seguranca

Dependabot acompanha npm e Actions semanalmente, sem merge automatico.
Em 2026-10-04, `npm audit` reportou 13 alertas transitivos nas ferramentas
(12 altos, 1 moderado), incluindo [braces sem correcao publicada](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm).
Nao foram ocultados nem considerados resolvidos. Padroes glob sao fixos,
instalacao usa `--ignore-scripts`, PRs nao publicam e jobs tem timeout.
Plugins de publicacao npm nao sao executados; dependencias de CI sao excluidas
dos jogos. Correcoes upstream ainda precisam de revisao e atualizacao.

Links: [downloads](https://github.com/matheus013/torre-das-cem-marcas/releases),
[workflow](https://github.com/matheus013/torre-das-cem-marcas/actions/workflows/release-build.yml)
e [instrucoes de teste](playtest-publico.md).

Primeira evidencia em 2026-10-04: [playtest-2-1](https://github.com/matheus013/torre-das-cem-marcas/releases/tag/playtest-2-1)
do commit `fdc86a6`, com suite de 43 testes e boot nativo aprovado nos tres
sistemas. Downloads publicos e SHA-256 conferidos apos a publicacao.

Primeiro SemVer automatizado: [v0.2.0](https://github.com/matheus013/torre-das-cem-marcas/releases/tag/v0.2.0)
do commit `9f9f8a8`, [execucao aprovada](https://github.com/matheus013/torre-das-cem-marcas/actions/runs/37251188513).
44 testes do jogo, 11 da automacao e versao 0.2.0 confirmada no runtime dos
tres sistemas. Commit documental/tag `dfd241d`, sete hashes conferidos e
downloads publicos sem login verificados.

Limites: boot headless nao certifica renderizacao, controles fisicos, co-op
externo, saves historicos nem requisitos minimos. Builds nao sao assinadas
com certificados comerciais ou notarizadas; continuam pre-releases gratuitos.
Repositorio publico torna codigo, historico e documentos acessiveis, mas
nenhuma licenca open-source nova foi escolhida pelo responsavel.
