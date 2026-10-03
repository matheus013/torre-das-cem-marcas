# Protocolo de QA e playtest de acesso antecipado

Nenhum caso abaixo esta aprovado por existir neste documento. Preencher os
resultados por build, maquina e participante. Usar executaveis exportados,
sem editor Godot e sem checkout do projeto na maquina do testador.

## Identificacao por sessao

Registrar versao, commit, alteracoes locais da build, sistema operacional,
CPU, GPU, RAM, resolucao, numero de jogadores e tipo de conexao.
Para problemas: esperado, ocorrido, passos, frequencia, captura e log.
Ocultar dados pessoais e nunca anexar chaves dos provedores de IA.

## Matriz minima

| ID | Caso | Resultado esperado | Resultado / evidencia |
| --- | --- | --- | --- |
| B01 | Instalar Windows sem Godot | Abre pelo executavel, sprites e menu presentes | Pendente |
| B02 | Instalar Linux sem Godot | Abre pelo executavel, sprites e menu presentes | Pendente |
| B03 | Abrir com --dev e --server | Release continua no menu publico | Pendente |
| B04 | Instalar via cliente Steam | Launch option abre o jogo e atualizacao funciona | Pendente |
| S01 | Primeira partida solo offline | Escolher personagem, entrar na Torre e voltar | Pendente |
| S02 | Morrer e repetir expedicao | Sem bloqueio; perdas e progresso coerentes | Pendente |
| S03 | Completar ciclo com cada personagem | Todas viaveis, sem composicao obrigatoria | Pendente |
| S04 | Percorrer conteudo anunciado | Andares e chefes acessiveis, sem softlock | Pendente |
| P01 | Salvar, encerrar e reabrir | Estado do personagem e mundo preservado | Pendente |
| P02 | Atualizar build com save anterior | Migracao preserva itens e progresso | Pendente |
| P03 | Arquivo de save truncado | Recupera backup ou avisa sem apagar dados | Pendente |
| P04 | Interromper escrita / disco sem espaco | Save anterior permanece utilizavel | Pendente |
| N01 | Grupos de 2, 3 e 4 jogadores | Movimento, combate e saque consistentes | Pendente |
| N02 | Host e clientes em redes externas | Conexao reproduzivel; limitacoes documentadas | Pendente |
| N03 | Desconectar cliente durante combate | Host segue; jogador recebe estado claro | Pendente |
| N04 | Encerrar host durante expedicao | Clientes saem de estado de espera infinito | Pendente |
| N05 | IP invalido, timeout e sala cheia | Falha explicada e retorno ao menu funciona | Pendente |
| N06 | Latencia / perda de pacotes | Sem duplicar itens, dano ou progresso | Pendente |
| U01 | Menus em 720p, 1080p e ultrawide | Texto legivel; botoes nao sobrepostos | Pendente |
| U02 | Ajustar e restaurar opcoes | Persistem apos reiniciar; padroes recuperaveis | Pendente |
| U03 | Remapear controles | Conflitos tratados; jogar e navegar possiveis | Pendente |
| F01 | Maior carga no hardware minimo | Meta de desempenho sustentada e registrada | Pendente |
| F02 | Jogar por duas horas | Sem crash recorrente ou crescimento ilimitado de memoria | Pendente |
| A01 | Jogar sem servicos de IA | Jogo completo funciona offline | Pendente |
| C01 | Xbox por USB e Bluetooth | Selecionar personagem, mover, mirar, lutar, menus e pausa funcionam | Pendente |
| C02 | DualShock 4 por USB e Bluetooth | Botoes/eixos corretos; confirmar/cancelar e dicas coerentes | Pendente |
| C03 | DualSense por USB e Bluetooth | Botoes/eixos corretos; confirmar/cancelar e dicas coerentes | Pendente |
| C04 | Desconectar/reconectar durante partida | Sem movimento preso; teclado/mouse continuam utilizaveis | Pendente |
| C05 | Alternar mira automatica com H/L3 e opcoes | Alvo vivo mais proximo; sem alvo usa direcao manual | Pendente |
| C06 | Abrir menus com controle e navegar ate o fim | Equipar, gemas, atributos, save/load e retorno acessiveis | Pendente |
| C07 | Steam Input ligado/desligado | Sem entradas duplicadas e com mapeamento utilizavel | Pendente |

## Primeira sessao externa

Dar a build a pelo menos 10 pessoas sem explicar os controles verbalmente.
Observar onde elas travam, se entendem retirada e morte e se conseguem iniciar
uma segunda expedicao. Rodar pelo menos 3 grupos de co-op em redes reais.
Essas sao metas de validacao do projeto, nao regras da Steam.

Perguntar apos a sessao: o que ficou confuso, qual falha impediu continuar,
o que motivaria repetir a expedicao e se o estado da loja corresponde ao jogo.
Registrar respostas sem converter opinioes em numeros inventados de prontidao.

## Severidade e decisao

- Critico: perda de save, impossibilidade de abrir ou progresso bloqueado.
- Alto: crash reproduzivel, duplicacao de itens ou funcao anunciada inoperante.
- Medio: atrito relevante com alternativa disponivel.
- Baixo: defeito visual/textual sem prejuizo ao fluxo.

Criticos e altos impedem lancamento. Cada correcao precisa de reproducao antes,
novo teste depois e identificacao da build validada. Os resultados devem ser
anexados ao registro de execucao antes de marcar EA4 ou EA6 como concluidos.
