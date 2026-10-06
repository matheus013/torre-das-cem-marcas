#!/usr/bin/env python3
"""Gera data/village/village_content.json (moradores de Aresta) e registra seus sprites e os novos
predios e props da vila no manifesto do PixelForge.

Moradores nomeados vem dos documentos 07 e 09 (liderancas das casas e instituicoes); moradores
comuns formam a populacao contextual (documento 64). Personalidade, opinioes publicas e fatos
conhecidos alimentam a mente sistemica e, no modo com IA, o prompt do modelo. Segredos dos
documentos ficam de fora: revelacoes pertencem a narrativa autoral.
Uso: python3 tools/content/build_village.py
"""
import json
import pathlib
import zlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "data" / "village" / "village_content.json"
MANIFEST = ROOT / "art" / "manifest.json"
PROCESS = ROOT / "art" / "process.json"

CHARACTER_PROMPT = ("pixel art, 3/4 top-down rpg game character sprite, single person standing alone, full body from "
                    "head to feet, facing the viewer, small chibi proportions, clean dark outline, muted earthy colors, "
                    "plain white background, {}")
BUILDING_PROMPT = ("pixel art, 3/4 top-down rpg building sprite, one single building alone, clean dark outline, muted "
                   "earthy colors, plain white background, {}")
PROP_PROMPT = ("pixel art, 3/4 top-down rpg prop sprite, one single object alone, clean dark outline, muted earthy "
               "colors, plain white background, {}")

