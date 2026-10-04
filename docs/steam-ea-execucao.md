# Registro de execucao: Steam Early Access

## 2026-10-02: EA1

Roadmap definido em `roadmap-steam-acesso-antecipado.md`.
Implementados presets, script de build, versao central, workflow e verificacao
do pacote release. Corrigido encaminhamento de argumentos de rede para a cena
dev em release. O nome tecnico do projeto foi preservado para manter saves.

## Evidencias locais

- Engine: Godot 4.6.3.stable.official.7d41c59c4.
- Exports release Windows x86_64, Linux x86_64 e macOS universal gerados.
- Logs de exportacao sem ERROR ou WARNING.
- Autoteste `RELEASE_PACK_OK` passou no runtime release macOS fora do checkout.
- Pacotes PCK de Windows e Linux tambem passaram no mesmo runtime macOS.
  Isso valida o conteudo desses pacotes, nao executa seus binarios nativos.
- Autoteste verifica roteamento publico, JSONs, sprites, menu e exclusao de
  pastas de ferramentas, testes, documentacao e arte bruta.
- Scripts shell passaram em `sh -n`; diff passou em `git diff --check`.
- Suite completa: 29 testes aprovados, zero falhas, incluindo rede e vila online.

Artefatos ignorados pelo Git: `builds/windows/aresta.exe` e `aresta.pck`,
`builds/linux/aresta.x86_64` e `aresta.pck`, `builds/macos/aresta.zip`.
Cada pasta inclui versao da engine, commit base e lista de alteracoes locais;
as builds representam o checkout com modificacoes, nao um commit limpo.

## Pendencias do EA1

Executar o workflow no GitHub; testar os executaveis nativos em Windows e Linux
limpos; migrar o diretorio dos saves antes de trocar o nome tecnico.
macOS QA nao tem assinatura/notarizacao comercial e nao representa suporte
macOS anunciado na loja.

## Proxima frente executavel

EA2: menu de opcoes persistentes no titulo e partida, InputMap/remapeamento,
pausa solo e audio licenciado. EA3 pode avancar em paralelo com escrita atomica,
backup e recuperacao do save. Usar `steam-ea-playtest.md` para registrar QA.
EA1 permanece em andamento ate suas pendencias terem evidencias.

Publicacao depende de playtests externos, AppID/depots reais, conta Steamworks,
materiais da loja e aprovacao da Valve. Nenhuma publicacao ou upload foi feito.

## 2026-10-02: EA2, primeira entrega

Menu de opcoes incluido no titulo e na partida. Preferencias de tela cheia,
resolucao da janela, FPS, VSync e volumes sao carregadas no boot e persistem
no arquivo ja utilizado pelo modo dev, preservando sua secao de configuracao.
Valores invalidos sao normalizados; erros de gravacao ficam visiveis e nao
alteram as opcoes em uso. Restaurar padroes modifica a selecao pendente e
somente Aplicar grava a configuracao.

Esc abre o painel em vez de abandonar a sessao. No solo, a arvore pausa e
retoma quando o painel fecha; no host/cliente, a simulacao continua enquanto
as entradas de gameplay ficam bloqueadas pelo painel. Voltar ao menu usa o
fluxo existente de salvamento do host e encerramento da sessao.

Validacao: suite completa com 30 testes aprovados e zero falhas; teste dedicado
tambem executado com renderizacao OpenGL no macOS. Cobertura de validacao,
round-trip em disco, preservacao do modo dev, buses de audio, aplicacao pelo
painel, falha de gravacao, pausa solo, continuidade online e liberacao da
pausa ao destruir a cena. Capturas em 1280x720, 1920x1080 e 2560x1080 geradas
por `tools/release/settings_preview.gd` e inspecionadas.

Builds Windows/Linux/macOS atualizadas sem erros ou avisos na exportacao.
Os tres PCKs passaram novamente em `RELEASE_PACK_OK` com runtime release macOS;
executaveis Windows/Linux
ainda dependem de QA nativo. Controles de volume configuram buses Master,
Music e Effects; a producao dos sons e a trilha licenciada permanecem pendentes.

EA2 continua em andamento: falta audio de gameplay,
acessibilidade dos sinais e validacao externa da primeira sessao.

## EA2: remapeamento de teclado

