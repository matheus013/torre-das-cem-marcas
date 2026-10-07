# Renovacao Antecipada: roteiro de gatilhos

Roteiro de implementacao N0, 2026-10-07. IDs abaixo sao propostos para N1,
nao eventos ja disponiveis no jogo. Base:
[matriz auditada](lore-matriz-canone-runtime.md) e
[recorte canonico](game-design/57-recorte-vertical.md).

## Sequencia principal

| Etapa / ID proposto | Condicao de entrada | Acao confirmada pelo host | Estado produzido | Consequencia |
| --- | --- | --- | --- | --- |
| Crise / `ra_crise` | Mundo sem abertura registrada; jogador em Aresta | Conversar com Alda | Abertura conhecida | Direcionamento para Nara; nao bloqueia a Torre |
| Contrato / `ra_contrato` | Conversa com Nara, perto dela e fora de combate | Aceitar pedido explicitamente | Contrato ativo | Objetivo no diario; sem custo ou premio inventado |
| Pedido de ajuda / `ra_socorro` | Contrato ativo; evento do andar 1 ainda nao resolvido | Concluir resgate ou registrar abandono | Resultado de socorro | Reacao posterior; desfecho nao exige classe especifica |
| Rota / `ra_cicatriz` | Andar 2; trecho seguro validado | Renovacao altera caminho com aviso | Rota alterada conhecida | Nova decisao de caminho; nenhuma saida perdida |
| Prioridade / `ra_prioridade` | Andar 3; situacao apresentada ao grupo | Resolver trabalhadores, equipamento ou rota | Prioridade e resultado confirmados | Altera encontro/preparo/relatorio, conforme regra a implementar |
| Recipiente / `ra_recipiente` | Andar 4, interacao segura disponivel | Examinar recipiente com Eloa ou ferramenta substituta | Evidencia inicial e objeto identificado | Mensagem incompleta; nao explica sua origem inteira |
| Guardiao / `ra_guardiao` | Condicoes do encontro satisfeitas | Confirmar desfecho valido do Guardiao | Encontro resolvido | Libera retirada e oferta da busca; premio uma unica vez |
| Busca / `ra_prova_adicional` | Encontro resolvido, risco informado | Buscar evidencia ou retirar imediatamente | Prova adicional obtida ou recusada | Diferencia dossie; retirada sem prova continua valida |
| Retorno / `ra_retorno` | Jogador voltou com resultado confirmado | Fechar registro da incursao | Relatorio pendente | Nara pode apresentar descobertas/perdas reais |
| Relatorio / `ra_relatorio` | Perto de Nara; relatorio pendente | Confirmar entrega | Entrega registrada | Recompensa idempotente, sem exigir coleta duplicada |
| Custodia / `ra_custodia` | Objeto recuperado; momento seguro coletivo | Confirmar uma das quatro opcoes | Destino do objeto persistente | Falas e efeito jogavel; politica coletiva ainda a aprovar |
| Consequencia / `ra_consequencia` | Custodia confirmada | Aplicar consequencia uma unica vez | Arco concluido e vila atualizada | Proximo assunto de investigacao disponivel |

O encadeamento nao e uma fila de cutscenes. Etapas podem ser consultadas
depois; servicos, movimento e leitura opcional permanecem disponiveis.
O diario distingue objetivo, evidencia verificada e rumor.

## Regras transversais de estado

- Missao e custodia pertencem ao mundo do host; identidade de perfil nao
  transporta a escolha para outro mundo.
- Reconexao e entrada tardia leem o estado confirmado, sem refazer premios.
- Resultados de uma incursao sao distintos das descobertas permanentes.
  Cada incursao precisa de identidade estavel antes de implementar relatorios.
- Nao marcar um resultado por ouvir uma fala, abrir uma janela ou ler uma
  string de status. Avanco exige evento de dominio confirmado.
- Nao inferir descoberta de `deepest_floor`, nivel, gemas ou chefe em cooldown.
- Repetir uma etapa confirmada oferece resumo; nao reinicia premios ou custodia.
- Evidencias essenciais nao passam por filtro de raridade ou venda automatica.
- Logs de moradores podem refletir fatos publicos, mas nao sao o save da missao.

## Caminhos fora da conclusao principal

