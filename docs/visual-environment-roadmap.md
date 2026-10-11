# Revisao Visual dos Cenarios

## Diagnostico

O problema da imagem nao era a HUD: o mesmo piso ocupava quase toda a tela,
enquanto os poucos marcos estavam afastados da rota. Um mapa grande, sem
hierarquia entre percurso, clareiras e bordas, parece vazio mesmo com bons
sprites. A prioridade e composicao e identidade, nao espalhar objetos ao acaso.

As plantas tambem mostram que os biomas compartilham praticamente a mesma
distribuicao de seis conjuntos e a mesma forma retangular. Trocar o tile e os
props nao resolve essa repeticao estrutural. Nas arenas, o anel do mesmo prop
e repetido quase sem um marco exclusivo do chefe. Esses sao os maiores limites
que permanecem depois desta primeira rodada.

A revisao abrange a vila e seus distritos, casa de Elen, sala legada de chefe,
dez biomas da Torre e geracao dos cem andares, incluindo arenas. A decoracao
de chao e exclusivamente visual; objetos altos continuam usando a colisao
compartilhada entre host e clientes.

## Aplicado Nesta Etapa

- [x] Objetos de beira de rota, com pequenos conjuntos do mesmo bioma.
- [x] Corredor central de combate livre e clareiras de chegada preservadas.
- [x] Piso com desgaste, manchas e detalhes pequenos especificos dos biomas.
- [x] Soleiras, canteiros laterais e pavimentacao complementar na praca da vila.
- [x] Tapetes tecidos e luz da janela no interior, organizando areas de uso.
- [x] Sombras de contato nos props, sem alterar sombras dos personagens.
- [x] Particulas ambientais discretas, ancoradas no mundo, com teto de 28.
- [x] Planos deterministas em cache, malhas trianguladas uma vez e culling.
- [x] Testes de conectividade dos cem andares e dos destinos dos moradores.
- [x] Ferramentas de captura dos mapas e de enquadramentos reais do jogo.

## Proximas Melhorias

### Refinamento do trecho de referencia (2026-10-11)

- [x] Desgaste e pequenos detritos acompanham as bordas das salas das Galerias.
- [x] Patio, claustro e arquivo possuem padroes de pavimento distintos.
- [x] Detalhes exclusivamente visuais, sem alterar obstaculos ou o RNG da simulacao.
- [x] Regressao de determinismo, limites do mapa e malhas dos cem andares.
- [x] Capturas nativas atualizadas de UI e cenarios; paineis sem rolagem horizontal.
- [ ] Benchmark com hordas e quatro jogadores; densidade nao aprovada para hardware-alvo.

O passe reutiliza os assets existentes. O Bosque e os eventos N3 continuam
pendentes; esta entrega nao implementa acontecimentos narrativos novos.

Validacao local: `sh tests/run_all.sh` terminou com 89 testes aprovados e
zero falhas, incluindo rede. Capturas: 21 de UI e 39 de cenarios. Isso nao
substitui QA grafico nativo Windows/Linux nem controles fisicos.

### Marco G1 - Galerias (2026-10-08)

- [x] Gerar e importar quatro modulos: muro baixo, muro lateral, arco e nicho.
- [x] Alternar patio, claustro e arquivo arruinado nos andares comuns das Galerias.
- [x] Compor duas salas abertas por andar, com bordas de piso e paredes interrompidas.
- [x] Emoldurar a chegada e dar marcos arquitetonicos as arenas das Galerias.
- [x] Integrar colisao autoritativa; o vao do arco permanece caminhavel.
- [x] Testar determinismo, assets, composicoes, navegacao e geracao dos 100 andares.
- [ ] Medir GPU/CPU com hordas e quatro jogadores antes de ampliar a densidade.

Os modulos estao em `assets/sprites/props/galeria_*.png`, com origem e dimensoes
registradas em `art/gallery-kit.json`. O atlas original foi preservado em
`art/generated/gallery_kit_v1.png`, e a importacao e reproduzivel por
`tools/art/import_gallery_kit.gd`. Esta etapa nao conclui as demais prioridades
P1: os outros biomas ainda precisam de composicoes e kits proprios.

Proximo trecho: Bosque, substituindo o mesmo arranjo retangular por clareiras,
bordas de vegetacao e ruinas tomadas pelas raizes, sem fechar os corredores.

