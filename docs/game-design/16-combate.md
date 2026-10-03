# Combate

> **Revisão:** a cadência deliberada, o ataque manual e o conjunto de três técnicas descritos abaixo foram substituídos pelo combate de hordas, ataque básico automático e quatro habilidades ativas de `63-cooperativo-online-e-combate-de-hordas.md`. Este texto permanece como histórico e referência para identidades dos personagens.

## Estado atual

- **Definido:** ação em tempo real com perspectiva superior ou três-quartos.
- **Definido:** cadência deliberada, cooperação orgânica e viabilidade solo.
- **Definido:** princípios gerais de escalonamento e legibilidade.
- **Definido:** magia possui origem dracônica e não utiliza uma barra universal obrigatória.
- **Definido em documento próprio:** mira híbrida, três técnicas equipadas e recursos gerais.
- **Definido em documento próprio:** câmera híbrida, separação do grupo e comportamento geral dos menus.

## Identidade

- O combate ocorre em tempo real e permanece integrado à exploração.
- A cadência é deliberada e tática, sem ritmo de bullet hell.
- Posicionamento, terreno, interrupção e preparação importam tanto quanto dano.
- Inimigos comuns não funcionam apenas como grandes reservas de vida.
- Ataques básicos continuam úteis durante toda a campanha.
- Ataques inimigos possuem antecipações claras e respostas compreensíveis.

## Estrutura dos personagens

Cada personagem possui:

- sequência ofensiva básica;
- ação defensiva ou de mobilidade própria;
- técnica característica;
- conjunto reduzido de técnicas equipadas;
- ferramenta de exploração utilizável em combate;
- mecanismo autoral ligado ao próprio estilo.

Exemplos de mecanismos autorais incluem estabilidade de Tomé, conexões de Eloa, Traçado e Desvio de Sena, Diagnóstico e Intervenção de Noa e uso estrutural do ambiente por Rui.

Não existe uma barra universal de mana. Técnicas fortes são alimentadas pelo comportamento característico de cada personagem, evitando espera passiva por recargas.

## Magia em combate

- Toda magia deriva, direta ou indiretamente, de uma ou mais das dezesseis matrizes originadas pelos Dragões Primordiais.
- Personagens canalizam magia por seus próprios mecanismos autorais, equipamentos, materiais, preparação e comportamento.
- Estudar magia não substitui identidade de combate nem cria uma classe rígida de mago.
- Combinar matrizes amplia possibilidades e também custo, risco e complexidade.
- Dádivas Dracônicas integram-se ao conjunto reduzido de técnicas e mantêm limite próprio.
- Poder divino pode interagir com magia sem possuir a mesma origem.
- A estrutura cosmológica está registrada em `44-origem-da-magia-e-separacao-dos-universos.md`.

## Cooperação Orgânica

O fluxo cooperativo possui três momentos:

1. **Preparação:** um personagem cria rota, marca, diagnóstico, cultura, reserva ou posição.
2. **Abertura:** outro interrompe, desloca ou expõe a ameaça.
3. **Aproveitamento:** qualquer integrante utiliza a oportunidade criada.

- Interações fundamentais não ficam presas a duplas específicas.
- Relações elevadas podem acrescentar ações especiais.
- Nenhuma composição depende de tanque, curador ou dano tradicionais.

## Jogo Solo

- Um jogador controla um único personagem, sem companheiro obrigatório.
- Todo personagem produz e aproveita suas próprias oportunidades.
- A quantidade e coordenação dos inimigos se ajustam ao tamanho do grupo.
- Objetivos cooperativos recebem variações executáveis individualmente.
- O modo solo reduz pressão simultânea, não inteligência ou identidade dos inimigos.
- Personagens voltados a suporte mantêm caminhos próprios de dano e sobrevivência.

## Escalonamento Cooperativo

Com mais jogadores, o jogo pode alterar:

- quantidade e composição de inimigos;
- direções de ataque;
- sobreposição de ameaças;
- objetivos simultâneos;
- comportamento e ações de chefes.

