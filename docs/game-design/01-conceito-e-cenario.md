# Conceito e Fundação do Cenário

## Conceito central

- Roguelike RPG geracional cooperativo em pixel art para um a quatro jogadores.
- Cada campanha cria um mundo independente, com estado e progressão próprios.
- Por padrão, nenhum progresso é carregado entre mundos.
- Ao criar uma campanha, o grupo pode optar por conectá-la ao multiverso.
- Mundos conectados recebem acontecimentos e consequências de Singularidades Globais.
- Mundos não conectados não possuem Singularidades nem sofrem seus impactos.
- O estado do mundo inclui vila, famílias, personagens, economia, NPCs, masmorra, eventos e decisões narrativas.
- A primeira geração possui dez personagens jogáveis fixos, sem duplicação dentro da mesma sessão.
- Todos nasceram ou foram criados na vila e se conhecem em diferentes graus.
- Uma Queda Total avança o mundo por anos e inicia nova geração jogável sem apagar o progresso da vila.
- Existem quatro povos jogáveis principais, incluindo humanos como um povo entre iguais.
- Famílias podem ser mistas por nascimento, casamento, adoção e migração.
- Diferenças entre povos são horizontais e não restringem profissão, equipamento ou função de grupo.
- Cada personagem possui progressão individual dentro daquele mundo.
- Diferenças grandes de progressão entre personagens são permitidas.

## Direção visual

- `Hero Siege` é a referência principal para ambientação e tratamento de texturas: pixel art vista de cima, cenários compactos, materiais marcados, terreno legível e alta densidade de detalhes ambientais.
- Aresta deve adaptar essa linguagem ao próprio cenário, mantendo a vila acolhedora, funcional e transformável, enquanto a Torre pode ser mais opressiva, estranha e degradada.
- A referência orienta escala, densidade, leitura de materiais e atmosfera; sprites, tiles, arquitetura, símbolos e paleta serão autorais.
- `Pokémon FireRed` continua sendo a referência para organização espacial, exploração e entrada em interiores.
- Jogos da série `Diablo` continuam sendo a referência para hierarquia do HUD de combate.
- Nenhuma dessas referências substitui a identidade narrativa de Aresta nem autoriza cópia direta de assets, mapas ou interface.
- Desde 2 de outubro de 2026, o protótipo usa arte provisória gerada pelo PixelForge e ajustada à paleta de Aresta (decisão 515). A arte autoral definitiva continua posterior à validação do ciclo funcional.

## Loop principal

1. Preparar-se na vila.
2. Formar o grupo e escolher objetivos.
3. Explorar a masmorra, enfrentar perigos e descobrir recursos.
4. Decidir entre avançar, acampar ou recuar.
5. Retornar com recursos, informações e consequências.
6. Desenvolver personagens, famílias, serviços e a vila.
7. Abrir novas possibilidades e avançar mais fundo.

Fluxo estrutural:

> Masmorra fortalece personagem → personagem fortalece família → família fortalece vila → vila fortalece aventureiros → aventureiros avançam na masmorra.

## Origem da vila

- A vila chama-se **Aresta**.
- A vila existe há aproximadamente 120 a 150 anos.
- Começou como um posto misto de exploração, vigilância e comércio.
- Seus fundadores já pertenciam a mais de um povo, e ondas posteriores de migração ampliaram sua diversidade.
- Exploradores precisavam de proteção, ferramentas, suprimentos e compradores.
- Artesãos, comerciantes e famílias se estabeleceram gradualmente ao redor da entrada.
- A masmorra tornou-se a principal fonte de riqueza e identidade local.
- Alimentos e outras necessidades básicas também vêm da superfície.

## História cosmológica distante

- A magia originou-se nos dezesseis Dragões Primordiais.
- Durante a Era da Convivência, deuses, dragões e povos mortais habitavam os mesmos grandes territórios.
- Milhares de Dragões Puros nasceram de pais Primordiais e mães Humanas.
- A ambição de uma hegemonia Humana transformou revolta por autonomia em guerra de domínio universal.
- Deuses e Primordiais enfrentaram exércitos apoiados por Herdeiros Divinos, filhos de deuses com Humanos.
- A guerra quase destruiu a antiga continuidade e culminou na Separação em muitos universos.
- Depois dela, deuses criaram pequenos Domínios Divinos e Primordiais retiraram-se principalmente para o vazio entre universos.
- Descendentes Puros dispersaram-se e muitos vivem ocultos entre Humanos.
- A masmorra combina uma Raiz do Coração da Ascensão, a contenção criada durante a Separação e mundos acumulados em suas camadas.
- A estrutura completa está registrada em `51-torre-coracao-e-centesimo-mandato.md`.
- A estrutura completa está registrada em `44-origem-da-magia-e-separacao-dos-universos.md`.

