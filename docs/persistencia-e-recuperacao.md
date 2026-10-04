# Persistencia e recuperacao

Auditoria em 2026-10-03. Mundo, recordes, configuracoes e perfil protegidos;
migracao historica e QA nativo ainda impedem encerrar EA3.

## Arquivos em user://

| Arquivo | Responsavel e conteudo | Protecao atual |
| --- | --- | --- |
| aresta_prototype_save.json | Solo/host: mundo, inventarios das personagens, progressao e estado do jogador host | Temporario, validacao, backup e recuperacao |
| aresta_floor_records.json | Solo/host: tempos por andar e tamanho de grupo | Temporario, validacao, backup e recuperacao |
| aresta_settings.cfg | Opcoes, teclado, mira automatica e preferencia dev | Temporario, backup, recuperacao e preservacao de secoes |
| aresta_profile.cfg | Identidade local usada para reconexao | Temporario, backup e validacao do ID |
| aresta_npc_ai.cfg | Preferencias opcionais de IA, sem gravar chave de API | Temporario, backup, recuperacao e whitelist de campos |
| aresta_dev_content.json | Conteudo do editor de desenvolvimento | JSON direto; fora do fluxo publico |

Logs do motor e arquivos de testes nao sao progresso. Nao enviar a pasta inteira
para suporte sem revisar dados privados. O nome tecnico do projeto ainda define
a pasta; nao renomear antes de implementar migracao de diretorio.

## Gravacao e recuperacao

`atomic_file.gd`, usado por JSON e ConfigFile, pressupoe um unico escritor:
duas instancias na mesma pasta de
usuario nao podem salvar simultaneamente. Steam Cloud ainda nao esta integrado.

1. Valida dados e le o arquivo anterior sem modifica-lo.
2. Grava `.tmp`, faz flush, fecha e rele para validar o JSON.
3. Grava e valida `.bak.tmp`, depois substitui `.bak` pelo save anterior valido.
   Na primeira gravacao, o backup recebe o novo save.
4. Substitui o principal por rename no mesmo diretorio, sem apaga-lo antes.

Falhas retornam erro; principal nao e aberto para escrita direta. Um principal
corrompido nao substitui backup valido. Temporarios abandonados nao sao promovidos
no carregamento. Se o principal estiver ausente, truncado ou estruturalmente
invalido, carrega `.bak` e informa recuperacao no jogo. O principal corrompido
fica intacto ate a proxima gravacao solicitada; o backup pode perder o progresso
da ultima gravacao. Sem backup valido, o mundo atual permanece inalterado.

Voltar ao menu salva antes de desconectar. Se falhar, mantem a sessao e exibe
erro. Fechar pelo sistema operacional ainda nao garante autosave.

## Configuracoes e identidade

O formato `.cfg` anterior continua legivel, sem conversao de pasta. Atualizacoes
preservam secoes desconhecidas e as preferencias dos outros consumidores do
mesmo arquivo. Opcoes e teclado leem o mesmo backup; o dialogo avisa quando
houve recuperacao. Modo dev e IA tambem usam gravacao protegida. Falha ao salvar
IA mantem o modo em uso e aparece na UI, sem anunciar sucesso.

Sem configuracao recuperavel, leitores usam defaults e escritores recusam
sobrescrever o arquivo corrompido. O perfil exige ID textual nao vazio; recupera
o mesmo ID pelo backup. Sem perfil recuperavel ou sem permissao para gravar,
gera identidade temporaria estavel durante o processo e avisa nos logs. A
identidade temporaria nao recupera a reserva/progresso do ID perdido e pode
mudar apos reiniciar. O perfil antigo nao e substituido silenciosamente.

ConfigFile valida sintaxe; opcoes/teclado/IA mantem sanitizacao de valores.
Um truncamento que ainda forme um `.cfg` sintaticamente valido pode ser lido
como parcial, com defaults para chaves ausentes: nao ha checksum/completude.
Diagnosticos de parse sao emitidos pelo motor. Preferencias de IA persistem
somente campos conhecidos; chave de API nao e incluida em novas gravacoes.

## Versoes e co-op

Formato atual: `WorldSimulation.SAVE_VERSION = 7`. Versoes 1 a 7 usam os defaults
e a conversao de inventario legado existentes. Tipos de campos consumidos pelo
restauro sao verificados antes de mutar a simulacao; isso nao e uma validacao
semantica completa de todo inimigo/conteudo. Versao maior que 7 nao carrega
backup mais antigo nem permite sobrescrita por esta build.

Os testes que trocam apenas o numero de versao sao sinteticos: nao comprovam
migracao de um save historico real. Ainda falta fixture autentica e prova de
atualizacao sem duplicar moeda, itens ou progressao.

Clientes nao gravam/carregam o mundo. O host possui o arquivo de mundo e o
estado persistente das personagens; posicao e recursos locais salvos pertencem
ao jogador host. Carregar nao remove os peers conectados. Nao ha portabilidade
de progresso individual do convidado para outro host nesta entrega.

## Evidencias e limites

`tests/json_store_test.gd`: rotacao, primeira gravacao, recuperacao, temporario
abandonado, arquivos invalidos, falhas induzidas de abertura, protecao de versao
futura e rejeicao sem mutacao do mundo. `tests/world_persistence_test.gd`:
recuperacao na cena, aviso visivel no estado da UI, protecao de clientes e recordes.
O smoke test existente verifica equipamentos, gemas e progressao apos salvar.
`tests/config_persistence_test.gd`: compatibilidade com CFG anterior, secoes
preservadas, recuperacao de controles/mira com aviso, falhas de escrita,
recuperacao de identidade, ID temporario estavel e exclusao de campos secretos.
Testes dev agora usam arquivo isolado, sem alterar preferencias do jogador.

Flush e rename nao substituem prova de queda de energia nem garantem durabilidade
fisica em qualquer filesystem. Pendentes: matar processo entre etapas, disco
cheio real, permissao negada, falha de rename, Windows/Linux nativos, concorrencia,
migracao de pasta e troca de build com save historico.
