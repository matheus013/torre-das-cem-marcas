# ADR 0007 — Gemas de habilidade

## Estado

**Aceita em 1 de outubro de 2026.**

## Contexto

As quatro habilidades ativas não são mais kits fixos. Cada comando recebe uma Gema Ativa, ligada a até duas Gemas de Suporte. Gemas Ativas evoluem do nível 1 ao 10 e registram exatamente uma escolha de benefício por nível.

## Decisão

- Modelar definição imutável separadamente da instância persistente da gema.
- Usar quatro slots estáveis associados a `Q/W/E/R`.
- Limitar cada ativa a dois suportes diretos.
- Validar suportes por tags declarativas.
- Proibir suporte recursivo e cópia da mesma instância no mesmo conjunto.
- Manter nível, escolhas, qualidade, procedência e identificador na instância da gema.
- Resolver modificadores numa sequência ordenada e inspecionável.
- Fazer host validar equipagem, progressão, reespecialização e ativação.

## Pipeline de efeito

1. carregar forma e valores básicos da Gema Ativa;
2. aplicar escolha de cada nível em ordem crescente;
3. aplicar os dois suportes na ordem canônica de identificador, não na ordem de encaixe;
4. aplicar atributos, mecanismo autoral e equipamento do portador;
5. aplicar condições temporárias do mundo;
6. limitar valores inválidos e produzir descrição de depuração;
7. executar o efeito autoritativo.

A ordem canônica evita que trocar visualmente dois suportes altere o resultado sem explicação.

## Dados e salvamento

Cada instância persistida contém:

- identificador único;
- identificador da definição;
- nível entre 1 e 10;
- uma escolha por nível alcançado;
- dois identificadores opcionais de suportes ligados;
- qualidade, procedência, proprietário e localização.

Definições são dados versionados do jogo. Migrações precisam preservar instâncias quando uma escolha ou tag mudar de versão.

## Implementação inicial

- `SkillGemDefinition` descreve tipo, tags, compatibilidade e escolhas por nível.
- `EquippedActiveGem` controla nível, uma escolha por nível e dois suportes.
- `SkillGemLoadout` mapeia quatro slots para `Q/W/E/R`.
- A prova usa objetos em memória; Resources, inventário persistente e pipeline de modificadores entram depois da validação estrutural.

## Consequências

- Personagens ganham grande variedade de builds sem multiplicar comandos.
- Conteúdo cresce combinatoriamente, exigindo tags, limites e testes automatizados.
- Identidade dos personagens precisa vir também de mecanismos autorais e afinidades para que gemas não tornem todos equivalentes.
- Interface deve explicar por que um suporte é incompatível e mostrar a transformação final da skill.
