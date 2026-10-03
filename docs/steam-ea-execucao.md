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
