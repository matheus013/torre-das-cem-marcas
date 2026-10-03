# Inventário, Carga e Partilha

## Estado atual

- **Definido:** inventário físico individual integrado à carga coletiva.
- **Definido:** estados de carga, Carta de Partilha e ocultação deliberada.
- **Definido:** princípios de perda, depósito e recuperação.
- **Definido:** todo NPC possui inventário físico e pode carregar, guardar, perder, entregar ou ter itens tomados.
- **Definido:** móveis e banco armazenam itens com propriedade, acesso e risco próprios.
- **Definido para o recorte:** capacidade, estados e penalidades iniciais seguem `58-parametros-iniciais-do-recorte.md`.
- **Definido em documento próprio:** estrutura de dinheiro e fundos após a partilha.

## Estrutura do inventário

Cada personagem possui:

- **Equipamento Ativo:** itens atualmente vestidos ou utilizados.
- **Suprimentos Preparados:** consumíveis e ferramentas escolhidos antes da expedição.
- **Carga Transportada:** parte física do loot coletivo.
- **Compartimento Pessoal:** poucos objetos sob responsabilidade individual.
- **Espaço Oculto:** pequena capacidade para contrabando ou itens não declarados.

NPCs seguem a mesma lógica de posse física. Equipamentos e objetos carregados permanecem no corpo se morrerem; patrimônio guardado em casa, trabalho, banco ou esconderijo continua nesses locais.

Não existe inventário em grade. Itens usam categorias simples de volume e dificuldade de transporte.

## Estados de carga

- **Leve:** movimentação e Fôlego normais.
- **Carregado:** pequena redução de recuperação e mobilidade.
- **Sobrecarregado:** penalidades significativas, ainda permitindo recuo.
- **Carga Especial:** objeto volumoso que ocupa as mãos, exige suporte ou pode ser transportado por duas pessoas.

Capacidade depende principalmente de Kit de Expedição, preparação e melhorias Rotavela. Força física isolada não transforma Tomé no carregador obrigatório.

## Carga da expedição

- Materiais comuns entram em uma relação compartilhada visível.
- O peso permanece distribuído fisicamente entre os integrantes.
- O grupo reorganiza carga em áreas seguras.
- Itens únicos e artefatos mostram claramente seu portador.
- A carga de um personagem caído ou desaparecido permanece no local.
- Nilo redistribui, protege e acondiciona carga com maior eficiência.
- Acampamentos permitem depósitos temporários sujeitos a roubo, criaturas e mudanças da masmorra.

## Carta de Partilha

Antes da expedição, o grupo escolhe uma regra pública:

- **Partilha Igual:** valor dividido igualmente após taxas e custos.
- **Prioridade do Descobridor:** o descobridor possui preferência sobre o item.
- **Fundo Comunitário:** maior parte segue para família, projeto ou vila.
- **Contrato Personalizado:** liberado por leis, reputação ou influência Rotavela.

Partilha Igual é o padrão recomendado para novas campanhas. Objetos perigosos continuam sujeitos à declaração.

## Retorno à vila

Para cada descoberta relevante, o grupo pode:

- vender ou dividir;
- entregar a uma família;
- financiar projeto;
- registrar na Casa das Expedições;
- guardar para fabricação;
- declarar como artefato;
- esconder ou negociar clandestinamente.

Recursos comuns podem ser processados em conjunto. Itens únicos exigem decisão explícita.

## Ocultação

- Um personagem pode mover deliberadamente um objeto para seu Espaço Oculto.
- A ação reduz capacidade e deixa possibilidades de prova.
- Testemunhas, inspeções, registros de peso e propriedades especiais podem revelar a ocultação.
- Descoberta afeta relações, reputação e possível investigação.
- Coleta rápida nunca se transforma acidentalmente em roubo.

## Perda e recuperação

- Recuo bem-sucedido preserva a carga transportada.
- Derrota pode deixar carga e equipamentos no local.
- Compartimentos protegidos preservam parte dos recursos.
- Depósitos e itens abandonados podem ser recuperados em outra expedição.
- Ciclos da masmorra podem mover, danificar ou expor o loot a grupos NPC.
- Itens importantes não desaparecem silenciosamente sem oportunidade ou consequência narrativa.

## Armazenamento na vila

- Baús, armários, estantes, cofres e compartimentos ocultos funcionam como depósitos físicos.
- Cada móvel possui proprietário, pessoas autorizadas, capacidade e proteção.
- O banco oferece cofres individuais, familiares e coletivos com registro de acesso.
- Furto, arrombamento, apreensão legal e assalto continuam possíveis conforme segurança e provas.
- A estrutura completa está registrada em `53-posse-crime-provas-e-chantagem.md`.

## Implementação no protótipo

- Saque de baixas cai no chão em volta do inimigo; qualquer jogador o recolhe passando por cima, sem menu (decisão 550).
- Materiais iguais próximos empilham; equipamentos e itens raros têm facho de luz e nome na cor do tier.
- Derrota e reserva de reconexão expirada deixam a carga no chão da Torre para recuperação posterior.
- A Carta de Partilha ainda não existe: por enquanto, quem recolhe carrega o item.

## Fluidez

- Materiais comuns empilham automaticamente.
- Coleta durante combate não abre menus.
- Comparação e redistribuição detalhadas ocorrem em locais seguros.
- O grupo recebe aviso antes de ultrapassar um estado de carga.
- Jogadores podem recusar automaticamente objetos que causariam sobrecarga.

## Resultado econômico

A divisão entre Bolsa Pessoal, Fundo de Expedição, Patrimônio Familiar e Tesouro Público está registrada em `21-economia-pessoal-e-fundos.md`.

Posse, procedência, crime e armazenamento estão registrados em `53-posse-crime-provas-e-chantagem.md`.
