# Sistema de Gemas e Progressão de Skills

## Estado de implementação do protótipo

- O catalogo atual tem 36 ativas, 20 suportes mecanicos e 20 suportes de buff. As 14 familias incluem projetil, dash, nova, campo, barreira, corrente, invocacao, santuario, cone, feixe, orbita, mina, meteoro e bumerangue. Lista: [catalogo de gemas](../catalogo-gemas.md).
- Cada personagem possui seu próprio loadout: quatro slots em Q, W, E e R, suportes por slot e nível, EXP e evoluções por gema (decisão 538).
- A aba Skills (`G`) troca a gema de cada slot, encaixa e remove suportes compatíveis e escolhe a evolução pendente de cada nível, sempre fora da Torre.
- Resolução no combate: base, evoluções por nível e suportes em ordem estável. Capacidade de suporte é `2 + nível` com no máximo dois suportes por slot.
- Gemas recebem a mesma EXP da personagem e precisam de `80 × nível` para subir; a evolução do nível atual deve ser escolhida antes do próximo nível. O beta limita gemas ao nível 3.
- Modificadores executados: projéteis em leque, perfuração, ricochete, homing, retorno, área no impacto, rastro e chegada do dash, barreira na chegada, repulsão, lentidão, vulnerabilidade, barreira por acerto, atração, campo que segue, excesso de cura em barreira, dano ao expirar, saltos de corrente, cura por salto, repetição no último alvo, eco agendado, roubo de vida e chance crítica adicional.
- Cargas extras acumulam usos por slot e recarregam uma por vez; estabilidade de santuario reduz o dano recebido por aliados no raio. O smoke de compatibilidade nao substitui playtests de todas as combinacoes; flags legadas de evolucao ainda exigem auditoria.
- Icones provisorios desenhados por codigo identificam as 76 gemas do beta. Multishot, ricochete e roubo de Vida sao suportados; Sifao de Folego recupera o recurso atual, limitado a 8 pontos por segundo por jogador.
- A implementação técnica está na ADR 0018.

## Estado

**Definido como substituição do modelo de habilidades fixas.** As quatro teclas ativas permanecem, mas a habilidade executada depende da Gema Ativa equipada.

## Estrutura do loadout

- Cada personagem possui quatro encaixes de Gemas Ativas, associados a `Q`, `W`, `E` e `R`.
- Cada Gema Ativa possui dois encaixes ligados para Gemas de Suporte.
- Um loadout completo pode conter quatro Gemas Ativas e até oito Gemas de Suporte.
- Ataque básico automático, interação, item rápido e passivas do personagem não ocupam esses encaixes.
- Gemas só podem ser trocadas em Aresta, acampamento seguro ou ponto de preparação autorizado.
- Uma Gema de Suporte modifica apenas a Gema Ativa à qual está ligada.

## Gemas Ativas

Uma Gema Ativa define:

- ação executada;
- forma de mira ou seleção automática;
- tags como projétil, corpo a corpo, área, movimento, proteção, invocação ou matriz mágica;
- custo, recarga e requisito de ativação;
- progressão própria do nível 1 ao 10;
- alternativas de benefício oferecidas em cada nível.

O personagem continua oferecendo atributos, passiva autoral e equipamento, sem classe ou afinidade restritiva. A gema determina a skill; a build do portador determina como ela se comporta.

## Gemas de Suporte

- Não possuem comando próprio.
- Exigem tags compatíveis na Gema Ativa.
- Podem alterar dano, alcance, área, quantidade, trajetória, condição, custo, recarga ou comportamento.
- Todo aumento forte pode impor custo, redução ou condição coerente.
- Suportes não modificam outros suportes e não criam ligações recursivas.
- Duas cópias da mesma gema não podem ocupar os dois encaixes da mesma ativa.
- Combinações incompatíveis são recusadas antes de confirmar o loadout.

