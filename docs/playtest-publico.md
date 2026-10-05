# Aresta - Playtest publico

Build gratuita de teste em desenvolvimento, nao um lancamento comercial
nem uma build aprovada para a Steam. Balanceamento e progresso podem mudar.
Nao precisa instalar Godot, Steam ou configurar chave de API para jogar.

## Downloads

- Windows 64-bit: `aresta-windows-x86_64.zip`. Extraia a pasta inteira e abra
  `aresta.exe`. Mantenha `aresta.pck` junto do executavel.
- Linux 64-bit: `aresta-linux-x86_64.tar.gz`. Extraia e execute
  `./aresta.x86_64` dentro da pasta. Se necessario, `chmod +x aresta.x86_64`.
- macOS Intel/Apple Silicon: `aresta-macos-universal.zip`. Extraia e abra
  `Aresta - Prova Tecnica.app`. O nome tecnico ainda e provisorio.

Pacotes de teste sem assinatura comercial. Windows/macOS podem bloquear
downloads de desenvolvedor nao reconhecido. No macOS, consulte
[as instrucoes oficiais de abertura](https://support.apple.com/pt-br/102445)
somente se confiar nesta origem; nao desative a protecao global do sistema.
Notarizacao Apple e assinatura Windows continuam pendentes.

Confira `SHA256SUMS.txt` para verificar integridade. Cada pacote identifica
o commit e a versao da engine. A automacao testa conteudo/importacao e boot
headless nos tres sistemas; isso nao substitui QA grafico ou de controles.

## Testar e reportar

Comece em **Novo jogo**, prepare sua build em Aresta e entre na Torre.
Teclado/mouse e mapeamento de Xbox/PS4/PS5 estao implementados; controles
fisicos USB/Bluetooth e Steam Input ainda precisam de validacao externa.
Co-op e experimental: host e clientes precisam da mesma build; acesso pela
internet pode depender de firewall e encaminhamento de portas.
Moradores com IA externa sao opcionais, desligados por padrao e nao
necessarios para o jogo. Audio e outros polimentos ainda estao em producao.

Guarde uma copia dos seus saves antes de atualizar. Eles usam a pasta de
dados do Godot para `Aresta - Prova Tecnica`; compatibilidade historica ainda
esta em validacao. Estas builds nao incluem um atualizador automatico.

Reporte problemas em [Issues](https://github.com/matheus013/torre-das-cem-marcas/issues),
com tag do playtest, sistema, hardware, passos e imagem/log quando possivel.
Nao publique chaves de API, credenciais ou dados pessoais nos relatos.
Downloads: [Releases](https://github.com/matheus013/torre-das-cem-marcas/releases).

Repositorio publico nao significa relicenciamento automatico de codigo,
arte ou historia. Nenhuma licenca open-source nova e definida nesta entrega.