| Prioridade | Ambiente | Melhoria visual | Criterio de conclusao |
| --- | --- | --- | --- |
| P1 | Galerias | G1 entregue; refinar entulho, transicoes e distribuicao da luz no trecho de referencia | As composicoes continuam reconheciveis com hordas e efeitos; nenhum corredor bloqueado |
| P1 | Todos os biomas | 3-4 composicoes autorais por regiao, combinadas pelo gerador | Dois andares consecutivos nao repetem a mesma silhueta central |
| P1 | Estrutura dos mapas | Alternar patio, travessia, salas conectadas e clareiras; bordas com transicoes naturais | A planta de cada regiao tem forma propria, mantendo rotas e espaco para hordas |
| P1 | Vila | Rever escala relativa de casas, moradores e mobiliario; fachadas com pequenos conjuntos funcionais | Comercio, casas e producao distinguiveis em uma captura sem rotulos |
| P1 | Interiores | Tiles de parede com portas/janelas, objetos domesticos e variantes por servico | Casa, enfermaria e alquimia tem identidades proprias; zonas ainda nao existentes exigem trabalho de gameplay separado |
| P1 | Chefes | Marcos exclusivos de cada arena, relacionados ao chefe e a sua historia | Centro de combate limpo e telegrafias legiveis no pico de efeitos |
| P2 | Vila | Fumaca nas chamines, agua na fonte, roupas e bandeiras ao vento | Movimento perceptivel sem competir com NPCs/interacoes |
| P2 | Bosque/Manto | Folhas, vegetacao em camadas, fungos com animacao e esporos localizados | Caminhos e inimigos permanecem distinguiveis do fundo |
| P2 | Bacias | Margens e transicoes de agua, ondas e reflexos discretos | Agua decorativa nao parece uma superficie caminhavel ou um ataque |
| P2 | Ermo/Eixos | Cabos, maquinas quebradas, faiscas localizadas e marcas de descarga | Efeitos ambientais nao usam a mesma linguagem das telegrafias |
| P2 | Arquivo | Rotas inscritas no piso, mapas danificados e pequenos postos de levantamento | Os objetos contam uma historia coerente, sem depender de texto novo |
| P2 | Planicie/Campos/Obra | Vegetacao parasita, jardins interrompidos e etapas de construcao | Uma assinatura visual propria para cada regiao |
| P2 | Global | Luzes localizadas, revisar contraste de inimigos e fundo | Sem nevoa opaca, cores estouradas ou jogador perdido no cenario |
| P3 | Global | Variantes de tiles e transicoes de borda, decals de desgaste e animacoes de props | Repeticao reduzida em capturas proximas e afastadas |
| P3 | Global | Presets de qualidade e medicao de CPU/GPU em hordas e co-op | Orçamento estabelecido por hardware-alvo, nao apenas pela maquina de desenvolvimento |

## Ordem Recomendada

1. Fazer das Galerias um trecho de referencia: chegada, marca narrativa e arena.
2. Usar esse trecho para acertar escala, contraste e densidade antes de ampliar.
3. Criar kits pequenos por bioma; evitar reformar cem andares manualmente.
4. Inserir animacoes e novos efeitos somente apos medir o custo de renderizacao.
5. Validar hordas, gamepad, janelas estreitas e quatro jogadores em cada regiao.

## Assets e Limites

O passe inicial reaproveitou os sprites existentes. O marco G1 acrescenta o kit
gerado das Galerias. Ainda faltam kits de arquitetura dos demais biomas,
modular, transicoes de terreno e sprites animados de agua/vegetacao/maquinas
para as proximas etapas. Eles devem seguir a escala e a perspectiva dos assets
atuais; nao basta inserir ilustracoes maiores no mapa.

As manchas e particulas nao concedem recursos, nao causam dano e nao modificam
o save. Novos props altos entram pela geracao deterministica e respeitam a
faixa livre da rota. Nao existe ainda um benchmark completo de GPU em hordas;
cache e limites de desenho sao precaucoes, nao uma garantia de FPS.

## Verificacao

```sh
godot --headless --path . --script tests/environment_dressing_test.gd
godot --headless --path . --script tests/map_connectivity_test.gd
godot --headless --path . --script tests/gallery_composition_test.gd
sh tests/run_all.sh
godot --path . --script tools/art/map_shots.gd
godot --path . --script tools/art/scenery_shots.gd
```

`art/shots/maps` recebe a planta da vila e paginas dos cem andares.
`art/shots/scenery` recebe 39 enquadramentos: chegada e rota dos dez biomas,
mais os andares 2, 3, 5 e 6 para comparar as composicoes das Galerias,
quatro arenas, quatro distritos da vila, dois interiores e uma janela estreita.
As capturas reais sao amostras representativas, nao uma visita manual a cada
metro dos cem andares. A conectividade e os planos visuais sao testados em todos.