| Situacao | Resultado requerido |
| --- | --- |
| Entrou na Torre sem contrato | Combate atual continua; nao declarar missao concluida por profundidade |
| Voltou antes do andar 4 | Registrar retirada e descobertas reais; contrato pode continuar |
| Fracassou antes de recuperar o objeto | Relatorio de perda, sem custodia ficticia; preservar conhecimento ja confirmado |
| Objeto recuperado, sem prova adicional | Quatro opcoes de custodia continuam disponiveis |
| Jogador desconectou | Preservar resultados confirmados; nao inventar voto ou entrega |
| Save antigo tem reforco/andares avancados | Preservar progresso; iniciar narrativa sem premios retroativos implicitos |
| Repetiu o confronto | Nao duplicar objeto unico, entrega de arco ou consequencia politica |

A morte/Queda Total depende de C03 da matriz. Nao apresentar o retorno
imediato atual como morte e reencarnacao canonicas.

## Matriz de revelacoes

| Momento | Informacao que pode chegar ao jogador | Fonte legitima | Informacao que continua restrita |
| --- | --- | --- | --- |
| Abertura em Aresta | Renovacao fora do esperado; risco local; necessidade de investigar | Alda/Nara e sinais da vila | Fragmento, Duas Marchas e responsabilidade no encobrimento |
| Primeiras expedicoes | Materiais, ferramentas, rotas antigas e relatos contraditorios | Ambiente, trabalhadores e registros encontrados | Relato onisciente da expedicao desaparecida |
| Camara Refeita | Recipiente Ferral, reacao material, mensagem incompleta | Objeto examinado e reacoes especificas | Explicacao completa da origem gravitacional e do transporte pela Torre |
| Retorno inicial | Reconhecimento parcial do trabalho Ferral e interesses sobre custodia | Dalia e relatorio; apenas o que cada fonte sabe | Dalia conhecer todo o destino da expedicao ou uma familia deter toda a verdade |
| Regiao 5, entrega futura | Integrantes extras, simbolos Vardal e carga real | Vestigios na Tempestade Espelhada | Exposicao antecipada da identidade do agente prestativo |
| Regiao 6, entrega futura | Acordo contraditorio, Duas Marchas e nomes apagados | Arquivo/Mil Cascas e provas legitimamente obtidas | Resolver todas as contradicoes como simples falsificacao |
| Regiao 8, entrega futura | Primeiro Lastro e proposito gravitacional do fragmento | Evidencias da regiao | Conhecimento completo sem descoberta correspondente |
| Regiao 10 e Segunda Ascensao, futuro | Marcadores, metodo do clone e vinculo do agente | Provas tardias conforme Ultimo Lastro | Spoilers dessa identidade nas falas ou prompts iniciais |

Antes de liberar cada dialogo, validar a relacao entre conhecimento do NPC,
evidencia do mundo e etapa do jogador. Rumor deve continuar identificado como
rumor. A IA opcional recebe somente o subconjunto publico autorizado; as
escolhas e falas indispensaveis sao autorais e funcionam sem servico externo.

## Primeira implementacao N1

**Objetivo tecnico:** provar o fluxo com Nara e uma evidencia de campo, nao
escrever toda a campanha nem acrescentar uma nova revelacao canonica.

1. Catalogo minimo com IDs, requisitos, objetivo, texto curto e conclusao.
2. Estado narrativo independente de memorias de NPC, com persistencia validada.
3. Conversa autoral com Nara e aceitacao explicita do pedido.
4. Interacao de campo deterministica, registrada pelo host, sem drop raro.
5. Retorno e confirmacao do relatorio com uma entrega unica.
6. Objetivo/diario legiveis com foco por controle e teclado/mouse.

A evidencia da prova deve usar um registro contextual permitido pelas fontes
do recorte. Seu texto final e recompensa precisam de especificacao em N1;
nao usar o objeto do andar 4 como recompensa provisoria nem reutilizar uma
arma chamada Lastro como se fosse o fragmento narrativo.

**Testes de saida:** comandos repetidos, distancia invalida, cliente sem
permissao, retorno incompleto, save/carregar antes/depois da entrega,
reconexao e preservacao de inventario/build/gemas em saves anteriores.
