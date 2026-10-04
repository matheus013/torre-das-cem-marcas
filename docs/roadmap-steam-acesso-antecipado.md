# Roadmap: Steam em acesso antecipado

Atualizado em 2026-10-03. Objetivo: uma build paga que entrega um ciclo de jogo
estavel, tem escopo descrito com honestidade e passa pela revisao da Steam.
Este plano complementa o roadmap de MVP; a quantidade de conteudo existente
nao substitui os criterios de qualidade abaixo. Datas de lancamento dependem
de playtests e aprovacoes, nao de estimativas de porcentagem.

## Situacao atual

Implementacao enviada para `origin/main` nos commits `04e03ae` (gameplay,
opcoes, controles, mira e distribuicao) e `eda37f6` (documentacao e QA).

- Suite local: 35 testes aprovados, zero falhas, incluindo CFG/perfil, saves e rede.
- Build macOS de QA regenerada e autoteste do runtime release aprovado nesta entrega.
- Builds release Windows/Linux e macOS de QA geradas sem erros ou avisos.
- Os tres pacotes PCK passaram no autoteste com runtime release macOS.
  Executaveis nativos Windows/Linux ainda nao foram validados em maquinas limpas.
- Opcoes persistentes, pausa solo, remapeamento de teclado, mapeamento inicial
  Xbox/PS4/PS5 e mira automatica opcional implementados.
- Opcoes/controles, perfil e IA com backup e recuperacao; CFG anterior preservado.
- Capturas do titulo e opcoes/controles verificadas em 720p, 1080p e ultrawide.
  Isso ainda nao valida todos os menus e estados de combate nessas resolucoes.
