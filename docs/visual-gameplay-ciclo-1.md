# Ciclo 1: Bosque e comparacao de equipamentos

Data: 2026-10-11. Prioridade do responsavel: cenarios/UI e gameplay
Survivors + RPG. Lore, fechamento do MVP e publicacao Steam ficam em
backlog; sistemas existentes e automacoes nao foram removidos ou desligados.

## Bosque

Piso composto em tres variacoes deterministas: clareira alongada de vento,
bordas de raizes e ruinas com trechos de pavimento. Margens irregulares,
vegetacao agrupada, pequenos detritos e faixa de passagem desgastada.
Inclui os andares 8-16 e o piso da arena; assets altos continuam existentes.

O passe e exclusivamente visual. Mantem a geracao de colisoes, rotas,
spawns e posicoes de saves anteriores. Nao conclui a reforma de topologia
nem promete uma floresta estruturalmente diferente das Galerias.
Malhas preparadas uma vez, culling existente, menos de 700 detalhes por
andar e teto ambiental de 28 particulas mantido.

## Equipamentos

Inventario tem uma faixa fixa de comparacao, acessivel por mouse e foco
de teclado/controle, independentemente da rolagem da mochila. Informa:

- Qual peca saira: o mesmo encaixe vazio/ocupado ou anel/reliquia de menor
  score usado pela transacao real, sem introduzir substituicao nova.
- Vida com ferimentos, Folego, defesa, movimento, cadencia, recarga e area,
  quando houver diferenca; percentuais mostram delta em pontos percentuais.
- Dano por acerto, alcance, intervalo e critico do autoataque, com suporte,
  escala, afinidade, nivel de personagem e modificadores equipados.
- Ganhos/perdas de passivas e suportes do autoataque que ficarao inativos.
- Incompatibilidades antes de equipar, sem remover a peca atual.

Comparacao e somente leitura. Usa outro loadout com as mesmas instancias;
nao equipa temporariamente no personagem nem altera sorteios. As mesmas
formulas servem ao runtime e a previa, incluindo modificadores fixos de
passiva/afixos. Buffs ativos sao mantidos no estado atual; nao antecipa
procs, vulnerabilidade do alvo, dano critico esperado, geometria contra
uma horda ou potencia final das skills. Portanto, nao representa DPS.

Nao muda economia, valores de combate, slots, propriedade de equipamentos
ou formato do save. Favoritos, filtros e ordenacao ainda estao pendentes.

## Verificacao

Suite final `sh tests/run_all.sh`: 95 testes aprovados, zero falhas,
incluindo quatro provas de rede. Capturas nativas revisadas em janela
estreita, 720p e 1080p; faixa de comparacao permanece visivel e sem
rolagem horizontal. Validacao nao substitui controles fisicos/playtest.

- `tests/woodland_dressing_test.gd`: nove andares, tres variacoes,
  determinismo, quantidade de detalhes e rotas/colisoes preservadas.
- `tests/equipment_comparison_test.gd`: valores apos equipar, ferimentos,
  modificador fixo de passiva, encaixe de anel, incompatibilidade, suporte,
  RNG/estado preservados e foco no menu.
- `tests/ui_no_horizontal_scroll_test.gd`: inclui novas pecas e comparacao
  nos sete tamanhos de janela da regressao existente.
- `tools/art/visual_gameplay_shots.gd`: 15 capturas em 1280x720, 1920x1080
  e 640x720, com tres variacoes do Bosque e duas comparacoes de equipamento.

Sonda local headless no Apple M1, com suite rodando ao mesmo tempo:
161 inimigos, quatro jogadores, media 9,864 ms e pior quadro 12,157 ms
para `step + view_snapshot`; cerca de 1,91 Mbit/s por cliente a 20 Hz.
Nao mede render/GPU, p95/p99, hardware minimo ou uma sessao prolongada;
nao e comparacao controlada com a versao anterior nem aprovacao de desempenho.

## Continuacao

Visual: Manto dos Esporos e, depois, demais biomas/interiores. Gameplay:
auditar consumidores de atributos/passivas em G0.3/G0.4, fontes desejaveis
de saque e builds de G3.2. Medir os gargalos antes de ampliar densidade.
Controles fisicos e playtest de compreensao da comparacao permanecem pendentes.
