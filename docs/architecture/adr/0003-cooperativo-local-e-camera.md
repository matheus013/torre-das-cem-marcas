# ADR 0003 — Cooperativo local e câmera

## Estado

**Substituída pela ADR 0004 em 1 de outubro de 2026.**

Esta decisão permanece registrada porque orientou a primeira prova descartável. Não representa mais a arquitetura vigente.

## Decisão

### Jogadores locais

- Uma sessão possui de um a quatro slots locais.
- Cada slot mantém identidade separada de seu dispositivo físico.
- Teclado é um dispositivo compartilhado configurável; controles são identificados pelo ID recebido da engine.
- Desconectar um controle pausa as ações daquele slot e oferece reconexão, sem transferir controle automaticamente.
- Entrada e saída livre existem em áreas seguras; durante combate, saída exige pausa coletiva ou confirmação.

### Torre

- A câmera principal é compartilhada.
- O enquadramento usa o retângulo que contém os jogadores e margem de perigo.
- Limite suave avisa e desacelera separação excessiva.
- Limite rígido impede ampliar uma arena além da leitura projetada.
- Separações são eventos autorais e ativam Viewports próprios temporariamente.

### Aresta e áreas seguras

- Jogadores próximos compartilham painel.
- Grupos afastados recebem painéis próprios usando SubViewports que compartilham o mesmo World2D.
- A prova inicial implementa uma divisão 1, 2 e grade 2 × 2; agrupamento 3+1 e 2+1+1 entra após validação do princípio.

## Limites da prova

- Formas e cores provisórias substituem sprites finais.
- Quatro perfis de teclado permitem testar sem quatro controles, mas não representam a interface final.
- A prova não contém combate, inventário nem salvamento definitivo.

## Critério de aceitação

- quatro jogadores entram e saem sem duplicar dispositivo;
- cada entrada move apenas seu personagem;
- modo Torre mantém todos legíveis em câmera compartilhada;
- modo seguro divide e reúne painéis sem recriar o mundo;
- desconexão não remove o personagem nem corrompe o slot.
