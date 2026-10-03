# Experiência, Interface e Câmera do Recorte

## Estado

**Definido para o recorte vertical.**

> **Revisão:** fluxos de mundo, relatório e informação continuam vigentes. Entrada por dispositivo local, quatro painéis, câmera compartilhada e HUD de três técnicas foram substituídos por `63-cooperativo-online-e-combate-de-hordas.md`.

Este documento descreve informação, fluxo e comportamento. Composição visual final, tipografia, resolução e animações pertencem à produção visual.

## Criação de mundo

O primeiro fluxo possui quatro etapas curtas.

### Continuidade

- **Mundo conectado:** Singularidades Globais, história compartilhada e Travessia multiversal podem existir no pós-jogo.
- **Mundo isolado:** toda campanha e pós-jogo local permanecem disponíveis, sem eventos globais nem Singularidades compartilhadas.

A escolha é explicada antes da confirmação e fica permanente para aquele mundo. Não exige conexão ativa durante partidas locais; sincronização global ocorre apenas quando o jogo puder realizá-la com segurança.

### Regras de campanha

- dificuldade de combate;
- progresso indireto de personagens inativos;
- limites para crime e sabotagem entre jogadores;
- assistência de decisão cooperativa;
- idioma, conteúdo sensível e acessibilidade inicial.

### Identidade local

- nome da continuidade;
- símbolo da crônica;
- espaço de salvamento selecionado.

### Jogadores

Cada participante entra, escolhe dispositivo, configura assistência individual e seleciona personagem disponível. Configurações pertencem ao jogador humano; progressão e dinheiro pertencem ao personagem.

## Fluxo principal

1. **Aresta:** conversar, tratar, comprar, fabricar, investigar e escolher prioridades.
2. **Mesa de expedição:** selecionar objetivo, grupo, Carta de Partilha, suprimentos e limite de gasto.
3. **Previsão de risco:** revisar profundidade, rotas, ameaças conhecidas, carga, indisponibilidades e meios de retirada.
4. **Torre:** explorar, lutar, coletar, decidir avançar ou recuar.
5. **Retorno:** registrar sobreviventes, itens, provas, custos, experiência e versões dos acontecimentos.
6. **Consequência:** aplicar relações, reputação, calendário, projetos, tratamento e eventos.

O jogador retorna ao controle em Aresta antes de receber novas solicitações extensas.

## Interface em Aresta

### Informação persistente

- data e período do dia;
- personagem controlado e estado de saúde;
- objetivo acompanhado opcionalmente;
- evento urgente quando existir;
- indicação de jogadores em painéis separados.

Dinheiro, reputações e listas de missões aparecem sob demanda, não como barras permanentes.

### Mapa de Aresta

- Mostra locais e serviços, não todos os NPCs em tempo real.
- Indica aberto, fechado, interrompido, investigado ou indisponível por símbolos e texto.
- Permite acompanhar até três assuntos, sem transformar toda relação em marcador.
- Segredos, crimes e pessoas ocultas só aparecem quando existe conhecimento legítimo do personagem.

## Mesa de expedição

Uma única sequência reúne:

- objetivo principal e contratos opcionais;
- personagens disponíveis e motivo de indisponibilidade;
- mapa conhecido e ponto de retorno pretendido;
- Carta de Partilha;
- Fundo de Expedição e limite de gasto;
- suprimentos individuais e carga coletiva;
- risco conhecido, lacunas de informação e proteção de resgate;
- confirmação separada de cada jogador.

Alertas distinguem **perigo conhecido**, **informação ausente** e **consequência irreversível**. O jogo não traduz incerteza em porcentagem falsa de sucesso.

## HUD de expedição

Cada jogador possui bloco estável com:

- retrato e símbolo de jogador;
- Vida e Fôlego;
- mecanismo autoral;
- quatro Gemas Ativas em `Q/W/E/R`;
- item rápido;
- estado de carga;
- ferimento ou condição crítica.

Informação de aliados reduz-se a Vida, estado crítico, mecanismo relevante à cooperação e pedido contextual. Detalhes completos aparecem em sala segura ou menu coletivo.

Jogos da série `Diablo` orientam a hierarquia do HUD de combate: Vida e recurso ocupam extremos opostos do bloco inferior, enquanto habilidades e consumíveis ficam centralizados. `Hero Siege` orienta sua compactação em pixel art, minimapa, informação objetiva e ocupação reduzida do campo de ação. Aresta adapta essa leitura para Vida, Fôlego, mecanismo autoral e quatro Gemas Ativas, sem copiar molduras, texturas ou identidade visual.

### Implementação provisória do HUD

- Vida e Fôlego aparecem como globos que se esvaziam de baixo para cima, nas extremidades do painel inferior.
- Os quatro slots mostram ícone da gema, tecla no canto, preenchimento de recarga e contorno dourado quando prontos.
- Uma faixa acima do painel mostra a Passiva Autoral: pontos para recursos de até três cargas, barra para Instabilidade e marcador de amostra.
- Minimapa usa dourado para a personagem, vermelho para inimigos e ciano para a saída.

### Números de dano

- Dano causado aparece em creme acima do alvo e sobe enquanto desaparece.
- Crítico usa texto maior, vermelho, com exclamação e um breve aumento de tamanho ao surgir.
- Dano sofrido pela personagem aparece em laranja com sinal negativo.
- BLOQUEIO indica acerto anulado por escudo de afixo; ABSORVIDO indica dano contido pela barreira.
- Números e efeitos ficam numa camada própria, sem escurecer pela iluminação ambiente.

### Tela inicial pública

Com modo dev desligado, o jogo abre numa tela com título, portão da Torre, os quatro personagens do beta, Jogar e Sair. Laboratório, editores e provas técnicas não aparecem.