## Autonomia e mundo exterior

- Aresta pertence formalmente à **Marca de Ordel**, território regional de fronteira.
- A **Chancelaria da Marca** administra impostos, estradas, defesa regional, comércio entre cidades e cartas de autonomia.
- A Chancelaria é dirigida por um Chanceler escolhido por uma assembleia de cidades e corporações para mandato de dez anos; o cargo não é hereditário.
- Uma antiga carta concede autonomia à vila e reconhece seu controle local sobre a entrada.
- A vila deve pagar impostos, produzir relatórios e cooperar diante de grandes ameaças.
- A Chancelaria pode fiscalizar, negociar ou tentar suspender a autonomia, mas precisa justificar a medida perante a assembleia regional.
- Distância, custo militar, fracassos anteriores, conhecimento local e proteção legal dificultam uma tomada direta.
- O exterior vê a vila como fronteira perigosa, fonte de riquezas, ameaça e oportunidade.
- Descobertas importantes atraem comerciantes, estudiosos, autoridades, espiões e grupos hostis.
- O crescimento pode provocar tentativas de revisar ou revogar a autonomia.
- O mundo exterior aparece principalmente por visitantes, caravanas, notícias e consequências; não será um mundo aberto paralelo.

## Situação inicial

- A vila é funcional, mas está estagnada e sob pressão crescente.
- O governo ainda funciona e possui legitimidade, embora enfrente divergências.
- A guarda é pequena, respeitada e possui poucos recursos.
- O conselho divide-se entre exploração, segurança, lucro e conhecimento.
- Os personagens jogáveis são percebidos de maneiras diferentes: promessas, herdeiros, trabalhadores ou figuras controversas.
- Cada personagem possui motivação própria para explorar.
- Uma expedição desaparecida e mudanças recentes na masmorra formam o motivo coletivo.
- A expedição desaparecida é a Expedição do Último Lastro, ocorrida dezoito anos antes; sua verdade causal está registrada em `60-expedicao-do-ultimo-lastro.md`.

## Primeiro arco de mistério

- O recorde público de exploração termina no andar 63.
- Um objeto marcado como pertencente ao andar 78 aparece em uma área rasa.
- O objeto está ligado a uma expedição desaparecida.
- Mapas antigos começam a falhar.
- Criaturas e caminhos apresentam mudanças incomuns.
- O monumento da entrada reage ao objeto.
- Existem indícios de que exploradores antigos ou o governo esconderam informações.
- Esses acontecimentos formam um único mistério inicial, sem revelar a origem da masmorra.

## Cultura local

- A relação emocional com a masmorra mistura orgulho, medo, luto e gratidão.
- Quase todas as famílias foram beneficiadas ou feridas por ela.
- Existe um ritual comunitário de partida e retorno, acompanhado por tradições familiares.
- Jovens podem receber treinamento, mas só entram após idade e autorização adequadas.
- Mortos e desaparecidos são registrados de formas distintas.
- Famílias escolhem como preservar a memória de seus membros.
- Materiais conhecidos da masmorra aparecem em ferramentas, medicina, iluminação, construção e arte.
- Artefatos desconhecidos ou perigosos são regulados.
- Uma celebração anual combina comércio, fundação da vila e homenagem aos que não retornaram.
- O significado da celebração muda conforme a campanha.

## Tom narrativo

- Comunidade calorosa cercada por perigo real e mistério crescente.
- Consequências deixam marcas, mas raramente destroem uma campanha.
- Escolhas combinam princípios morais reconhecíveis com conflitos ambíguos.
- A masmorra pode conter suspense, estranheza e horror corporal moderado.
- O jogo não deve tornar-se inteiramente horror, grimdark ou infantil.
- Humor nasce da convivência e das personalidades, sem anular perigo ou luto.
- Romances são opcionais, autorais e baseados em personalidade, história, compatibilidade e decisões.
- Nem todo vínculo profundo precisa tornar-se romance.
