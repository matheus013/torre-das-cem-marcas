# Liberdade de Build e Passivas Únicas

## Estado

**Definido:** não existem classes, arquétipos mecânicos ou papéis obrigatórios. Cada personagem jogável possui exatamente uma passiva autoral, única e impactante.

As passivas de Eloa, Sena, Cira e Rui e suas evoluções até o nível 20 estão fechadas para o beta em `71-personagens-e-arvores-do-beta.md`.

## Liberdade

- Nenhum personagem é guerreiro, mago, tanque, curador, suporte ou equivalente como categoria do sistema.
- Todos podem equipar as mesmas Gemas Ativas, Gemas de Suporte e categorias de equipamento quando atendem requisitos universais do item.
- Não existem bônus ocultos de classe, listas exclusivas de skills ou penalidades por sair de um papel esperado.
- Atributos, evoluções, gemas, suportes e equipamento formam a build escolhida pelo jogador.
- Os estilos descritos anteriormente para o elenco representam fantasia, história e tendências iniciais, não classes nem limites.
- Toda build precisa preservar meios de causar dano e sobreviver em solo, ainda que faça isso de formas diferentes.

## Passiva autoral

- Cada personagem possui exatamente uma Passiva Autoral desde o início.
- A passiva não ocupa `Q/W/E/R`, encaixe de suporte, equipamento ou escolha de evolução.
- Ela não pode ser removida, trocada, roubada, transferida ou equipada por outro personagem.
- Precisa alterar decisões, combinações ou leitura da situação; bônus plano pequeno não é suficiente.
- Deve interagir com categorias amplas de evento para funcionar com muitas gemas e builds.
- Pode crescer ou mudar por evoluções, mas sua identidade central permanece reconhecível.
- A passiva diferencia personagens sem definir uma função obrigatória para o grupo.

## Regras de design

Uma passiva saudável deve:

- funcionar com ataque automático e com várias famílias de gemas;
- oferecer ao menos duas formas de aproveitamento;
- produzir informação clara para o jogador e para aliados;
- evitar exigir um único atributo, arma ou tipo de dano;
- não conceder economia, loot ou experiência de forma que torne o personagem obrigatório;
- não substituir uma Gema Ativa completa sem condição ou custo;
- permanecer útil em solo e cooperativo.

## Passivas da Primeira Geração

Os nomes e efeitos abaixo formam a direção inicial; números pertencem ao sandbox.

### Tomé — Têmpera de Campo

Usar repetidamente ações diferentes sobre o mesmo alvo ou estrutura acumula Têmpera. O jogador pode consumir a Têmpera para reforçar defesa, ruptura ou propriedade da próxima gema, permitindo builds ofensivas, defensivas ou utilitárias.

### Eloa — Luz Residual

Acertos e interações deixam resíduos breves que revelam propriedades e podem conduzir o próximo efeito entre pontos relacionados. Qualquer gema capaz de atingir, proteger ou alterar área pode explorar a condução.

### Nilo — Reserva Planejada

Antes da expedição, Nilo escolhe uma categoria de contingência. Cumprir condições de preparo gera cargas que melhoram uso de item, defesa, munição mágica ou recuperação sem criar recursos do nada.

### Sena — Duas Correntes

Alternar entre repetir uma ação planejada e improvisar uma ação diferente gera efeitos distintos. Builds podem explorar consistência, variedade ou a transição entre ambas.

### Raul — Medida de Contenção

Interromper, deslocar, desacelerar ou poupar um alvo registra sua resistência. A próxima ação relevante pode converter a leitura em quebra, imobilização ou proteção contra aquele padrão.

### Lina — Vigília Compartilhada

Lina mantém uma ameaça, aliado ou área sob vigília. Quando o estado observado muda de forma perigosa, sua próxima ação recebe uma resposta contextual de alcance, velocidade ou proteção.

### Cira — Placas Adaptativas

Receber ou neutralizar uma propriedade hostil permite armazenar uma amostra temporária. A amostra pode ser usada defensivamente, incorporada à próxima gema ou descarregada em área.

### Noa — Diagnóstico Duplo

Observar repetições de dano, condição ou recuperação revela um diagnóstico. Noa escolhe converter a leitura em exploração de fraqueza, prevenção ou tratamento, sem ficar presa à cura.

### Ilan — Cultura Persistente

Efeitos deixados no terreno podem receber uma cultura que amadurece por tempo ou eventos. Ao colher, Ilan converte a cultura em dano, recurso, controle ou proteção segundo o que foi cultivado.

### Rui — Oportunidade Estrutural

Impactos, obstáculos, bordas e efeitos persistentes revelam oportunidades temporárias no cenário. Rui pode usar uma oportunidade para alterar trajetória, criar cobertura, abrir passagem ou sustentar outra magia.

## Sucessores

- Cada personagem de uma nova geração também possui uma passiva única.
- Passivas não são herdadas automaticamente por sangue ou família.
- Um sucessor pode reinterpretar um legado anterior, mas precisa possuir gatilho e decisão próprios.
- O sistema impede duas passivas idênticas na mesma geração jogável.

## Cooperativo online

- O host processa gatilhos e efeitos das passivas.
- Eventos usam identificadores claros, como acerto, condição aplicada, deslocamento, interação, queda e alteração de terreno.
- Clientes recebem estado suficiente para antecipar interface, mas não confirmam cargas ou efeitos.
- Logs de depuração mostram qual evento ativou a passiva e qual regra foi aplicada.