# id, nome, titulo, casa/instituicao, local de trabalho, tracos, valores, personalidade, opinioes, prompt
NAMED = [
    ("alda_serrin", "Alda Serrin", "Regente de Aresta", "Regencia", "conselho",
     {"caution": 0.75, "ambition": 0.6, "empathy": 0.5, "courage": 0.5}, {"vila": 0.9, "dever": 0.8, "poder": 0.6},
     "Velaria serena e calculista; fala pouco e mede cada palavra; pensa sempre na autonomia da vila.",
     "Quer expedicoes bem registradas e sem alarde; teme que crises tirem a autonomia de Aresta.",
     "elegant middle aged woman with long silver hair, pale blue robe with gold trim, holding a sealed scroll"),
    ("nara_quiral", "Nara Quiral", "Diretora da Casa das Expedicoes", "Casa das Expedicoes", "expedicoes",
     {"courage": 0.8, "empathy": 0.6, "ambition": 0.5, "caution": 0.45}, {"conhecimento": 0.8, "vila": 0.7, "dever": 0.7},
     "Nacaria, antiga aventureira; direta, animada com cada descida e exigente com relatorios.",
     "Reuniu o quadro especial para reavaliar o andar 78; cobra relatorio de cada expedicao.",
     "athletic woman with short copper hair and scarred arm, leather explorer coat, map case on her hip"),
    ("dalia_ferral", "Dalia Ferral", "Mestra da Forja", "Casa Ferral", "forja",
     {"caution": 0.8, "courage": 0.6, "empathy": 0.35, "ambition": 0.45}, {"dever": 0.85, "conhecimento": 0.7, "familia": 0.7},
     "Nacaria severa e paciente; respeita trabalho bem feito e desconfia de materiais desconhecidos.",
     "Quer entender todo material da Torre antes de usa-lo; discute precos com os Rotavela.",
     "stern older woman blacksmith with grey braid, heavy leather apron, soot on her face, holding a hammer"),
    ("cassio_rotavela", "Cassio Rotavela", "Primeiro Signatario", "Casa Rotavela", "armazem",
     {"ambition": 0.85, "empathy": 0.4, "caution": 0.55, "courage": 0.4}, {"poder": 0.7, "vila": 0.6, "familia": 0.7},
     "Humano cordial e preciso; sorri enquanto calcula; gosta de comercio e de novos aventureiros.",
     "Defende comercio exterior e expansao; ve cada pedra regenerativa como oportunidade.",
     "well dressed merchant man with neat beard, burgundy coat with gold buttons, ledger book under arm"),
    ("tamar_vardal", "Tamar Vardal", "Custodio da Vigilia", "Casa Vardal", "vigilia",
     {"caution": 0.7, "courage": 0.65, "empathy": 0.5, "ambition": 0.4}, {"justica": 0.85, "dever": 0.8, "vila": 0.7},
     "Diade: uma corrente le a lei ao pe da letra, a outra pesa as consequencias; costuma falar em duas vozes.",
     "Defende fiscalizacao, mas rejeita poderes de emergencia sem prazo.",
     "tall androgynous person in dark blue guard robe with silver crest, two toned hair half black half white"),
    ("ivo_cerne", "Ivo Cerne", "Comandante da Guarda", "Guarda de Aresta", "posto_guarda",
     {"courage": 0.85, "caution": 0.5, "empathy": 0.45, "impulsivity": 0.4}, {"dever": 0.9, "vila": 0.8, "sobrevivencia": 0.6},
     "Humano pragmatico e seco; encontrou uma criatura profunda perto da entrada e ainda pensa nisso.",
     "Quer a entrada da Torre vigiada; pede que os grupos voltem antes de exaurir.",
     "muscular guard commander in steel breastplate and red cape, short black hair, spear in hand"),
    ("maura_salvedra", "Maura Salvedra", "Voz da Enfermaria", "Casa Salvedra", "enfermaria",
     {"empathy": 0.8, "caution": 0.6, "courage": 0.5, "ambition": 0.35}, {"vila": 0.8, "conhecimento": 0.7, "familia": 0.6},
     "Humana medica, gentil com pacientes e dura com quem arrisca a vida a toa.",
     "Defende saude publica e recuperacao de aventureiros; pede cuidado com substancias da Torre.",
     "kind healer woman with dark curly hair tied up, white and green robe, satchel of herbs"),
    ("lior_campelo", "Lior Campelo", "Guardiao da Colheita", "Casa Campelo", "campos",
     {"caution": 0.55, "empathy": 0.6, "courage": 0.45, "ambition": 0.35}, {"vila": 0.75, "familia": 0.7, "sobrevivencia": 0.75},
     "Velario agricultor, voz mansa, preocupado com o solo e com as reservas de comida.",
     "Prefere independencia da masmorra; acha que a Torre nao pode ser a unica fonte de Aresta.",
     "farmer man with straw hat, light brown skin, simple green tunic, holding a hoe"),
    ("brina_pedralva", "Brina Pedralva", "Mestra de Obra", "Casa Pedralva", "obra",
     {"ambition": 0.7, "courage": 0.6, "caution": 0.45, "empathy": 0.5}, {"vila": 0.7, "poder": 0.55, "conhecimento": 0.6},
     "Diade energica, pensa em vigas e fundacoes; quer uma grande obra publica para ganhar assento.",
     "Precisa de pedra regenerativa para os reforcos da vila e valoriza quem entrega material.",
     "sturdy builder woman with rolled sleeves, orange headscarf, tool belt, carrying a wooden beam"),
    ("oren_lumeiro", "Oren Lumeiro", "Curador-Mor", "Casa Lumeiro", "arquivo",
     {"caution": 0.85, "ambition": 0.45, "empathy": 0.4, "courage": 0.3}, {"conhecimento": 0.9, "dever": 0.6, "poder": 0.4},
     "Nacario erudito e reservado; fala por enigmas quando o assunto e perigoso.",
     "Defende contexto antes de divulgar verdades; adora registros e mapas trazidos da Torre.",
     "old scholar man with long white beard, round spectacles, dark purple robe, stack of books"),
    ("elen", "Elen", "Moradora da casa de teto vermelho", "Aresta", "casa_elen",
     {"empathy": 0.75, "courage": 0.4, "caution": 0.5, "impulsivity": 0.45}, {"familia": 0.8, "vila": 0.7, "pertencimento": 0.7},
     "Vizinha acolhedora que abre a casa para o quadro de expedicao; curiosa sobre tudo que acontece.",
     "Gosta de ouvir historias da Torre e se preocupa quando alguem volta ferido.",
     "young woman with long brown hair in a ponytail, simple beige dress with red shawl, holding a basket"),
]