A vida dos inimigos também pode crescer, mas não deve ser o principal método de escalonamento.

## Legibilidade

- Silhuetas, efeitos e cores permanecem reconhecíveis em pixel art.
- Áreas perigosas são distinguíveis das áreas criadas pelos jogadores.
- Efeitos cooperativos utilizam sinais consistentes.
- Grandes impactos produzem pausa visual curta e resposta sonora sem interromper o controle.
- Combates intensos alternam pressão e recuperação em vez de manter ruído constante.

## Afixos de inimigos

- Inimigos podem receber até um prefixo e um sufixo modificador.
- Afixos alteram atributos como Vida, velocidade, dano, intervalo de ataque e recompensa; versões posteriores também podem adicionar uma mecânica declarada.
- Cada afixo possui ID estável, posição no nome e peso de sorteio.
- O host realiza o sorteio deterministicamente e replica IDs e atributos finais para os clientes.
- Prefixos e sufixos possuem sinais visuais diferentes e nenhum deles depende apenas de cor.
- Chefes autorais podem usar conjuntos próprios ou bloquear afixos incompatíveis.

## Raças e graus de evolução

- Todo monstro possui uma raça, que representa sua origem estrutural ou biológica e concede um traço persistente.
- O beta começa com Juntídeo, Calcário, Rebocado, Moldado e Enxertado. Seus traços interagem, respectivamente, com barreiras, mitigação, camuflagem, adaptação a impactos e alimentação por efeitos.
- Todo monstro também possui um grau independente da raça: Nascente, Maduro, Evoluído, Alfa ou Ápice.
- O grau altera porte, Vida, velocidade, dano, cadência, recompensa e o intervalo permitido de afixos.
- Nascente não recebe afixos; Maduro recebe de zero a um; Evoluído recebe de um a dois; Alfa recebe exatamente dois.
- Ápice representa chefes e criaturas excepcionais. Sua mecânica é autoral e ele não recebe afixos aleatórios, evitando combinações que descaracterizem o encontro.
- Raça e grau fazem parte do estado determinístico criado pelo host, do salvamento e da replicação online.

## Invocações

- Gemas, equipamentos e Relíquias podem criar entidades aliadas chamadas invocações.
- Uma invocação pode representar construto, espírito, cópia, criatura ou mecanismo; ela não precisa pertencer às raças de monstros.
- Toda invocação possui proprietário e equipe, podendo usar o alvo do dono ou selecionar alvos segundo sua própria regra.
- Definições controlam Vida, poder, intervalo, alcance, movimentação, duração, colisão, vulnerabilidade e persistência entre áreas.
- Limites são aplicados por proprietário e por definição. Ao atingir o limite, a definição decide entre substituir a mais antiga ou rejeitar a nova invocação.
- Invocações temporárias desaparecem ao expirar. Invocações permanentes são possíveis estruturalmente, mas só entram como conteúdo após regras específicas de salvamento, transição e equilíbrio.
- Criação, alvo confirmado, dano, morte e expiração são simulados pelo host.

## Bosses e raids

- Classe de encontro é independente de raça e grau: Comum, Elite, Boss ou Raid.
- Bosses possuem fases autorais, barra de Ruptura, janela de atordoamento e enrage.
- Raids acrescentam objetivos de arena capazes de proteger o inimigo central e dividir a pressão do encontro.
- Bosses e núcleos de raid são Ápice, não recebem afixos aleatórios e escalam de um a quatro participantes.
- Tarefas paralelas no cooperativo tornam-se sequenciais no solo; nenhuma raid exige composição ou personagem específico.
- O host controla fases, objetivos, Ruptura, enrage, recompensas e restauração do encontro.

## Questões posteriores

- Valores exatos de Fôlego e recuperação.
- Conteúdo dos mecanismos autorais individuais.
- Ajustes numéricos da câmera e limites de separação.
- Conteúdo exato dos menus rápidos.
- Regras detalhadas de colisão e fogo aliado.
