# Integracao da lore: auditoria N0

Auditado em 2026-10-07 no checkout local. Escopo: Renovacao Antecipada,
Aresta e andares 1 a 4. Resultado: mapa de reutilizacao, lacunas e conflitos.
Esta auditoria nao implementa narrativa nem aprova alteracoes do canone.

## Referencias

- [Recorte](game-design/57-recorte-vertical.md), fonte da sequencia e custodia.
- [Regiao 1](game-design/28-regiao-1-galerias-refeitas.md), fonte regional.
- [Ultimo Lastro](game-design/60-expedicao-do-ultimo-lastro.md), verdade do objeto.
- [Interface](game-design/62-experiencia-interface-e-camera.md), fluxo e diario.
- [Co-op vigente](game-design/63-cooperativo-online-e-combate-de-hordas.md).
- [Geracoes](game-design/55-roguelike-geracional-e-reencarnacao.md).
- [Roteiro de gatilhos](lore-roteiro-renovacao-antecipada.md).

## NPCs e locais existentes

IDs confirmados em `data/village/village_content.json`. Locais confirmados
em `src/gameplay/world/village_plan.gd`, via `spots()["work"]`.
Os papéis abaixo indicam destino de implementacao, nao novas falas prontas.

| Papel narrativo | ID real | Local de trabalho | Base atual | Lacuna / marco |
| --- | --- | --- | --- | --- |
| Crise e autonomia de Aresta | `alda_serrin` | `conselho` | Regente fixa, conversa | Abertura contextual; N2 |
| Contrato, preparacao e relatorio | `nara_quiral` | `expedicoes` | Diretora circulante, conversa | Missao/relatorio estruturados; N1/N2/N5 |
| Recipiente Ferral e custodia | `dalia_ferral` | `forja` | Atendimento de reparo, conversa | Exame da evidencia e consequencia Ferral; N4/N5 |
| Provisoes e leitura Rotavela | `cassio_rotavela` | `armazem` | Comercio, conversa | Reacao aos selos e ao retorno; N2/N5 |
| Fiscalizacao e custodia do conselho | `tamar_vardal` | `vigilia` | Morador circulante, conversa | Conhecimento restrito e reacoes legais; N5 |
| Risco da partida | `ivo_cerne` | `posto_guarda` | Guarda em ronda | Avisos contextuais, sem bloquear servico; N2 |
| Feridos e perdas | `maura_salvedra` | `enfermaria` | Cura e remocao de ferimentos | Relatorio de sobreviventes; N5/N6 |
| Primeira melhoria comunitaria | `brina_pedralva` | `obra` | Moradora circulante | Relacionar obra, material e decisao; N5 |
| Contexto e procedencia dos registros | `oren_lumeiro` | `arquivo` | Arquivista fixo, conversa | Diario e evidencia incompleta; N3/N5 |
| Compostos e preparacao | `sira_botanica` | `alquimia` | Atendimento funcional | Texto contextual sem inventar vinculo com o Lastro; N2 |

Nara e Tamar precisam continuar acessiveis apesar das rondas. Usar o NPC
existente e seu ponto de trabalho; nao gerar uma copia fixa para a historia.
Praca, portao, casa das expedicoes e oficinas ja possuem representacao externa.
Nao exigir interiores novos para iniciar N1/N2.

## Matriz de acontecimentos

| Fato / fonte | Alvo no runtime | Gatilho atual reutilizavel | Lacuna | Marco |
| --- | --- | --- | --- | --- |
| Renovacao Antecipada / recorte | Alda e Nara | `talk_to_npc()` | Sem arco, contrato ou falas por etapa | N1/N2 |
| Preparacao e partida / recorte | Porta da Torre | `enter_tower()`, `set_start_floor()` | Entrada livre nao registra contrato | N2 |
| Pedido de ajuda / recorte | Andar 1, `Patio das Marcas` | `start_floor(1)`, layout navegavel | Sem trabalhador em perigo, resgate ou desfecho | N3 |
| Extracao e rota cicatrizada / recorte | Andar 2, `Vias de Extracao` | `FloorLayout.generate()`, hazards do bioma | Hazard nao equivale a rota fechada com retorno seguro | N3 |
| Escolha de prioridade / recorte | Andar 3 | Piso e hordas existentes | Sem trabalhadores/equipamento/rota como objetivos concorrentes | N3 |
| Materiais do recorte / recorte | `pedra_regenerativa`, `musgo_de_orientacao` | `_receive_item()`, `banked_loot` | Existem, mas nao registram evidencia/objetivo | N1/N3 |
| Fragmentos de molde / recorte | Novo material a definir | Catalogo de itens | Nao identificado material dedicado; luvas/reliquia nao equivalem a fragmentos | N3 |
| Equipamento perdido / recorte | Instancia com procedencia | Instancias de equipamento e inventario | Sem identidade narrativa de proprietario/prova | N3 |
| Recipiente com fragmento / Ultimo Lastro | Objeto unico na Camara | Andar 4 e layout | Sem objeto interativo nem mensagem codificada | N4 |
| Reacao de Eloa / recorte | `eloa` | Selecao e snapshot de personagem | Sem interacao propria ou ferramenta substituta para as outras | N4 |
| Guardiao de Enxerto / recorte | `guardiao_de_enxerto`, andar 4 | `_spawn_floor_boss()`, `_register_floor_kill()` | Kit existe; apenas abate conclui, sem contencao/incapacitacao | N4 |
| Prova adicional e retirada / recorte | Saida do andar 4 | `leave_tower()`, portal e escada | Sem janela de busca/risco nem prova distinta do objeto | N4 |
| Relatorio de retorno / recorte | Nara | `leave_tower()`, `remember_event("retorno")` | Apenas contagem de pedra/status, sem dossie ou entrega | N1/N5 |
| Quatro custodias / recorte | Casa, Ferral, conselho, ocultacao | Mundo do host | Sem decisao, validacao coletiva ou consequencias | N5/N6 |
| Reforco comunitario / recorte | `village_progress`, Brina | Reforco automatico ao acumular 3 pedras | Sem escolha explicita; decidir como preservar obra anterior | N5 |
| Fracasso e Testemunho / recorte | Personagens e mundo | Queda, estabilizacao, `_handle_defeat()` | Retorno imediato nao equivale a morte/indisponibilidade/geracao | N6 |

