# ADR 0015 — Encontros de boss e raid

## Estado

Aceita em 1 de outubro de 2026.

## Contexto

Bosses e raids precisam de fases, objetivos, escalonamento e recuperacao de sessao que nao pertencem ao modelo de um inimigo comum. Codificar cada confronto diretamente na cena dificultaria autoria, teste e consistencia online.

## Decisao

- Separar `MajorEncounterDefinition` de `MajorEncounterState`.
- Referenciar a definicao-base do inimigo por ID estavel.
- Modelar fases como limiares decrescentes de Vida com listas autorais de mecanicas.
- Permitir que fases declarem um objetivo que bloqueia dano ate sua conclusao.
- Escalonar Vida e dano por quantidade de participantes entre um e quatro.
- Manter Ruptura, atordoamento e enrage como estados comuns a boss e raid.
- Fazer o host controlar dano, fase, objetivos, enrage, conclusao e snapshots.
- Exigir grau Apice, classe correspondente e ausencia de afixos aleatorios para o inimigo central.
- Manter apresentacao, IA de mecanicas e composicao de ondas separadas do estado deterministico do encontro.

## Implementacao inicial

- O catalogo possui um boss e uma raid validos.
- `MajorEncounterState` aplica escalonamento, limita dano em fases protegidas, processa Ruptura, enrage e restauracao de snapshot.
- A Central de Conteudo possui editor de boss e raid com campos JSON para fases e objetivos.

## Consequencias

- Novos encontros podem ser criados sem alterar o nucleo de progressao.
- Mecanicas especificas ainda exigem executores registrados pelo combate.
- Testes precisam cobrir cada objetivo, transicao e combinacao de tamanho de grupo antes da publicacao do encontro.
