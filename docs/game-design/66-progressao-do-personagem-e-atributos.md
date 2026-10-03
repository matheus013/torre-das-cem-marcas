# Progressão do Personagem e Atributos

## Implementação no protótipo

- Baixas concedem EXP conforme classe: Comum 12, Elite 30, Boss 120 e Raid 400.
- A exigência inicial é `60 + 35 × (nível atual - 1)`, provisória para o beta.
- O HUD mostra nível, EXP atual, próxima exigência e bloqueio de evolução.
- Níveis comuns concedem cinco pontos; a tela de Personagem distribui os seis atributos e apresenta as seis escolhas nos marcos.
- Vitalidade altera Vida; Agilidade altera movimento e cadência automática; Sorte altera chance e multiplicador crítico; Sabedoria altera recuperação de recarga. As escalas de Força e Inteligência nas gemas ainda precisam entrar no resolvedor de combate.
- Progresso individual dos quatro personagens, EXP, pontos, atributos e escolhas integram o salvamento.
- Desde a decisão 549, as quatro personagens vão até o nível 100, cada nível soma 5 de Vida e os dez marcos têm seis escolhas executáveis no combate (documento 74).

## Estado

**Definido como substituição das progressões anteriores de trinta e dez níveis.** A estrutura toma Dofus como referência de legibilidade entre atributos primários e derivados, adaptada para ação em tempo real e builds por gemas.

> **Recorte do beta:** somente Eloa, Sena, Cira e Rui estão disponíveis, agora do nível 1 ao 100 (decisão 549). Os níveis 10 e 20 usam as árvores de `71-personagens-e-arvores-do-beta.md`; as árvores completas estão em `74-arvores-de-evolucao-1-a-100.md`.

## Progressão do nível 1 ao 100

- Cada personagem evolui do nível 1 ao 100 durante sua geração.
- Níveis que não são múltiplos de 10 concedem cinco pontos de atributo para distribuição livre.
- Níveis 10, 20, 30, 40, 50, 60, 70, 80, 90 e 100 concedem uma escolha de evolução em vez de pontos.
- Cada marco oferece um catálogo maior que o de uma gema: baseline de quatro a seis alternativas.
- Marcos 10 a 90 misturam buffs, especializações, conversões e novas interações.
- Todas as opções do nível 100 concedem uma mecânica nova ao personagem.
- O personagem não avança além de um marco enquanto sua escolha estiver pendente.
- A progressão completa concede 450 pontos distribuíveis e dez escolhas de evolução.
- O nível da personagem, o nível de cada gema e o Legado são progressões separadas.
- Experiência continua vindo de combate, exploração, descoberta, resgate, objetivos e decisões, sem premiar apenas dano ou golpe final.

## Liberdade de build

- Não existem classes, arquétipos mecânicos nem árvore obrigatória por personagem.
- Qualquer personagem pode investir em qualquer atributo primário e usar qualquer gema cujos requisitos consiga cumprir.
- Identidade autoral aparece numa passiva única e impactante, sem afinidades que restrinjam build.
- Cada marco oferece opções de um catálogo amplo influenciado pela build atual, sem listas de classe.
- Quando existir uma evolução da passiva entre as opções, ela compete com alternativas mecânicas gerais; nunca é uma escolha obrigatória.
- Escolhas híbridas permitem combinar duas direções sem alcançar o pico de uma especialização pura.
- O jogo mostra efeitos derivados antes da confirmação.

## Atributos primários

### Vitalidade

Aumenta Vida máxima, resistência a ferimentos e estabilidade durante queda. Não aumenta dano.

### Força

Aumenta impacto físico, quebra, empurrão controlado e capacidade de carga. Gemas podem usar Força como escala primária ou secundária.

### Inteligência

Aumenta potência mágica, barreiras, cura e intensidade de construções ou invocações. Não representa conhecimento narrativo do personagem.

### Agilidade

Aumenta resposta de movimento, recuperação de esquiva, cadência compatível e controle de reposicionamento. Velocidade máxima recebe limites para não tornar Agilidade obrigatória.

### Sorte

Aumenta potência crítica e frequência de efeitos condicionais explicitamente marcados. Não aumenta diretamente loot comum, evitando uma build obrigatória para abrir recompensas.

### Sabedoria

Aumenta eficiência de recursos, recuperação de recargas e resistência a controle. Não aumenta experiência recebida, evitando que o jogador precise sacrificar a build atual para evoluir mais rápido.

## Atributos derivados

Os seis primários, equipamentos, gemas e condições alimentam:

- Vida máxima;
- Fôlego e recuperação;
- potência física e mágica;
- chance e potência crítica;
- redução de recarga;
- velocidade, aceleração e recuperação de esquiva;
- alcance e área de efeito;
- duração e potência de condições;
- armadura e resistências;
- quebra, estabilidade e resistência a controle;
- limite e potência de invocações;
- carga transportável.

