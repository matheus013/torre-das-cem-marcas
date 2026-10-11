# Avisos de terceiros

O código do jogo é MIT e o conteúdo próprio tem todos os direitos reservados (veja
[LICENSE](LICENSE)). Os componentes abaixo são de outros autores e seguem as licenças
deles. **Não redistribua estes arquivos fora do jogo nem torne público um repositório
que os contenha.**

## Motor

**Godot Engine 4.6** — licença MIT.
Copyright (c) 2014-present Godot Engine contributors.
Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.

As builds exportadas embutem o motor e as bibliotecas dele (FreeType, ENet, mbedTLS e
outras). A tela de créditos precisa exibir o aviso do Godot e os dessas bibliotecas
(`Engine.get_license_text()` e `Engine.get_copyright_info()`), conforme
<https://docs.godotengine.org/en/stable/about/complying_with_licenses.html>.

## Interface

| Pacote | Autor | Arquivos | Licença |
| --- | --- | --- | --- |
| Dark Ages UI v1.0 | Hypnobius (hypnobius.itch.io) | `assets/ui/dark_ages.png` | uso comercial permitido; proibido revender ou redistribuir o pacote. Texto em `assets/ui/DarkAges-LICENSE.txt` |
| Free Medieval Fantasy UI Pack | Kibyra | `assets/ui/medieval_icons.png` | uso comercial permitido; proibido redistribuir ou revender os arquivos. Texto em `assets/ui/MedievalIcons-README.txt` |

## Efeitos, sons e ícones

A lista completa, com o uso de cada pacote no jogo, as restrições e as licenças ainda a
confirmar, fica em [docs/assets-de-terceiros.md](docs/assets-de-terceiros.md#créditos-e-licenças).
Créditos obrigatórios:

- Super Pixel Effects Gigapack — Will Tice / unTied Games
- TTRPG Legacy (Rings e Swords) — Ddant1100

Créditos opcionais, mantidos por cortesia: Free Pixel Fantasy Weapon Pack (domin-dev),
Pixel Art Skill Animations - Lightning (Frostwindz), Free Pixel Magic Sprite Effects
(craftpix), Pixel Combat (Helton Yan), MAGE ICONS BIG PACK (Batareya), Idylwild's Armory,
Dark Ages UI (Hypnobius) e Free Medieval Fantasy UI (Kibyra).

## Ferramentas de desenvolvimento

As dependências de `package.json` (semantic-release e plugins) só rodam no CI de releases,
não entram no jogo, e seguem as licenças registradas em `package-lock.json`.