COMMON = [
    ("guarda", "Guarda", 4, "posto_guarda", "town guard soldier with leather armor and spear, blue tabard"),
    ("feirante", "Feirante", 3, "feira", "market vendor with apron and headscarf, carrying a crate of vegetables"),
    ("trabalhador", "Trabalhador", 3, "obra", "construction worker with simple clothes and a pickaxe"),
    ("lavrador", "Lavrador", 3, "campos", "peasant farmer with straw hat carrying a sack of grain"),
    ("aventureiro", "Aventureiro", 3, "expedicoes", "young adventurer with backpack, sword and travel cloak"),
    ("crianca", "Crianca", 3, "praca", "small child with messy hair running, simple tunic, holding a wooden toy"),
]

BUILDINGS = [
    ("forja", "village forge building with big chimney, stone walls, anvil and glowing furnace at the entrance"),
    ("enfermaria", "village infirmary building with white walls, green roof and a herb garden"),
    ("conselho", "village council hall, large stone building with columns, banners and wide stairs"),
    ("arquivo", "old archive building with tall narrow windows, purple roof and scroll sign"),
    ("posto_guarda", "wooden guard watchtower with a small roofed platform and blue flag"),
]
PROPS = [
    ("barraca_frutas", "market stall with striped red and white awning selling fruits and vegetables"),
    ("barraca_tecidos", "market stall with blue awning selling colorful fabrics"),
    ("fonte", "stone plaza fountain with water"),
    ("plantacao", "small farm field with rows of green crops and wooden stakes"),
    ("banco", "wooden park bench"),
    ("galinha", "small white chicken"),
    ("bandeira", "tall wooden pole with a long blue and gold banner"),
    ("andaime_vila", "wooden scaffold with planks next to a pile of stone blocks"),
]


def seed_for(key):
    return zlib.crc32(key.encode()) % 90000 + 1000