Poder, alcance, crítico e velocidade são atributos derivados escassos. Nenhuma escolha isolada deve conceder um novo ciclo completo de habilidade sem contrapartida.

## Escala das gemas

- Cada Gema Ativa declara de um a três atributos de escala e seus pesos.
- Gemas não ficam presas a elementos fixos: as dezesseis matrizes mágicas podem usar combinações diferentes.
- Gemas de Suporte podem converter parte da escala, nunca criar soma ilimitada de todos os atributos.
- A interface exibe quais atributos realmente alteram a skill e a diferença antes e depois da mudança.
- Skills utilitárias continuam úteis sem investimento ofensivo por meio de duração, área, controle ou função fixa.

## Retornos decrescentes

- Valores baixos e médios recebem conversão eficiente.
- Especialização extrema continua possível, mas enfrenta retornos decrescentes e custo de oportunidade.
- Equipamento e evolução usam a mesma função de conversão para evitar duas regras invisíveis.
- Limites rígidos existem apenas para estatísticas capazes de quebrar leitura ou simulação, como redução de recarga, crítico, velocidade e quantidade de invocações.
- Os pontos de inflexão serão definidos por playtest; a interface sempre mostra o ganho real, não apenas o valor bruto.

### Baseline técnico

| Pontos brutos na faixa | Conversão efetiva |
|---:|---:|
| 0 a 100 | 100% |
| 101 a 200 | 75% |
| 201 a 300 | 50% |
| acima de 300 | 25% |

Investir os 450 pontos em um único atributo produz 262,5 pontos efetivos. Distribuir 100 pontos em quatro atributos e 50 em outro produz 450 pontos efetivos, mas abre mão do pico especializado. Essa diferença deve criar builds puras, híbridas e generalistas viáveis, sem declarar uma delas universalmente superior.

### Limites iniciais

- velocidade máxima adicional por Agilidade: 25%;
- recuperação de esquiva adicional: 35%;
- cadência adicional do ataque automático: 25%;
- chance crítica total: 35%;
- dano crítico total: 200%;
- recuperação adicional de recarga: 50%;
- eficiência adicional de recurso: 50%;
- resistência a controle: 45%.

Esses limites são guardas técnicas iniciais. Playtest pode reduzi-los ou ampliá-los sem mudar a estrutura da progressão.

### Implementação provisória do crítico

Enquanto atributos e equipamento não alimentam o combate do Pátio, o crítico usa valores fixos: 12% de chance e multiplicador de 1,75 (decisão 523). Quando Sorte e equipamento forem ligados ao combate, esses valores passam a vir do resolvedor de atributos, respeitando os limites acima.

## Perfis de escala das gemas

- Cada Gema Ativa pode escalar com no máximo três atributos primários.
- Pesos são declarados nos dados da gema e aparecem na interface.
- Uma gema pode ser pura, híbrida ou predominantemente utilitária.
- Gemas de Suporte podem converter ou redistribuir pesos dentro do mesmo limite de três atributos.
- A escala modifica potência apropriada ao efeito; não transforma automaticamente cura, alcance e dano na mesma proporção.

## Evolução final do personagem

No nível 100, todas as alternativas precisam criar uma regra nova. Exemplos:

- permitir que duas Gemas Ativas compartilhem uma condição;
- transformar excesso de Fôlego em escudo temporário;
- fazer o ataque automático copiar uma propriedade da última skill usada;
- permitir troca contextual entre duas configurações de suporte;
- evoluir o mecanismo autoral para uma forma que altera decisões de combate.

Essas opções não substituem Singularidades, contratos, Cicatrizes ou Legados narrativos.

A liberdade de build e as passivas da Primeira Geração estão definidas em `67-liberdade-de-build-e-passivas-unicas.md`.

## Reespecialização

- Escolhas ficam fixas durante a expedição.
- Aresta oferece reespecialização mediante treino, recurso e passagem de tempo.
- O custo cresce conforme a profundidade da escolha e quantidade de alterações simultâneas.
- Nível, história, marcas e consequências corporais não são apagados.

## Referência adaptada

Dofus separa características básicas como Vitalidade, Sabedoria, Força, Inteligência, Sorte e Agilidade de estatísticas derivadas como Vida, PA, PM, alcance, iniciativa, crítico, prospecção, esquiva e bloqueio. Aresta aproveita essa organização legível, mas substitui economia de turnos por cadência, recarga, Fôlego e movimento em tempo real.

- [Dofus Wiki — Characteristics](https://dofuswiki.fandom.com/wiki/Characteristic)