- [CI de testes do commit 7ead65f](https://github.com/matheus013/torre-das-cem-marcas/actions/runs/37171840741):
  concluido com sucesso. Protecao de configuracoes/perfil exige nova execucao.
- Workflow de releases disponivel, mas execucao remota e artefatos baixados
  ainda pendentes. Atualmente dispara manualmente ou em pull requests.

EA1 e EA2 permanecem abertos. Nenhuma build foi enviada para a Steam, e
nenhum marco de QA externo ou aprovacao da Valve foi concluido.

## Escopo de lancamento

- Windows x86_64 e teclado/mouse como alvo inicial.
- Linux x86_64 recebe build e QA; anunciar suporte somente depois de aprovado.
- macOS e usado para QA local, sem promessa de suporte comercial nesta fase.
- Solo completo sem conta, chave de API ou servico externo obrigatorio.
- Co-op de 1 a 4 jogadores anunciado somente apos validacao em redes externas.
- Torre, personagens e sistemas anunciados correspondem a conteudo testado.
- Controle Xbox/PS4/PS5 faz parte do alvo; suporte completo depende de QA fisico.
- Steam Deck, conquistas e Steam Cloud ficam opcionais ate validados.
- IA de moradores e opcional; custos, dados enviados e dependencias devem ser
  esclarecidos antes de expor essa opcao ao comprador.

## Marcos e ordem

| Marco | Entrega | Criterio de saida | Estado |
| --- | --- | --- | --- |
| EA1 | Build reproduzivel | Exports release Windows/Linux, pacote verificado e primeira execucao em Windows limpo | Faltam CI release, QA nativo e migracao do nome |
| EA2 | Experiencia publica | Opcoes persistentes, controles configuraveis, audio essencial, pausa solo e menus legiveis | Faltam audio, acessibilidade e QA externo |
| EA3 | Persistencia e estabilidade | Save atomico, backup, recuperacao, migracao e atualizacao sem perda de progresso | Mundo/recordes/CFG/perfil protegidos; migracao e QA de falhas pendentes |
| EA4 | Solo e co-op confiaveis | Ciclo completo, desempenho medido, desconexoes tratadas e testes externos | Pendente |
| EA5 | Produto e loja | Licencas, creditos, requisitos, midia, descricao e respostas de Early Access | Pendente |
| EA6 | Candidato e Steam | Instalacao via Steam, revisoes aprovadas, prazos cumpridos e plano de suporte | Pendente |

Infraestrutura de EA1 permite avancar EA2 e EA3 enquanto o QA nativo esta
pendente; EA4 valida os tres. Preparacao de loja e onboarding
podem ocorrer em paralelo, mas nenhuma caracteristica deve ser anunciada antes
de sua comprovacao. Problemas que destroem saves ou impedem progresso bloqueiam
qualquer lancamento.

## EA1: distribuicao reproduzivel

- [x] Presets release Windows/Linux com JSON e sprites incluidos.
- [x] Preset macOS exclusivo para QA local.
- [x] Script de build com identificacao do commit, engine e alteracoes locais.
- [x] Fechar acesso a cena dev via argumentos de rede em release.
- [x] Versao central no projeto e exibida no menu.
- [x] Workflow que testa, exporta, verifica o pacote release e guarda artefatos.
- [x] Executar e registrar exports e verificacao do pacote localmente.
- [x] Versionar e enviar a implementacao e o roadmap ao repositorio remoto.
- [x] Confirmar o resultado do CI de testes no GitHub (7ead65f).
- [ ] Executar workflow no GitHub e verificar os artefatos baixados.
- [ ] Testar Windows limpo sem Godot, abertura pelo executavel e partida solo.
- [ ] Definir nome final de application/config/name com migracao de user://.

O nome tecnico atual permanece porque altera-lo muda o diretorio dos saves.
Renomear sem migracao faria o jogador aparentar perder progresso.
O pacote conserva modulos de prototype usados pelo jogo; exclui arte bruta,
documentacao, ferramentas e testes. A ausencia de ferramentas no menu nao
significa que todo codigo interno foi removido.

## EA2: experiencia publica

- [x] Menu de opcoes acessivel no titulo e dentro da partida.
- [x] Tela cheia/janela, resolucao e limite de FPS persistentes.
- [x] Volume geral, musica e efeitos; restaurar padroes.
- [x] Mapear acoes de teclado no InputMap e permitir remapeamento com conflitos tratados.
- [x] Implementar mapeamento inicial de controle, movimento, mira e navegacao.
- [x] Mira automatica opcional no inimigo vivo mais proximo, alternavel na partida.
- [ ] Validar Xbox, DualShock 4 e DualSense por USB/Bluetooth em plataformas alvo.
- [x] Menu de pausa solo; em co-op menus nao prometem pausar o mundo.
- [ ] Sons de dano, habilidades, saque, morte e interface; musica/ambiencia.
- [x] Inspecionar titulo e opcoes/controles em 1280x720, 1920x1080 e ultrawide.
- [ ] Validar todos os menus, HUD e estados de combate nessas resolucoes.
- [ ] Sinais de combate nao dependem somente de cor; ajuste de efeitos intensos.
- [ ] Primeira sessao permite entender entrada, retirada, morte e persistencia.

Saida: jogador externo consegue iniciar, ajustar preferencias, fazer uma
expedicao, retornar e sair sem orientacao verbal. Audio tem licenca registrada.

O suporte de controle atual tem mapeamento padrao e testes simulados. Acoes
de teclado podem ser remapeadas; botoes de controle ainda nao. Entrada de IP
do co-op e configuracao textual dos provedores de IA dependem de teclado.
Nao anunciar Full Controller Support antes de validar esses fluxos e hardware.

Mira automatica: H por padrao (remapeavel), L3 ou opcoes. Prefere sempre o
inimigo vivo mais proximo na mesma zona, recalcula o alvo e usa a mira manual
quando nao ha inimigos. A escolha persiste e pode mudar durante a partida ou pausa.

## EA3: saves e diagnostico

- [x] Auditoria dos arquivos em user:// e politica de versao documentadas.
- [x] Mundo e recordes: escrita via temporario, validacao e backup.
- [x] Recuperacao de arquivo truncado/corrompido e aviso ao jogador.
- [x] Proteger configuracoes/perfil mantendo formato CFG e secoes existentes.
- [x] Recuperar identidade do backup e manter ID temporario estavel em falhas.
- [ ] Testar disco cheio, interrupcao e rename nativos.
- [ ] Migracao de save anterior, sem duplicar itens, moeda ou progressao.
- [ ] Fixture de save real de uma versao anterior para teste de atualizacao.
- [ ] Logs com versao e instrucoes de coleta, sem chaves de API ou dados privados.
- [x] Documentar propriedade atual do progresso co-op e suas limitacoes.
- [ ] Exibir essas limitacoes ao convidado antes de entrar na sessao.

Detalhes, evidencias e riscos: [persistencia-e-recuperacao.md](persistencia-e-recuperacao.md).
Sair pelo menu nao desconecta se o save falhar. Saves de versao futura nao sao
sobrescritos nem substituidos silenciosamente por backup antigo.

Saida: testes de salvar/carregar, interrupcao durante escrita, recuperacao e
atualizacao passam; progresso real sobrevive a troca de build.

## EA4: qualidade do jogo e rede

- [ ] Testar todos os andares, chefes e transicoes anunciados; sem softlocks.
- [ ] Validar cada personagem solo e grupos de 2, 3 e 4 jogadores.
- [ ] Medir FPS e tempo de frame em hardware alvo durante a maior carga.
- [ ] Sessao prolongada de 2 horas, memoria e repeticao de entrar/sair.
- [ ] Desconexao de cliente e host, timeout, IP invalido e servidor cheio.
- [ ] Testar redes externas, latencia e perda de pacotes; registrar limitacoes.
- [ ] Decidir lobbies/relay Steam ou manter IP com limitacoes explicitas na loja.
- [ ] Rodar playtest com pelo menos 10 pessoas externas e 3 grupos de co-op.
- [ ] Resolver todos os bugs criticos/altos e repetir seus casos de reproducao.

Saida: evidencias identificam build, hardware, passos e resultado. Nenhuma
perda de save, crash recorrente ou bloqueio de progresso permanece aberto.
Os numeros de participantes sao metas internas, nao exigencias da Valve.

## EA5: produto e pagina

- [ ] Inventario de origem/licenca para codigo, sprites, fontes e audio.
- [ ] Creditos acessiveis no jogo; incluir avisos exigidos pelas licencas.
- [ ] Revisar uso de IA, direitos dos assets e Content Survey da Steam.
- [ ] Resolver privacidade, custos e fallback dos moradores com IA externa.
- [ ] Nome, descricao curta, idiomas, tags e requisitos medidos.
- [ ] Capturas reais, trailer de gameplay, capsulas e imagens de biblioteca.
- [ ] Respostas de Early Access: por que, estado atual, diferencas previstas,
  duracao estimada, politica de preco e participacao da comunidade.
- [ ] Descrever limitacoes de multiplayer, progresso e saves.
- [ ] Canal de bugs e rotina sustentavel de atualizacoes/changelog.

Saida: loja descreve o valor da build disponivel hoje. Sem promessas de datas
ou recursos futuros como condicao para justificar a compra.

## EA6: candidato, revisao e lancamento

- [ ] Conta Steamworks, dados bancarios/fiscais e taxa por aplicativo.
- [ ] AppID e depots reais; branch privada para candidato e launch options.
- [ ] Instalar e atualizar pelo cliente Steam em maquinas limpas.
- [ ] Revisoes de pagina e build aprovadas; recursos anunciados funcionam.
- [ ] Cumprir espera minima de 30 dias da taxa e 2 semanas de Coming Soon.
- [ ] Checklist final de saves, solo, co-op, creditos, logs e requisitos.
- [ ] Guardar candidato anterior para rollback e instrucoes de recuperacao.
- [ ] Preco e publicacao definidos pelo responsavel da conta.

Saida: evidencias dos marcos EA1-EA5, aprovacao da Valve e operacao de suporte
pronta. Publicar exige acesso a conta e decisao comercial do responsavel.
Steamworks SDK, conquistas e Cloud nao sao obrigatorios para distribuir o jogo;
devem ser integrados quando contribuem para as funcionalidades prometidas.

## Execucao e evidencias

### Proximas entregas

A revisao de 2026-10-03 identificou bonus de equipamento sem efeito, perda
silenciosa por limite de drops e entradas nao finitas aceitas. Estes achados
continuam abertos: completar o [gate G0 de gameplay](roadmap-gameplay-survivors-rpg.md)
antes de ampliar loot ou considerar EA4 concluido. O [diagnostico completo](revisao-projeto-survivors-rpg.md)
separa correcoes necessarias de novas mecanicas ainda propostas. G0 pode
avancar junto de EA3; nao substitui QA nativo, migracao ou revisao da Valve.

1. EA3: obter fixture historica e validar
   atualizacao; migrar a pasta antes de alterar o nome tecnico. Testar falhas
   reais em Windows/Linux e informar propriedade do progresso no co-op.
2. EA2: produzir/integrar audio com origem e licenca registradas, ligado aos
   buses e controles de volume ja implementados.
3. EA2: acessibilidade dos sinais, intensidade de efeitos e revisao dos demais
   menus/HUD; validar primeira sessao sem orientacao verbal.
4. EA1/EA2: executar CI release, baixar artefatos e testar Windows/Linux limpos
   e Xbox/DualShock 4/DualSense por USB/Bluetooth e com Steam Input.
5. EA4: desempenho, estabilidade prolongada e playtests externos solo/co-op.
6. EA5/EA6: loja, licencas, conta Steamworks, depots e revisoes de publicacao.

Esta ordem prioriza progresso salvo com seguranca. Validacoes externas e
onboarding podem acontecer em paralelo; a data de venda permanece indefinida.

### Comandos

Comandos: `sh tests/run_all.sh`, `sh tools/release/build.sh all` e
`sh tools/release/build.sh macos`. Instalar templates oficiais da mesma versao
da engine (4.6.3). `all` gera Windows e Linux, nao macOS.

Validacao do pacote usa um runtime release, nao o editor Godot:
`sh tools/release/check.sh /caminho/absoluto/aresta`.
Executar fora do checkout evita que arquivos locais escondam omissoes do PCK.

Registrar resultados em [registro de execucao](steam-ea-execucao.md).
Usar a [matriz de QA e playtest](steam-ea-playtest.md) para validacao externa.
Cada ciclo encerra tarefas somente com evidencias; dependencias externas ficam
pendentes, sem converter export bem-sucedido em validacao de gameplay.

## Referencias oficiais

- [Early Access](https://partner.steamgames.com/doc/store/earlyaccess)
- [Onboarding e prazos](https://partner.steamgames.com/doc/gettingstarted/onboarding)
- [Revisao](https://partner.steamgames.com/doc/store/review_process)
- [Coming Soon](https://partner.steamgames.com/doc/store/types)
- [Assets de loja](https://partner.steamgames.com/doc/store/assets)
- [Exportacao Godot 4.6](https://docs.godotengine.org/en/4.6/tutorials/editor/command_line_tutorial.html)