### Sinais no mundo

- Perigo inimigo: forma angular, pulso externo e som descendente.
- Efeito aliado: forma aberta, contorno contínuo e som ascendente.
- Interação: losango e verbo curto.
- Prova ou procedência: selo documental.
- Rota e retirada: seta segmentada.
- Elemento de jogador: cor configurável mais símbolo individual.

Nenhum significado depende apenas de cor.

## Carga, loot e posse

- Coleta comum mostra nome, unidades e novo estado de carga sem abrir janela.
- Item único pausa apenas a interação local e mostra portador, proprietário conhecido, procedência e regra da Carta de Partilha.
- Transferência relevante exige confirmação do recebedor.
- Ocultação é ação deliberada separada de guardar.
- Em sala segura, a tela coletiva mostra distribuição física e permite reorganização simultânea sem duplicar itens.

## Relação, reputação e prova

- Relação pessoal aparece por categoria e memórias relevantes, não por número exposto no padrão.
- Reputação mostra categoria por instituição, fatos conhecidos e tendência recente.
- Suspeita aparece apenas quando o personagem percebe sinais dela.
- Dossiê separa alegação, provas, testemunhas, contradições e lacunas.
- Uma prova informa procedência, integridade, acesso e possíveis contestações.
- Persuasão mostra argumentos disponíveis e riscos conhecidos, nunca chance exata universal.

## Queda, morte e Testemunho

### Personagem caído

- Retrato perde saturação, janela de estabilização aparece numericamente e no mundo.
- Aliados recebem direção, distância e risco de aproximação.
- O jogador caído pode marcar perigo e escolher entre recursos de emergência disponíveis.

### Morte parcial

- O corpo e a carga permanecem identificados no mapa enquanto houver conhecimento da posição.
- Sobreviventes veem estado do Testemunho de Retorno e meios válidos de transmiti-lo.
- No retorno, uma linha do tempo explica morte, itens perdidos, duração estimada da Volta e reação das relações centrais.

### Queda Total

- O jogo confirma que não existe Testemunho válido antes de encerrar a geração.
- A Crônica registra grupo, feitos, crimes conhecidos, itens e versões da morte.
- A Virada apresenta o intervalo de anos, mudanças essenciais e sucessores antes de devolver controle.
- No recorte vertical, esse fluxo termina em vinheta navegável e resumo de legado.

## Relatório de retorno

O relatório usa seis etapas:

1. sobreviventes, mortos, ferimentos e desaparecidos;
2. itens trazidos, perdidos, ocultos e contestados;
3. contratos e objetivos;
4. experiência, Domínios e descobertas;
5. versão declarada à Casa das Expedições;
6. mudanças imediatas em relações, reputações, calendário e vila.

O jogador pode revisar causas antes de confirmar partilha ou relato. Consequências desconhecidas não são reveladas antecipadamente.

## Linguagem das gerações

- Retratos exibem símbolo da família ou instituição e numeral da geração.
- Personagens da Primeira Geração usam moldura íntegra; sucessores incorporam uma marca visual de legado escolhida na criação.
- Reencarnados recebem sinal discreto permanente na ficha e apresentação temporária no corpo.
- Expedições Perdidas aparecem em seção própria da Crônica, sem serem apagadas pela geração seguinte.
- Edifícios preservados mostram placa ou detalhe da geração que os construiu.
- Mudanças temporais usam mapas comparativos e cenas locais, não apenas texto de resumo.

## Câmera compartilhada na Torre

### Baseline

- A câmera acompanha centro ponderado do grupo e desloca levemente em direção à ameaça ou objetivo visível.
- O limite suave começa quando um personagem fica a aproximadamente doze metros do centro.
- O limite rígido aparece a dezoito metros durante combate comum.
- Aviso de borda surge dois metros antes de cada limite.
- Mudança de enquadramento usa transição de aproximadamente 0,25 segundo; impactos nunca alteram bruscamente o centro.
- Arena deve manter jogadores e antecipações críticas dentro da área útil no enquadramento máximo.

Medidas são referências espaciais e devem ser convertidas à escala final sem alterar sua relação.

### Separação projetada

- Tela divide quando evento autorizado mantém grupos além de dez metros por mais de um segundo.
- Painéis voltam a unir quando todos ficam a menos de sete metros e fora de perigo imediato.
- Divisão preserva símbolo e direção dos outros painéis.
- Em solo, a mesma situação oferece rota contínua ou controle sequencial, nunca puzzle simultâneo impossível.

## Tela dividida em Aresta

- Jogadores próximos compartilham painel.
- A separação começa depois de aproximadamente dez metros ou ao entrar em interior independente.
- Conversas pessoais ocupam apenas o painel envolvido.
- Conselho, partida, retorno e decisão irreversível reúnem os painéis depois de aviso.
- Interface adapta densidade em quatro painéis sem remover Vida, confirmação ou consequência crítica.

## Votação e confirmação

- Decisão cotidiana usa maioria e representante para empate.
- Decisão irreversível exige maioria clara e confirmação individual dos afetados diretamente.
- Cronômetro só existe em situação ficcional urgente e sempre é anunciado antes.
- Ausência de voto não conta automaticamente como aprovação.
- A tela resume efeitos conhecidos sem revelar consequências ocultas.

## Critérios de experiência

- Informação necessária à sobrevivência fica visível durante ação.
- Informação social detalhada aparece no contexto em que pode ser usada.
- Cada perda explica causa e consequência sem revelar informação que os personagens não possuem.
- Quatro jogadores conseguem preparar-se e operar na vila sem filas obrigatórias.
- O estado conectado ou isolado do mundo permanece consultável e nunca muda silenciosamente.