Exemplo: uma Gema Ativa com tags `projétil` e `fogo` pode receber uma gema de ricochete que exige `projétil` e outra de queimadura profunda que exige `fogo`.

## Progressão do nível 1 ao 10

- Cada Gema Ativa possui nível próprio de 1 a 10.
- Em cada nível, o jogador escolhe exatamente uma evolução entre duas ou três alternativas apresentadas.
- Uma gema não avança ao nível seguinte enquanto a escolha do nível atual estiver pendente.
- Não é possível adquirir duas evoluções pertencentes ao mesmo nível.
- Ao chegar ao nível 10, a gema possui dez escolhas registradas.
- Evoluções dos níveis 1 a 9 podem ser buffs ou mudanças de mecânica.
- Todas as alternativas do nível 10 introduzem uma mecânica nova; aumento apenas numérico não é válido como evolução final.
- Benefícios posteriores podem reagir a escolhas anteriores, mas o baseline evita caminhos mortos e pré-requisitos ocultos.
- O nível da gema é separado do nível do personagem e da progressão geracional.

### Tipos de benefício

- melhoria direta com contrapartida;
- mudança de forma ou direção;
- conversão de propriedade ou matriz;
- nova interação com condição, terreno ou aliado;
- especialização em alvo único, horda, controle, proteção ou mobilidade;
- sinergia com uma categoria de Gema de Suporte.

Os níveis devem mudar decisões e comportamento, não apenas aumentar números em dez etapas.

### Evolução final

O nível 10 funciona como transformação da gema. Exemplos incluem dividir um projétil em órbita, converter cura excedente em criatura temporária, fazer uma barreira avançar junto ao portador ou permitir que uma skill consuma condições para repetir seu efeito. Cada alternativa precisa mudar como o jogador usa e combina a magia.

## Reespecialização

- A escolha de um nível fica travada durante expedições.
- Um serviço especializado em Aresta pode redefinir uma escolha mediante custo crescente.
- Redefinir não destrói nível, propriedade nem procedência da gema.
- Gemas raras ou marcadas podem exigir material, relação ou conhecimento específico para reespecialização.

## Item, propriedade e perda

- Gemas são itens físicos com proprietário, procedência, qualidade e identidade persistente.
- Nível e escolhas pertencem à instância da gema, não ao personagem que a equipa.
- Gemas podem ser compradas, encontradas, fabricadas, presenteadas, roubadas, apreendidas ou saqueadas.
- Uma gema equipada acompanha as regras de equipamento em morte parcial e pode permanecer no local da morte.
- Banco, móveis e inventários podem armazená-las.
- A Queda Total não transfere automaticamente gemas pessoais à nova geração; espólio e recuperação seguem as regras de herança.

## Origem no mundo

Gemas são cristalizações de padrões mágicos derivados das matrizes dos Dragões Primordiais. Elas não contêm domínio perfeito da magia, mas preservam uma forma reproduzível que outras raças conseguem canalizar. Religiões, famílias, cidades da Torre e Dragões Puros podem conhecer técnicas diferentes de criação e evolução.

## Autoridade online

- O host valida posse, encaixe, compatibilidade, nível, escolha, custo e ativação.
- O cliente pode prever interface e apresentação, mas não cria efeitos nem altera progressão.
- Cada instância possui identificador persistente para impedir duplicação por troca, desconexão ou salvamento.
- Trocas e reespecializações são transações atômicas: concluem inteiras ou não alteram o estado.

## Recorte inicial

- Quatro Gemas Ativas, uma representando cada função principal do sandbox.
- Seis a oito Gemas de Suporte para testar compatibilidade e combinações.
- Escolhas dos níveis 1 a 3 implementadas primeiro; a estrutura aceita até o nível 10.
- Pelo menos duas builds funcionalmente diferentes para cada Gema Ativa.
- Ferramenta de depuração mostra tags, modificadores, custos e origem de cada efeito.
