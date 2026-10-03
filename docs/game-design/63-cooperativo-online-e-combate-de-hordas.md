# Cooperativo Online e Combate de Hordas

## Estado

**Decisão aprovada após o encerramento inicial do game design.** Este documento substitui as regras incompatíveis de cooperativo local, câmera compartilhada, ataque manual e três técnicas equipadas.

## Estado de implementação

A vila de Aresta e a Torre já rodam como sessão host-cliente de um a quatro jogadores por IP direto (ADR 0018, decisões 533 a 537):

- host autoritativo com `WorldSimulation`; clientes enviam intenções e recebem snapshots a 20 Hz e eventos confiáveis;
- personagens únicas por sessão; troca somente fora da Torre;
- inimigos perseguem o jogador mais próximo e projéteis atingem qualquer jogador;
- EXP inteira para todos na arena e saque para quem derrota;
- a Câmara Refeita reúne todo o grupo do Pátio, e quem chega durante o confronto entra direto na sala;
- santuários curam aliados e barreiras compartilháveis alcançam aliados próximos;
- desconexão libera a personagem; o salvamento pertence ao host.

- reconexão: perfil local estável e reserva de 60 segundos para a personagem de quem caiu, com proteção total durante a espera (decisão 545);
- snapshots comprimidos com zstd (decisão 546);
- dificuldade escalada pelo tamanho do grupo na arena, com reforços pelo flanco, Vida de elite e chefe pela tabela do documento 58 e recompensa limitada a 80% do crescimento (decisão 548).

Convites, relay e descoberta em LAN ainda não existem.

## Identidade da sessão

- O jogo funciona em solo ou cooperativo online para até quatro participantes.
- Um participante cria o mundo e atua como host da sessão, em modelo semelhante a servidores escutantes de jogos cooperativos.
- Os demais entram por convite ou endereço do host, conforme os serviços disponíveis na plataforma.
- O host é autoridade sobre mundo, NPCs, inimigos, loot, dano, tempo, inventários e decisões persistentes.
- Clientes enviam intenção de movimento, habilidade e interação; não confirmam resultados importantes por conta própria.
- O mundo e seu salvamento pertencem ao host. Jogadores convidados preservam apenas preferências e identidade de perfil fora daquele mundo.
- Não existe migração de host no MVP. Se o host sair, a sessão termina depois de salvar o último estado confirmado.
- Servidor dedicado pode ser adicionado depois, sem ser requisito do MVP.

## Entrada e reconexão

- O MVP prova conexão em LAN e por IP direto antes de convites, relay ou serviços de plataforma.
- A sessão reserva por tempo limitado o personagem de um participante desconectado.
- Durante a tolerância de reconexão, o personagem deixa de aceitar comandos, recebe proteção contextual fora de combate e tenta recuar quando isso não altera resultados narrativos.
- Em combate, desconexão não duplica itens, evita dano já confirmado nem permite recarregar um estado anterior.
- Ao expirar a tolerância, o host assume a decisão segura definida para a atividade: remover da expedição quando possível ou manter o personagem indisponível até uma transição.

## Câmera e mundo

- Cada participante possui sua própria tela e câmera; não existe split-screen nem obrigação de enquadrar todo o grupo.
- Jogadores podem realizar atividades diferentes em Aresta e separar-se dentro das regras da expedição.
- Transições coletivas, início de chefe, mudança de andar e decisões irreversíveis usam reunião, confirmação ou votação explícita.
- Indicadores mostram direção, distância e estado de aliados quando estão fora da tela.
- Perigos e recompensas são simulados pelo host mesmo quando nenhum cliente os enquadra.

## Núcleo do combate

- A perspectiva é superior ou três-quartos, com grande quantidade de inimigos e pressão contínua de posicionamento.
- O ataque básico é automático. Cada personagem seleciona alvos válidos por alcance, prioridade e regras de seu kit.
- O jogador concentra sua atenção em movimento, posicionamento, rota, tempo de recarga, habilidades ativas, resgate e objetivo da expedição.
- Encontros alternam ondas densas, grupos especiais, ameaças ambientais, objetivos e chefes; não são apenas salas estáticas.
- A legibilidade tem prioridade sobre quantidade bruta. Silhueta, antecipação, cor, som e limite de efeitos preservam ameaças críticas.
- O combate mantém viabilidade solo e cooperação orgânica, sem exigir uma composição fixa de funções.

## Movimento com mouse

- Clique com o botão direito define um destino no chão.
- Manter o botão direito pressionado atualiza continuamente o destino em direção ao cursor.
- O personagem contorna colisões simples; obstáculos complexos exigem navegação validada pelo host.
- Interações usam o botão esquerdo ou comando contextual separado para não conflitar com movimento.
- Opções de acessibilidade permitem alternar entre manter e clicar, ajustar sensibilidade e remapear comandos.
- Controle por gamepad continua desejável, mas precisa preservar as mesmas regras sistêmicas e será validado depois do baseline de mouse e teclado.

## Quatro habilidades ativas

- Cada personagem possui quatro slots de Gemas Ativas fixos em `Q`, `W`, `E` e `R` durante a ação.
- A habilidade de cada slot depende da Gema Ativa equipada e de até duas Gemas de Suporte ligadas, conforme `65-sistema-de-gemas-e-progressao-de-skills.md`.
- As habilidades usam o cursor, o próprio personagem, um alvo automático ou uma área prevista, conforme o kit.
- `Q` tende a ser a ação de baixa recarga que expressa o mecanismo principal.
- `W` tende a oferecer mobilidade, defesa ou reposicionamento.
- `E` tende a controlar área, preparar combinação ou responder a grupos especiais.
- `R` tende a ser a ação de maior impacto, com preparação ou recurso autoral claro.
- Essas funções são uma gramática de leitura, não classes rígidas; kits podem inverter papéis quando a identidade justificar.
- Recargas e recursos são confirmados pelo host. O cliente pode antecipar animação e interface, mas deve corrigir rejeições sem duplicar efeito.
- Ataque automático, passivas, item rápido e interação não ocupam os quatro slots ativos.

## Escalonamento cooperativo

- Quantidade, composição, direções de entrada, inimigos especiais e objetivos escalam antes da Vida bruta.
- Mais jogadores ampliam a área efetivamente ocupada e podem provocar frentes simultâneas.
- Reviver, estabilizar e proteger aliados continuam importantes, mas não exigem função de curador dedicada.
- Dano direto entre aliados permanece desativado por padrão.
- Loot e decisões persistentes são resolvidos pelo host segundo as regras de propriedade e partilha do mundo.

## Princípios de rede para o design

- O jogo precisa continuar compreensível sob latência moderada e pequenas correções de posição.
- Ações irreversíveis, consumo de item raro, morte, loot e transição aguardam confirmação autoritativa.
- Movimento e feedback de habilidade podem usar previsão local quando a prova técnica demonstrar correção estável.
- O projeto não depende de conexão online permanente fora de sessões cooperativas ou da sincronização multiversal opcional.

## Recorte do MVP

- Uma pessoa hospeda e até três entram na mesma sessão.
- Cada tela acompanha apenas seu personagem.
- Movimento por botão direito, ataque automático e `Q/W/E/R` funcionam para os quatro kits do recorte.
- Host simula hordas, chefes, loot, queda, inventário e persistência.
- Entrada tardia é permitida apenas em Aresta ou ponto seguro.
- Reconexão, encerramento do host e salvamento não podem duplicar nem apagar estado confirmado.
- Convites de plataforma, relay, matchmaking público, servidor dedicado e migração de host ficam fora do primeiro MVP.