def build():
    npcs, assets, sprites = [], [], []
    for npc_id, name, title, house, work, traits, values, personality, opinions, prompt in NAMED:
        npcs.append({"id": npc_id, "name": name, "title": title, "house": house, "work": work, "named": True,
                     "sprite": "npcs/%s" % npc_id, "traits": traits, "values": values,
                     "personality": personality, "opinions": opinions})
        key = "npc_%s" % npc_id
        assets.append({"key": key, "asset_type": "character", "name": name, "metadata": {"role": title},
                       "prompt": CHARACTER_PROMPT.format(prompt), "seeds": [seed_for(key)], "size": 512})
        sprites.append({"key": key, "group": "npcs", "source": "raw/%s_s%d.png" % (key, seed_for(key)),
                        "output": "res://assets/sprites/npcs/%s.png" % npc_id, "block": 12})
    for kind, label, count, work, prompt in COMMON:
        key = "npc_comum_%s" % kind
        assets.append({"key": key, "asset_type": "character", "name": label, "metadata": {"role": kind},
                       "prompt": CHARACTER_PROMPT.format(prompt), "seeds": [seed_for(key)], "size": 512})
        sprites.append({"key": key, "group": "npcs", "source": "raw/%s_s%d.png" % (key, seed_for(key)),
                        "output": "res://assets/sprites/npcs/comum_%s.png" % kind, "block": 12})
        for index in range(count):
            npcs.append({"id": "%s_%d" % (kind, index + 1), "name": "%s %d" % (label, index + 1), "title": label,
                         "house": "Aresta", "work": work, "named": False, "sprite": "npcs/comum_%s" % kind,
                         "traits": {"courage": 0.5, "caution": 0.5, "empathy": 0.5}, "values": {"vila": 0.6},
                         "personality": "Morador comum de Aresta.", "opinions": ""})
    for key, prompt in BUILDINGS:
        manifest_key = "village_%s" % key
        assets.append({"key": manifest_key, "asset_type": "building", "name": key, "metadata": {"village": True},
                       "prompt": BUILDING_PROMPT.format(prompt), "seeds": [seed_for(manifest_key)], "size": 1024})
        sprites.append({"key": manifest_key, "group": "village_buildings", "source": "raw/%s_s%d.png" % (manifest_key, seed_for(manifest_key)),
                        "output": "res://assets/sprites/buildings/%s.png" % key, "block": 8})
    for key, prompt in PROPS:
        manifest_key = "village_%s" % key
        assets.append({"key": manifest_key, "asset_type": "prop", "name": key, "metadata": {"village": True},
                       "prompt": PROP_PROMPT.format(prompt), "seeds": [seed_for(manifest_key)], "size": 1024 if key in ("plantacao", "fonte", "andaime_vila") else 512})
        sprites.append({"key": manifest_key, "group": "village_props", "source": "raw/%s_s%d.png" % (manifest_key, seed_for(manifest_key)),
                        "output": "res://assets/sprites/props/%s.png" % key, "block": 8 if key in ("plantacao", "fonte", "andaime_vila") else 12})
    # Reuse the animated worker families; roles do not need duplicate sprite assets.
    for index, (name, work) in enumerate([("Bento", "mina"), ("Rosa", "mina"),
                                         ("Nilo", "madeira"), ("Lena", "madeira"),
                                         ("Dona Celia", "casa_elen"), ("Seu Abel", "praca")]):
        npcs.append({"id": "morador_%d" % (index + 1), "name": name,
                     "title": {"mina": "Mineiro", "madeira": "Lenhador"}.get(work, "Morador"),
                     "house": "Aresta", "work": work, "named": False,
                     "sprite": "npcs/comum_trabalhador" if work in ("mina", "madeira") else "npcs/comum_feirante",
                     "traits": {"caution": 0.5, "empathy": 0.6}, "values": {"vila": 0.7},
                     "personality": "Cuida da vila e de seus vizinhos.", "opinions": ""})
    npcs.append({"id": "sira_botanica", "name": "Sira Botanica", "title": "Alquimista",
                 "house": "Aresta", "work": "alquimia", "named": True, "sprite": "npcs/comum_feirante",
                 "traits": {"caution": 0.7, "empathy": 0.6}, "values": {"conhecimento": 0.8, "vila": 0.7},
                 "personality": "Prepara remedios com colheitas locais; cuidadosa e curiosa.",
                 "opinions": "Prefere testar cada ingrediente antes de preparar uma mistura."})
    for npc in npcs:
        npc["routine"] = "resident" if npc["id"] in ("elen", "morador_5", "morador_6") else "roaming"
        if npc["work"] in ("forja", "arquivo", "enfermaria", "conselho", "armazem", "alquimia"):
            npc["routine"] = "stationary"
        npc["resource"] = {"mina": "minerio", "madeira": "madeira", "campos": "alimentos"}.get(npc["work"], "")
        if npc["id"] == "lior_campelo":
            npc["routine"], npc["resource"] = "stationary", ""
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps({"version": 1, "npcs": npcs}, ensure_ascii=False, indent=1), encoding="utf-8")
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    known = {entry["key"] for entry in manifest["assets"]}
    manifest["assets"].extend(entry for entry in assets if entry["key"] not in known)
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=1), encoding="utf-8")
    process = json.loads(PROCESS.read_text(encoding="utf-8"))
    known = {entry["key"] for entry in process["sprites"]}
    process["sprites"].extend(entry for entry in sprites if entry["key"] not in known)
    PROCESS.write_text(json.dumps(process, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print("moradores %d, arte %d" % (len(npcs), len(assets)))
    print(" ".join(entry["key"] for entry in assets))


if __name__ == "__main__":
    build()