Implementadas 18 acoes configuraveis no InputMap para movimento, gemas, item
rapido, conversa, menus, troca de personagem, salvar/carregar e modo dos
moradores. A aba Controles permite capturar uma tecla por acao, cancelar a
captura com Esc, restaurar padroes e aplicar em conjunto com as demais opcoes.
O arquivo preserva preferencias de video/audio e de desenvolvimento.

Conflitos sao rejeitados quando as acoes compartilham contexto; conversar e
usar gema podem continuar na mesma tecla por ocorrerem em zonas diferentes.
Esc e atalhos de desenvolvimento ficam reservados; combinacoes de modificadores
e remapeamento do mouse nao fazem parte desta entrega. O movimento com
botao direito permanece funcional. Configuracoes de teclas invalidas recuperam
os padroes. HUD, menus de gemas e dicas exibem as teclas ativas.

Validacao: 31 testes da suite aprovados, incluindo rede e vila online. Teste
dedicado cobre conflitos por contexto, configuracao invalida, captura/cancelamento,
aplicacao e persistencia, movimento e despacho real de menu/gema. Capturas da
aba Controles em 720p, 1080p e ultrawide inspecionadas. Captura tambem validada
pela entrada real da Window (`push_input`), alem das chamadas de teste.
Exports atualizados sem erros/avisos; os tres PCKs passaram em
`RELEASE_PACK_OK` com runtime release macOS.
teste nativo Windows/Linux e playtests externos permanecem pendentes.

## EA2: controle e mira automatica

Escopo atualizado pelo usuario para incluir controles Xbox, PS4 e PS5 e mira
automatica opcional. InputMap recebe botoes normalizados, movimento pelo
analogico esquerdo, mira pelo direito e gatilho direito para item rapido.
Menus recebem foco, confirmacao/cancelamento e navegacao por direcional/analogico.
Start/Options abre e fecha a pausa; salvar/carregar e modo dos moradores estao
na aba Sessao, com comandos de autoridade indisponiveis para clientes.

Mira automatica alterna pela acao configuravel (H por padrao), L3 e opcoes.
Seleciona o inimigo vivo mais proximo na mesma zona a cada consulta; sem alvo,
mantem a mira manual. A preferencia persiste, inclusive quando alternada na
janela de pausa. Nao altera a selecao de alvos dos ataques basicos automaticos
da simulacao; modifica o alvo enviado pelas gemas ativas.

Reticula de mira no mundo, indicacoes Xbox/PlayStation de acordo com o dispositivo
reconhecido e retorno ao teclado/mouse apos desconectar incluidos. Zona morta
de analogicos em 0.25; gatilhos nao repetem comandos enquanto permanecem pressionados.
Controle fora da janela em foco nao envia comandos de gameplay.

Testes simulam botoes/eixos e verificam foco, menus, pausa, persistencia, mira
manual/automatica, troca do inimigo mais proximo, fallback sem inimigos e
desconexao. Isso nao comprova conexao USB/Bluetooth de hardware real. Nao
anunciar Full Controller Support nem Steam Deck antes de validar os fluxos
fisicos e a entrada de IP/texto. Remapeamento de botoes do controle permanece
uma melhoria futura; esta entrega remapeia o teclado e fornece padrao de controle.

Referencia: https://docs.godotengine.org/en/4.6/tutorials/inputs/controllers_gamepads_joysticks.html

Suite final: 32 testes aprovados, zero falhas. Capturas das opcoes/controles
inspecionadas em 720p, 1080p e ultrawide. Builds finais de Windows/Linux/macOS
geradas sem erros ou avisos. Validacao dos tres PCKs usa runtime release macOS;
QA nativo Windows/Linux e hardware de controle permanece pendente.

## Atualizacao do roadmap e repositorio

Implementacao enviada a `origin/main`: `04e03ae`. Documentacao enviada:
`eda37f6`. Roadmap atualizado com o resumo das entregas, separacao entre
capturas verificadas e QA completo, limitacoes atuais de controle e proxima
frente de persistencia segura, seguida por audio e acessibilidade.

O workflow Testes de `2de4a01` foi confirmado como concluido com sucesso:
https://github.com/matheus013/torre-das-cem-marcas/actions/runs/37088943958.
O workflow de releases ainda precisa de execucao remota e verificacao dos
artefatos. Resultado local de 32 testes nao substitui confirmacao do CI.

## EA3: primeira entrega de persistencia (2026-10-03)