## Pontos tecnicos verificados

- `WorldSimulation` e autoridade existente: clientes enviam intencoes.
- Conversa usa `VillageLife.talk()`: verifica jogador/proximidade, escolhe
  uma fala autoral ou solicita IA. Nao oferece dialogo ramificado/missao.
- `_village_context()` expõe profundidade, pedra e reforco. Nao existe ali
  estado narrativo, custodia ou conhecimento por etapa.
- `start_floor()` limpa inimigos, efeitos e telegraphs. Um evento narrativo
  nao pode viver somente nessas listas transitorias.
- Andares comuns abrem escada por cota de abates. Chefe morto abre escada,
  concede gemas e recebe cooldown. Nao disparar essas recompensas novamente
  quando N4 acrescentar um desfecho narrativo nao letal.
- `leave_tower()` entrega materiais, pode vender equipamento automaticamente,
  avanca periodo ao sair o ultimo membro e registra memoria de retorno.
- Save v9 inclui vila, inventarios, builds, gemas, andar e progresso material.
  Nao ha campo dedicado para missoes, evidencias, relatorios ou custodia em
  `save_data()`/`load_data()` e `world_save_schema.gd`.
- `_handle_defeat()` larga materiais e devolve a personagem imediatamente
  a Aresta com recursos restaurados. Nao ha salto geracional nesse fluxo.
- O prompt opcional de NPC recebe `opinions`. Nara menciona o andar 78 nesse
  campo; isso demanda revisar exposicao por etapa, mas nao comprova sozinho
  que uma fala atual revelou um segredo durante uma partida.

## Conflitos e decisoes abertas

| ID | Divergencia | Encaminhamento; nao aplicado |
| --- | --- | --- |
| C01 | Andar 3: recorte diz Galeria Interrompida; regiao, catalogo e gerador dizem Vias de Extracao | Proposta: conservar nome regional e chamar o evento/subarea de Galeria Interrompida. Confirmar antes de editar nomes |
| C02 | Recorte antigo inclui co-op local; revisao posterior determina online autoritativo | Aplicar documento 63, conforme ressalva existente no proprio recorte |
| C03 | Derrota imediata no prototipo versus morte, indisponibilidade e Queda Total no canone | Implementar relato de fracasso sem chamar retorno imediato de reencarnacao; aprovar transicao para vinheta antes de mudar saves |
| C04 | Reforco automatico existente versus melhoria coletiva associada ao arco | Preservar obra de saves antigos; separar entrega narrativa da obra material para nao gastar/recompensar duas vezes |
| C05 | Abate obrigatorio versus chefe contido/incapacitado | Criar resolucao de encontro distinta de morte e uma entrega unica de recompensas; manter balanceamento existente como baseline |
| C06 | Escolha coletiva sem regra atual de empate/desconexao | Proposta: confirmacao em area segura; politica de empate explicita antes da decisao. Sem escolha automatica silenciosa |
| C07 | Entrada livre, selecao de profundidade e saves avancados versus abertura narrativa | Nao resetar andares nem bloquear a Torre; oferecer arco inicial sem presumir descoberta a partir de `deepest_floor` |
| C08 | Objeto essencial versus loot filtravel/vendavel | Manter evidencia em registro narrativo nao vendavel, fora de filtros/autovenda; representacao de item pode ser separada |

Numeros de precos, reputacao e recompensas de custodia continuam abertos.
As quatro opcoes canonicas estao preservadas; nenhuma politica cooperativa
ou punicao nova foi aprovada por esta auditoria.

## Conclusao de N0

Verificacao documental: 20 links locais resolvidos, dez IDs de NPC existentes
e associacao do Guardiao de Enxerto ao andar 4 confirmados nos catalogos.
Nao foram executados testes de gameplay: esta etapa altera somente documentos.

Matriz, destinos reais, sequencia, limites de revelacao e conflitos registrados.
N0 conclui a auditoria, nao a implementacao. N1 pode iniciar pelo fluxo pequeno
de Nara -> evidencia -> retorno -> relatorio, sem depender de C01/C03/C05/C06.
Esses conflitos devem ser resolvidos antes dos marcos que alteram seus fluxos.
