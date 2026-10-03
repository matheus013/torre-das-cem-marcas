# ADR 0001 — Engine e linguagem

## Estado

**Aceita em 1 de outubro de 2026.**

## Contexto

O MVP é um jogo 2D em pixel art, solo e cooperativo online para até quatro jogadores. Precisa de rede host-cliente, simulação autoritativa, interface individual, persistência do mundo do host e exportação desktop.

O ambiente de desenvolvimento atual é um MacBook Pro M1 com 8 GB de memória e Godot 4.6.3 instalado. Unity, Unreal e .NET não estão instalados.

## Alternativas consideradas

### Godot 4.6.3

- pipeline 2D nativo e editor leve;
- GDScript integrado, rápido para protótipos e ferramentas;
- Input por dispositivo e múltiplos Viewports;
- exportação para Windows, macOS e Linux;
- licença MIT e ausência de custo por instalação ou receita;
- menor custo operacional no hardware disponível.

### Unity

- Input System possui gerenciamento de entrada e saída de jogadores e split-screen automático;
- ecossistema 2D maduro;
- exige instalação adicional, C#/.NET e maior dependência do ecossistema de pacotes;
- não oferece vantagem decisiva para o recorte atual que compense a troca de ambiente.

### Unreal Engine

- suporta jogadores locais, Viewports e Paper2D;
- excelente para 3D e projetos de maior peso visual;
- custo de editor, build e complexidade desproporcional ao MVP 2D no hardware atual.

## Decisão

Usar **Godot 4.6.3 stable** e **GDScript tipado**.

- Não usar C# no MVP.
- Fixar a versão minor da engine durante cada marco.
- Atualizações de engine exigem branch própria, importação limpa e execução dos testes de regressão.
- Plugins externos só entram quando removem risco comprovado e possuem manutenção compatível.

## Consequências

- Iteração inicial mais rápida e builds locais mais leves.
- A equipe precisa manter disciplina de tipos, testes e limites de responsabilidade em GDScript.
- A rede da sessão cooperativa integra o MVP; serviços globais do multiverso continuam isolados e posteriores.
- Portes para consoles permanecem decisão posterior e podem exigir fornecedores homologados.

## Fontes oficiais

- [Godot — lista de recursos](https://docs.godotengine.org/en/stable/about/list_of_features.html)
- [Godot — Viewport](https://docs.godotengine.org/en/stable/classes/class_viewport.html)
- [Godot — exportação](https://docs.godotengine.org/en/stable/tutorials/export/index.html)
- [Unity — PlayerInputManager](https://docs.unity3d.com/Packages/com.unity.inputsystem@1.4/api/UnityEngine.InputSystem.PlayerInputManager.html)
- [Unreal — Paper2D](https://dev.epicgames.com/documentation/unreal-engine/paper-2d-in-unreal-engine)