Mundo e recordes usam gravacao temporaria validada, backup e recuperacao.
Estruturas conhecidas sao validadas antes de restaurar o mundo. Backup nao
e carregado silenciosamente quando o principal tem versao futura; a build
antiga tambem nao sobrescreve esse arquivo. Falha ao salvar no retorno ao menu
mantem a sessao aberta. Clientes continuam sem acesso a save/load do host.

Auditoria de user://, politica de versao, propriedade co-op, testes e limites
registrados em `persistencia-e-recuperacao.md`. Configuracoes/perfil, fixture
historica, migracao de pasta e QA nativo de falhas continuam pendentes.

Validacao local desta entrega: 34 testes aprovados, zero falhas, incluindo
rede/vila online e os dois novos testes de persistencia. Export macOS de QA
regenerado e autoteste release executado fora do checkout aprovado. Nao foi
repetido QA nativo Windows/Linux; o novo CI sera disparado pelo push.

## EA3: configuracoes e identidade (2026-10-03)

CFG preservado e gravacao/backup compartilhados com saves via `atomic_file.gd`.
Opcoes, controles, modo dev e IA preservam secoes existentes. Opcoes avisam
recuperacao no dialogo; falhas de IA nao alteram o modo nem anunciam sucesso.
Perfil recupera o mesmo ID do backup; falha irrecuperavel usa ID temporario
estavel no processo, sem sobrescrever evidencia. Valores malformados de IA
usam defaults, e campos fora da whitelist nao entram em novas gravacoes.

Testes dev isolados revelaram falha de prioridade em `boot_scene`: `--public`
agora retorna explicitamente a cena publica, independente da preferencia local.
CI de `7ead65f` confirmado aprovado:
https://github.com/matheus013/torre-das-cem-marcas/actions/runs/37171840741.

Continuam pendentes fixture historica autentica, migracao de pasta, QA nativo
de falhas e comunicacao do progresso co-op ao convidado. CFG parcialmente
truncado mas ainda sintaticamente valido nao tem deteccao por checksum.

Validacao final: 35 testes aprovados, zero falhas, incluindo rede e controles.
Build macOS de QA regenerada sem erros/avisos de export e autoteste release
fora do checkout aprovado. Erros de parse nos testes de CFG sao esperados
para fixtures corrompidas; nenhum SCRIPT ERROR foi aceito pela suite.

## Gameplay: pausa e escolhas nos marcos (2026-10-04)

Pedido do responsavel: ao atingir os niveis de marco, pausar e abrir as
escolhas na tela, como no fluxo de evolucao de um survivors. Implementado
para os marcos permanentes 10-100, usando as seis escolhas ja existentes.
Niveis comuns continuam concedendo pontos sem interrupcao.

A pausa e derivada das escolhas pendentes dos jogadores conectados no host;
nao pausa a arvore de rede. Movimento, habilidades, consumiveis e timers da
simulacao ficam congelados. Confirmacao passa pelo host; invalida nao retoma.
Todos com marco pendente devem escolher; os demais veem espera. Desconectar
retira o jogador da barreira, sem perder a escolha. Save/reentrada e XP
acumulado retomam o fluxo correspondente, inclusive varios marcos seguidos.

Tela em camada independente do HUD escalado, com duas colunas no desktop e
uma coluna rolavel em janela estreita. Foco inicial, navegue/confirmacao pelos
eventos normalizados de controle, sem cancelar uma escolha obrigatoria.
O agente de teste escolhe marco antes de distribuir pontos, respeitando a
nova barreira autoritativa.

Validacao: suite completa com 36 testes aprovados, zero falhas, incluindo rede
e vila online. Teste de marco ampliado e repetido isoladamente para espera e
retomada dirigidas por snapshot sem simulador local. Cobertura de marcos ate
100, perfil reservado/reconexao, save/reload, XP acumulado e eventos de D-pad/A.
Capturas renderizadas locais em 1280x720 e 640x720 revisadas. Export macOS de
QA e autoteste release fora do checkout aprovados; execucao fisica de controles
e QA Windows/Linux permanecem pendentes. Este teste nao prova a nova pausa
numa sessao remota real com latencia; os smokes de rede validam o fluxo geral.

Roadmap e GDD atualizados. Marcas temporarias de Expedicao, itemizacao e
correcoes G0 continuam separadas e pendentes.
