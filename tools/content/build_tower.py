#!/usr/bin/env python3
"""Gera data/tower/tower_content.json: biomas, cem andares, inimigos, materiais, saques e chefes da Torre.

Segue a divisao do documento 05 (dez regioes) e os Limiares dos documentos 28 a 37: um chefe por regiao no
andar do Limiar, mais a Camara Refeita no andar 4. Andares comuns sao enormes e exploraveis; andares de chefe
sao arenas pequenas. Tambem registra em art/manifest.json e art/process.json os sprites de cada bioma para o
PixelForge (tiles, props, inimigos e chefes); entradas existentes sao preservadas.
Uso: python3 tools/content/build_tower.py
"""
import json
import pathlib
import zlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "data" / "tower" / "tower_content.json"
MANIFEST = ROOT / "art" / "manifest.json"
PROCESS = ROOT / "art" / "process.json"

TILE_PROMPT = ("pixel art, seamless tileable top-down ground texture, {}, full frame, flat even lighting, "
               "subtle low contrast detail, no border, no objects")
PROP_PROMPT = ("pixel art, 3/4 top-down rpg prop sprite, one single object alone, clean dark outline, muted earthy "
               "colors, plain white background, {}")
MONSTER_PROMPT = ("pixel art, 3/4 top-down rpg enemy sprite, single creature alone, whole body visible, clean dark "
                  "outline, muted colors, plain white background, {}")
BOSS_PROMPT = MONSTER_PROMPT.format("large boss monster, {}, imposing")

# ------------------------------------------------------------------ biomas (documento 05 e 28-37)

BIOMES = [
    {
        "id": "galerias", "name": "Galerias Refeitas", "floors": [1, 7], "ambient": "5c6680",
        "mechanic": "Cicatrizacao", "hazard": {"type": "slam", "label": "Parede em formacao", "radius": 70, "delay": 1.2, "interval": 7.0, "damage": 14},
        "tile": None, "tile_sprite": "tiles/floor_tower",
        "props": ["props/pillar", "props/rocks", "props/crates"],
        "race": None,
        "enemies": ["larva_de_junta", "raspador_de_junta", "sentinela_de_cal", "emboscado_de_reboco", "molde_de_ferramenta", "escora_hostil", "vigia_moldado"],
        "materials": [],
        "floor_names": {1: "Patio das Marcas", 2: "Vias de Extracao", 3: "Vias de Extracao", 4: "Camara Refeita",
                        5: "Fratura Recente", 6: "Fratura Recente", 7: "Porta das Sete Molduras"},
    },
    {
        "id": "bosque", "name": "Bosque dos Ventos Presos", "floors": [8, 16], "ambient": "6a8a7a",
        "mechanic": "Mares de Vento", "hazard": {"type": "gust", "label": "Rajada", "length": 520, "width": 90, "delay": 1.1, "interval": 6.0, "damage": 10, "push": 140},
        "tile": "mossy mineral ground with pale green reeds stubble and small pebbles, windswept",
        "props": [("arvore_oca", "hollow mineral tree with pale bark and holes, wind swept branches"),
                  ("juncos", "tall cluster of mineral reeds, pale green and grey"),
                  ("arco_de_pedra", "natural stone arch bridge fragment covered in moss")],
        "race": {"id": "ventania", "name": "Ventania", "trait": "barrier_breaker", "stat_profile": {"health": 0.9, "damage": 1.0, "speed": 1.2, "attack_interval": 0.9},
                 "description": "Criaturas leves moldadas pelas correntes; atravessam defesas apressadas."},
        "enemies": [
            ("semeador_de_juncos", "Semeador de Juncos", "nascente", "common", "swarm", "melee", 34, 8, 66, 0.7, "small hopping seed creature made of reeds and pale leaves, tiny legs"),
            ("planador_de_rajada", "Planador de Rajada", "maduro", "common", "telegraphed_shot", "ranged", 48, 11, 34, 1.5, "gliding membrane flying creature with long thin wings, pale green, gust spines"),
            ("casca_de_pressao", "Casca de Pressao", "maduro", "common", "erode_cover", "melee", 64, 12, 40, 0.8, "round armored seed pod beast swollen with pressure, cracked shell leaking air"),
            ("predador_da_calmaria", "Predador da Calmaria", "evoluido", "elite", "wall_ambush", "ambusher", 88, 18, 50, 1.1, "sleek grey feline predator with mineral plates, glowing green eyes, lurking"),
        ],
        "materials": [("junco_mineral", "Junco Mineral", "common"), ("membrana_de_pressao", "Membrana de Pressao", "uncommon")],
        "floor_names": {8: "Desfiladeiros do Sopro", 9: "Desfiladeiros do Sopro", 10: "Bosque Oco", 11: "Bosque Oco", 12: "Bosque Oco",
                        13: "Calmaria Morta", 14: "Calmaria Morta", 15: "Calmaria Morta", 16: "Pulmao da Pedra"},
    },
    {
        "id": "manto", "name": "Manto dos Esporos", "floors": [17, 27], "ambient": "7a6a8a",
        "mechanic": "Rede Micelial", "hazard": {"type": "zone", "label": "Nuvem de esporos", "radius": 85, "delay": 1.0, "interval": 6.5, "damage": 6, "duration": 4.0},
        "tile": "damp dark forest floor covered with mycelium threads, small glowing amber spores, purple moss",
        "props": [("cogumelo_gigante", "giant mushroom with wide purple cap and glowing amber spots"),
                  ("tronco_oco", "fallen hollow log covered with small fungi"),
                  ("poca_ambar", "small pool of glowing amber liquid surrounded by stones")],
        "race": {"id": "micelar", "name": "Micelar", "trait": "effect_feeder", "stat_profile": {"health": 1.15, "damage": 0.95, "speed": 0.9, "attack_interval": 1.05},
                 "description": "Organismos da rede que se alimentam de efeitos persistentes e materia em decomposicao."},
        "enemies": [
            ("esporinho", "Esporinho", "nascente", "common", "swarm", "melee", 36, 8, 60, 0.7, "tiny walking mushroom creature puffing spores"),
            ("tecelao_micelial", "Tecelao Micelial", "maduro", "common", "mark_target", "ranged", 50, 12, 30, 1.4, "spider like fungus creature weaving glowing mycelium threads"),
            ("sentinela_de_chapeu", "Sentinela de Chapeu", "maduro", "common", "enemy_barrier", "support", 70, 8, 22, 1.8, "stout mushroom guardian with thick shield-like cap"),
            ("devorador_branco", "Devorador Branco", "evoluido", "elite", "incorporate_objects", "melee", 96, 18, 40, 1.2, "pale white sterile beast without decay, smooth bone-like skin, hollow eyes"),
        ],
        "materials": [("lanterna_de_esporo", "Lanterna de Esporo", "common"), ("ambar_micelial", "Ambar Micelial", "uncommon")],
        "floor_names": {17: "Borda Seca", 18: "Borda Seca", 19: "Copa Baixa", 20: "Copa Baixa", 21: "Copa Baixa",
                        22: "Encruzilhada das Lanternas", 23: "Encruzilhada das Lanternas", 24: "Encruzilhada das Lanternas",
                        25: "Branco Esteril", 26: "Branco Esteril", 27: "No-Mae"},
    },
    {
        "id": "bacias", "name": "Bacias do Quarto Pulso", "floors": [28, 39], "ambient": "5a7a92",
        "mechanic": "Ciclo das Quatro Aguas", "hazard": {"type": "zone", "label": "Lamina d'agua", "radius": 110, "delay": 1.3, "interval": 7.0, "damage": 4, "duration": 5.0, "slow": 0.35},
        "tile": "wet cave stone floor with shallow puddles and blue green algae, mineral terraces",
        "props": [("comporta", "ancient stone sluice gate post with rusty metal wheel"),
                  ("colonia_de_conchas", "cluster of large shells and barnacles on a rock"),
                  ("barco_naufragado", "small wrecked wooden boat half broken")],
        "race": {"id": "lodoso", "name": "Lodoso", "trait": "stone_skin", "stat_profile": {"health": 1.2, "damage": 1.0, "speed": 0.85, "attack_interval": 1.1},
                 "description": "Fauna de lama e conchas, lenta e protegida por camadas minerais."},
        "enemies": [
            ("filtrador", "Filtrador", "nascente", "common", "swarm", "melee", 38, 8, 58, 0.75, "small amphibian filter feeder with wide mouth and blue skin"),
            ("anfibio_de_canal", "Anfibio de Canal", "maduro", "common", "telegraphed_shot", "ranged", 52, 12, 32, 1.5, "frog like amphibian spitting water, teal skin with orange spots"),
            ("predador_de_lama", "Predador de Lama", "maduro", "common", "wall_ambush", "ambusher", 66, 13, 44, 0.85, "mud covered crocodile like predator, brown and grey"),
            ("colosso_de_conchas", "Colosso de Conchas", "evoluido", "elite", "enemy_barrier", "support", 110, 14, 24, 1.6, "large crab like creature carrying a colony of shells on its back"),
        ],
        "materials": [("lodo_mineral", "Lodo Mineral", "common"), ("perola_de_refluxo", "Perola de Refluxo", "rare")],
        "floor_names": {28: "Pedras de Vazante", 29: "Pedras de Vazante", 30: "Pedras de Vazante", 31: "Canais de Pressao",
                        32: "Canais de Pressao", 33: "Canais de Pressao", 34: "Bacia dos Naufragios", 35: "Bacia dos Naufragios",
                        36: "Bacia dos Naufragios", 37: "Leito Oco", 38: "Leito Oco", 39: "Comporta do Quarto Pulso"},
    },
    {
        "id": "ermo", "name": "Ermo do Trovao Preso", "floors": [40, 51], "ambient": "6a5a8a",
        "mechanic": "Acumulo e Descarga", "hazard": {"type": "slam", "label": "Descarga", "radius": 80, "delay": 1.0, "interval": 5.0, "damage": 18},
        "tile": "black volcanic glass ground with thin copper veins and small cracks, dark and shiny",
        "props": [("cristal_carregado", "tall jagged violet crystal crackling with electricity"),
                  ("torre_de_cobre", "twisted copper spire rising from black glass"),
                  ("posto_vitrificado", "ruined vitrified stone outpost wall fragment")],
        "race": {"id": "carregado", "name": "Carregado", "trait": "adaptive_shell", "stat_profile": {"health": 1.05, "damage": 1.15, "speed": 1.0, "attack_interval": 0.95},
                 "description": "Carapacas que acumulam carga e se adaptam a impactos repetidos."},
        "enemies": [
            ("escavador_vitreo", "Escavador Vitreo", "nascente", "common", "swarm", "melee", 40, 9, 62, 0.7, "small burrowing beetle with black glass shell"),
            ("carapaca_carregada", "Carapaca Carregada", "maduro", "common", "erode_cover", "melee", 70, 14, 40, 0.85, "armored beast with crystal spikes glowing violet electricity"),
            ("cacador_de_metal", "Cacador de Metal", "maduro", "common", "mark_target", "ranged", 54, 13, 34, 1.3, "lean predator with copper antennae shooting sparks"),
            ("ninho_de_descarga", "Ninho de Descarga", "evoluido", "elite", "incorporate_objects", "support", 115, 20, 20, 1.3, "living crystal nest creature pulsing with lightning"),
        ],
        "materials": [("vidro_negro", "Vidro Negro", "common"), ("cristal_de_carga", "Cristal de Carga", "rare")],
        "floor_names": {40: "Planicies de Vidro Negro", 41: "Planicies de Vidro Negro", 42: "Planicies de Vidro Negro",
                        43: "Campos de Carga", 44: "Campos de Carga", 45: "Campos de Carga", 46: "Abrigos Quebrados",
                        47: "Abrigos Quebrados", 48: "Abrigos Quebrados", 49: "Tempestade Espelhada", 50: "Tempestade Espelhada",
                        51: "Coroa dos Condutores"},
    },
    {
        "id": "arquivo", "name": "Arquivo das Rotas Mortas", "floors": [52, 63], "ambient": "8a7a62",
        "mechanic": "Cartografia Reativa", "hazard": {"type": "line", "label": "Rota que se redesenha", "length": 600, "width": 70, "delay": 1.2, "interval": 6.0, "damage": 16},
        "tile": "ancient engraved stone road tiles with carved route lines and faded map symbols, beige",
        "props": [("marco_movel", "tall carved stone milestone marker with arrows"),
                  ("instrumento_de_medida", "old brass measuring instrument on a stone pedestal"),
                  ("estante_de_mapas", "stone shelf full of rolled maps and scrolls")],
        "race": {"id": "cartografo", "name": "Cartografo", "trait": "wall_camouflage", "stat_profile": {"health": 1.0, "damage": 1.1, "speed": 1.05, "attack_interval": 1.0},
                 "description": "Seres que seguem marcos e se escondem em rotas desenhadas."},
        "enemies": [
            ("tracador", "Tracador", "nascente", "common", "swarm", "melee", 40, 10, 60, 0.7, "small lizard leaving glowing mineral lines behind its tail"),
            ("devorador_de_tinta", "Devorador de Tinta", "maduro", "common", "erode_cover", "melee", 72, 14, 42, 0.85, "ink black slug creature eating paper scraps"),
            ("sinaleiro_falso", "Sinaleiro Falso", "maduro", "common", "telegraphed_shot", "ranged", 56, 14, 30, 1.4, "creature disguised as a signpost with a hidden eye"),
            ("cartografo_oco", "Cartografo Oco", "evoluido", "elite", "mark_target", "ranged", 104, 20, 32, 1.2, "hollow robed figure made of maps and measuring rods"),
        ],
        "materials": [("tinta_mineral", "Tinta Mineral", "common"), ("marco_gravado", "Marco Gravado", "rare")],
        "floor_names": {52: "Estradas Sobrepostas", 53: "Estradas Sobrepostas", 54: "Estradas Sobrepostas", 55: "Salas de Medida",
                        56: "Salas de Medida", 57: "Salas de Medida", 58: "Oficinas Desviadas", 59: "Oficinas Desviadas",
                        60: "Oficinas Desviadas", 61: "Duas Marchas", 62: "Duas Marchas", 63: "Marco Cego"},
    },
    {
        "id": "planicie", "name": "Planicie dos Adormecidos", "floors": [64, 72], "ambient": "8a6a62",
        "mechanic": "Movimento Colossal", "hazard": {"type": "donut", "label": "Respiracao do colosso", "radius": 220, "inner": 90, "delay": 1.5, "interval": 8.0, "damage": 18},
        "tile": "mineral skin ground of a sleeping colossus with moss patches and pores, warm brown and grey",
        "props": [("arvore_parasita", "parasitic tree growing from rocky skin with red roots"),
                  ("crista_ossea", "giant bone ridge emerging from the ground"),
                  ("respiradouro", "breathing vent hole in rocky skin with steam")],
        "race": {"id": "parasitario", "name": "Parasitario", "trait": "effect_feeder", "stat_profile": {"health": 1.25, "damage": 1.05, "speed": 0.9, "attack_interval": 1.05},
                 "description": "Ecossistemas que vivem sobre colossos e se nutrem de suas feridas."},
        "enemies": [
            ("limpador", "Limpador", "nascente", "common", "swarm", "melee", 44, 10, 58, 0.7, "small cleaner bird like creature with long beak"),
            ("predador_de_dobra", "Predador de Dobra", "maduro", "common", "wall_ambush", "ambusher", 78, 16, 46, 0.85, "flat predator hiding in skin folds, wide jaws"),
            ("migrante", "Migrante", "maduro", "common", "erode_cover", "melee", 84, 15, 38, 0.9, "six legged migrating herd beast with mossy back"),
            ("colosso_menor", "Colosso Menor", "evoluido", "elite", "incorporate_objects", "melee", 140, 22, 24, 1.3, "small colossus creature with rocky body and moss, sleepy eyes"),
        ],
        "materials": [("pele_mineral", "Pele Mineral", "common"), ("seiva_colossal", "Seiva Colossal", "rare")],
        "floor_names": {64: "Horizonte Impossivel", 65: "Dorso das Estacoes", 66: "Dorso das Estacoes", 67: "Dorso das Estacoes",
                        68: "Vales de Pulso", 69: "Vales de Pulso", 70: "Campo das Mudas", 71: "Campo das Mudas",
                        72: "Palpebra do Horizonte"},
    },
    {
        "id": "eixos", "name": "Eixos Partidos", "floors": [73, 81], "ambient": "5a6a8a",
        "mechanic": "Orientacao Gravitacional", "hazard": {"type": "pull", "label": "Poco de vetor", "radius": 180, "delay": 1.4, "interval": 7.0, "damage": 16, "strength": 160},
        "tile": "dark metal floor plates with cables and anchor bolts, scratched, blue grey",
        "props": [("ancora_gravitacional", "heavy anchor weight hanging from a broken cable"),
                  ("eixo_partido", "broken rotating metal axis pillar"),
                  ("carretel_de_cabo", "large cable spool with thick rope")],
        "race": {"id": "aderente", "name": "Aderente", "trait": "barrier_breaker", "stat_profile": {"health": 1.0, "damage": 1.15, "speed": 1.15, "attack_interval": 0.95},
                 "description": "Criaturas que atravessam superficies e cortam ancoragens."},
        "enemies": [
            ("aderente_menor", "Aderente Menor", "nascente", "common", "swarm", "melee", 46, 11, 64, 0.7, "suction cup creature clinging with many small arms"),
            ("planador_de_eixo", "Planador de Eixo", "maduro", "common", "telegraphed_shot", "ranged", 60, 15, 36, 1.3, "flat gliding creature with metallic fins"),
            ("ilha_pesada", "Ilha Pesada", "maduro", "common", "enemy_barrier", "support", 96, 12, 18, 1.7, "heavy floating rock creature with tiny legs underneath"),
            ("cortador_de_ancoras", "Cortador de Ancoras", "evoluido", "elite", "erode_cover", "melee", 130, 24, 50, 1.0, "mantis like predator with blade arms cutting cables"),
        ],
        "materials": [("cabo_de_lastro", "Cabo de Lastro", "common"), ("fragmento_de_eixo", "Fragmento de Eixo", "rare")],
        "floor_names": {73: "Escadas Laterais", 74: "Escadas Laterais", 75: "Pocos de Vetor", 76: "Pocos de Vetor", 77: "Pocos de Vetor",
                        78: "Camara do Primeiro Lastro", 79: "Queda das Ancoras", 80: "Queda das Ancoras", 81: "Eixo Zero"},
    },
    {
        "id": "campos", "name": "Campos do Quase", "floors": [82, 93], "ambient": "7a8a6a",
        "mechanic": "Possibilidades Transitorias", "hazard": {"type": "meteor", "label": "Possibilidade que se fixa", "radius": 75, "count": 4, "spread": 320, "delay": 1.3, "interval": 6.5, "damage": 22},
        "tile": "overgrown ruined garden floor with broken tiles and flowers, dreamlike pale colors",
        "props": [("ruina_impossivel", "ruined arch of a city that never existed, translucent edges"),
                  ("jardim_possivel", "flower bed with flowers in impossible colors"),
                  ("fixador", "strange pillar organism that solidifies the air around it")],
        "race": {"id": "possivel", "name": "Possivel", "trait": "adaptive_shell", "stat_profile": {"health": 1.1, "damage": 1.15, "speed": 1.05, "attack_interval": 1.0},
                 "description": "Criaturas que alternam versoes de si mesmas e aprendem com o que as atinge."},
        "enemies": [
            ("eco_de_presa", "Eco de Presa", "nascente", "common", "swarm", "melee", 48, 12, 62, 0.7, "translucent echo of a small deer creature, ghostly"),
            ("flor_de_escolha", "Flor de Escolha", "maduro", "common", "mark_target", "ranged", 62, 16, 26, 1.3, "carnivorous flower with two different heads"),
            ("cacador_de_versoes", "Cacador de Versoes", "maduro", "common", "wall_ambush", "ambusher", 84, 18, 48, 0.85, "hound with flickering doubled outline"),
            ("fixador_vivo", "Fixador Vivo", "evoluido", "elite", "enemy_barrier", "support", 150, 18, 22, 1.5, "crystalline organism that solidifies reality around it"),
        ],
        "materials": [("petala_possivel", "Petala Possivel", "uncommon"), ("semente_do_quase", "Semente do Quase", "rare")],
        "floor_names": {82: "Bifurcacoes Vivas", 83: "Bifurcacoes Vivas", 84: "Bifurcacoes Vivas", 85: "Bifurcacoes Vivas",
                        86: "Jardins Possiveis", 87: "Jardins Possiveis", 88: "Jardins Possiveis", 89: "Ruinas do Nunca",
                        90: "Ruinas do Nunca", 91: "Ruinas do Nunca", 92: "Horizonte Reduzido", 93: "Ultima Escolha"},
    },
    {
        "id": "obra", "name": "Obra Inacabada", "floors": [94, 100], "ambient": "7a6a5a",
        "mechanic": "Convergencia Regional", "hazard": {"type": "mixed", "label": "Convergencia", "interval": 5.0, "damage": 24},
        "tile": "unfinished construction floor with scaffold planks, stone blocks and chalk marks",
        "props": [("andaime", "wooden scaffold with ropes and planks"),
                  ("molde_de_lugar", "half built statue mold of a building"),
                  ("monumento_numerado", "stone monument covered with numbers and marks")],
        "race": {"id": "sem_autor", "name": "Sem Autor", "trait": "effect_feeder", "stat_profile": {"health": 1.3, "damage": 1.2, "speed": 1.0, "attack_interval": 1.0},
                 "description": "Formas montadas por processos sem autor a partir de todas as regioes."},
        "enemies": [
            ("operario_sem_autor", "Operario Sem Autor", "maduro", "common", "swarm", "melee", 60, 14, 60, 0.7, "faceless worker figure made of bricks and rope"),
            ("molde_vivo", "Molde Vivo", "maduro", "common", "erode_cover", "melee", 96, 18, 42, 0.85, "living plaster mold creature copying shapes"),
            ("marca_numerada", "Marca Numerada", "evoluido", "common", "mark_target", "ranged", 74, 18, 30, 1.2, "floating stone tablet with glowing number carved"),
            ("eco_regional", "Eco Regional", "alfa", "elite", "incorporate_objects", "melee", 170, 26, 34, 1.2, "patchwork beast made of pieces of all previous biomes"),
        ],
        "materials": [("material_sem_autor", "Material Sem Autor", "rare"), ("marca_de_mandato", "Marca de Mandato", "epic")],
        "floor_names": {94: "Vestibulo das Consequencias", 95: "Oficinas Sem Autor", 96: "Oficinas Sem Autor",
                        97: "Galeria dos Seis Fundamentos", 98: "Camara das Cem Marcas", 99: "Ultimo Limiar", 100: "Sala Sem Numero"},
    },
]

# ------------------------------------------------------------------ chefes (um por Limiar, mais o andar 4)

A = lambda kind, **params: dict({"type": kind}, **params)  # noqa: E731

BOSSES = [
    {"floor": 4, "biome": "galerias", "id": "guardiao_de_enxerto", "existing": True, "name": "Guardiao de Enxerto",
     "health": 900, "damage": 24, "speed": 38,
     "abilities": [A("slam", targets=1, radius=80, delay=1.3, damage=26, cooldown=4.5),
                   A("nova", radius=150, delay=1.4, damage=30, cooldown=7.0),
                   A("summon", count=2, cooldown=14.0, phase=2)],
     "phases": [0.6], "enrage": 150},
    {"floor": 7, "biome": "galerias", "id": "refeitor", "name": "O Refeitor",
     "prompt": "reconstruction golem made of moving stone frames and arches, glowing cyan seams, seven floating stone frames around it",
     "health": 1400, "damage": 28, "speed": 40,
     "abilities": [A("cross", length=560, width=70, delay=1.4, damage=34, cooldown=6.0),
                   A("slam", targets=2, radius=85, delay=1.2, damage=28, cooldown=4.5),
                   A("donut", radius=300, inner=110, delay=1.6, damage=36, cooldown=9.0, phase=2),
                   A("summon", count=3, cooldown=16.0, phase=2)],
     "phases": [0.65, 0.3], "enrage": 180},
    {"floor": 16, "biome": "bosque", "id": "pastor_das_correntes", "name": "Pastor das Correntes",
     "prompt": "huge migratory sky whale like creature trapped by mineral membranes, pale green and grey, wind swirling",
     "health": 2200, "damage": 32, "speed": 34,
     "abilities": [A("gust", length=640, width=110, delay=1.3, damage=26, push=180, cooldown=5.0),
                   A("barrage", count=12, speed=260, damage=18, cooldown=7.0),
                   A("pull", radius=360, delay=1.8, damage=40, strength=200, cooldown=11.0, phase=2),
                   A("meteor", count=5, radius=80, spread=360, delay=1.4, damage=30, cooldown=9.0, phase=2)],
     "phases": [0.6, 0.3], "enrage": 180},
    {"floor": 27, "biome": "manto", "id": "guardia_do_no_mae", "name": "Guardia do No-Mae",
     "prompt": "giant fungal queen creature rooted in mycelium web, glowing amber nodes, half covered with sterile white crust",
     "health": 3200, "damage": 36, "speed": 26,
     "abilities": [A("zone", targets=3, radius=95, delay=1.1, damage=10, duration=6.0, cooldown=6.0),
                   A("nova", radius=170, delay=1.4, damage=40, cooldown=7.5),
                   A("summon", count=4, cooldown=13.0),
                   A("donut", radius=340, inner=120, delay=1.6, damage=44, cooldown=10.0, phase=2)],
     "phases": [0.6, 0.3], "enrage": 200},
    {"floor": 39, "biome": "bacias", "id": "guardiao_da_comporta", "name": "Guardiao da Comporta",
     "prompt": "ancient leviathan amphibian guarding a stone sluice gate, blue scales, shell armor, water dripping",
     "health": 4600, "damage": 42, "speed": 32,
     "abilities": [A("line", count=3, spread=0.35, length=620, width=90, delay=1.3, damage=42, cooldown=6.0),
                   A("zone", targets=4, radius=110, delay=1.2, damage=12, duration=6.0, slow=0.4, cooldown=7.0),
                   A("charge", width=110, delay=1.2, damage=50, cooldown=9.0),
                   A("barrage", count=16, speed=240, damage=22, cooldown=8.0, phase=2)],
     "phases": [0.6, 0.3], "enrage": 210},
    {"floor": 51, "biome": "ermo", "id": "coroa_dos_condutores", "name": "Coroa dos Condutores",
     "prompt": "floating crown shaped storm entity made of copper rods and violet crystals, lightning arcs",
     "health": 6200, "damage": 48, "speed": 30,
     "abilities": [A("meteor", count=7, radius=85, spread=380, delay=1.1, damage=46, cooldown=5.5),
                   A("cross", length=640, width=80, delay=1.3, damage=50, cooldown=7.0),
                   A("barrage", count=20, speed=280, damage=24, cooldown=8.0),
                   A("nova", radius=200, delay=1.3, damage=56, cooldown=9.0, phase=2)],
     "phases": [0.65, 0.35], "enrage": 220},
    {"floor": 63, "biome": "arquivo", "id": "guardiao_do_marco_cego", "name": "Guardiao do Marco Cego",
     "prompt": "giant stone milestone golem covered with engraved routes and arrows pointing nowhere, beige stone, ink veins",
     "health": 8000, "damage": 54, "speed": 34,
     "abilities": [A("line", count=5, spread=0.3, length=680, width=80, delay=1.3, damage=52, cooldown=6.0),
                   A("slam", targets=4, radius=95, delay=1.1, damage=48, cooldown=5.0),
                   A("charge", width=120, delay=1.1, damage=60, cooldown=8.0),
                   A("donut", radius=360, inner=120, delay=1.5, damage=60, cooldown=10.0, phase=2)],
     "phases": [0.6, 0.3], "enrage": 230},
    {"floor": 72, "biome": "planicie", "id": "palpebra_do_horizonte", "name": "Palpebra do Horizonte",
     "prompt": "enormous half asleep eye creature embedded in rocky mountain skin, heavy eyelid, moss and roots",
     "health": 10500, "damage": 60, "speed": 0,
     "abilities": [A("donut", radius=380, inner=130, delay=1.6, damage=64, cooldown=8.0),
                   A("line", count=4, spread=0.5, length=700, width=100, delay=1.4, damage=60, cooldown=6.5),
                   A("summon", count=5, cooldown=12.0),
                   A("meteor", count=8, radius=90, spread=400, delay=1.3, damage=56, cooldown=7.0, phase=2)],
     "phases": [0.6, 0.3], "enrage": 240},
    {"floor": 81, "biome": "eixos", "id": "guardiao_do_eixo_zero", "name": "Guardiao do Eixo Zero",
     "prompt": "gyroscope shaped metal guardian with rotating rings and broken anchors, blue steel, gravity distortion",
     "health": 13000, "damage": 66, "speed": 36,
     "abilities": [A("pull", radius=400, delay=1.6, damage=70, strength=240, cooldown=9.0),
                   A("cross", length=700, width=90, delay=1.2, damage=66, cooldown=6.0),
                   A("barrage", count=24, speed=300, damage=30, cooldown=7.0),
                   A("charge", width=120, delay=1.0, damage=72, cooldown=8.0, phase=2)],
     "phases": [0.6, 0.3], "enrage": 240},
    {"floor": 93, "biome": "campos", "id": "guardiao_da_ultima_escolha", "name": "Guardiao da Ultima Escolha",
     "prompt": "three headed guardian made of overlapping translucent versions of itself, pale garden colors, flowers",
     "health": 16000, "damage": 72, "speed": 40,
     "abilities": [A("meteor", count=9, radius=90, spread=420, delay=1.2, damage=70, cooldown=6.0),
                   A("donut", radius=380, inner=120, delay=1.4, damage=74, cooldown=8.0),
                   A("line", count=6, spread=0.45, length=700, width=80, delay=1.3, damage=70, cooldown=6.5),
                   A("summon", count=5, cooldown=12.0, phase=2)],
     "phases": [0.65, 0.35], "enrage": 250},
    {"floor": 100, "biome": "obra", "id": "regente_centesimo", "name": "Regente Centesimo",
     "prompt": "regal construct of numbered stone tablets and unfinished architecture, crown of one hundred marks, gold and stone",
     "health": 22000, "damage": 80, "speed": 38,
     "abilities": [A("cross", length=720, width=90, delay=1.2, damage=80, cooldown=5.5),
                   A("meteor", count=10, radius=95, spread=440, delay=1.2, damage=78, cooldown=6.0),
                   A("donut", radius=400, inner=130, delay=1.4, damage=84, cooldown=8.0),
                   A("barrage", count=28, speed=300, damage=34, cooldown=7.0),
                   A("pull", radius=420, delay=1.5, damage=86, strength=260, cooldown=10.0, phase=2),
                   A("summon", count=6, cooldown=12.0, phase=2)],
     "phases": [0.7, 0.4, 0.15], "enrage": 260},
]

# Novas combinacoes por tamanho de grupo (documento 58): habilidades extras de dois, tres e quatro jogadores.
# Calibragem de Vida dos chefes pela sonda tools/bench/balance_probe.gd (decisao 566): alvo de
# cerca de 75 s em solo no nivel do andar.
BOSS_HEALTH_CALIBRATION = {
    "guardiao_de_enxerto": 2.5,
    "refeitor": 2.5,
    "pastor_das_correntes": 2.5,
    "guardia_do_no_mae": 2.0,
    "guardiao_da_comporta": 1.8,
    "coroa_dos_condutores": 1.6,
    "guardiao_do_marco_cego": 1.5,
    "palpebra_do_horizonte": 1.4,
    "guardiao_do_eixo_zero": 1.3,
    "guardiao_da_ultima_escolha": 1.2,
    "regente_centesimo": 1.0
}
# O Regente recebe golpes menores: a sonda mostrou o andar 100 intransponivel.
REGENTE_DAMAGE_SCALE = 0.6

PARTY_ABILITIES = {
    "2": [A("slam", targets=2, radius=80, delay=1.2, damage_ratio=0.8, cooldown=8.0)],
    "3": [A("line", count=2, spread=0.8, length=560, width=70, delay=1.3, damage_ratio=0.9, cooldown=9.0)],
    "4": [A("meteor", count=4, radius=80, spread=360, delay=1.3, damage_ratio=0.9, cooldown=8.0)],
}


def seed_for(key):
    return zlib.crc32(key.encode()) % 90000 + 1000


def explore_size(floor):
    """Andares comuns crescem com a profundidade: de 3200x2400 a 4800x3600."""
    grow = min(1.0, (floor - 1) / 60.0)
    return [int(3200 + 1600 * grow), int(2400 + 1200 * grow)]


def build():
    biomes, floors, enemies, races, items, loot_tables, bosses = [], [], [], [], [], [], []
    boss_floors = {boss["floor"]: boss for boss in BOSSES}
    art_sprites, manifest_assets = [], []
    for biome in BIOMES:
        tile = biome["tile_sprite"] if biome.get("tile_sprite") else "tiles/floor_%s" % biome["id"]
        props = biome["props"] if isinstance(biome["props"][0], str) else ["props/%s_%s" % (biome["id"], key) for key, _ in biome["props"]]
        enemy_ids = []
        if biome["race"]:
            races.append(biome["race"])
        for entry in biome["enemies"]:
            if isinstance(entry, str):
                enemy_ids.append(entry)
                continue
            eid, name, rank, klass, mechanic, kind, health, damage, speed, interval, prompt = entry
            enemy_ids.append(eid)
            table = "saque_%s" % eid
            materials = biome["materials"]
            entries = [{"item_id": "pedra_regenerativa", "chance": 0.35, "minimum": 1, "maximum": 1}]
            if materials:
                entries.append({"item_id": materials[0][0], "chance": 0.7 if klass == "common" else 1.0, "minimum": 1, "maximum": 2 if klass == "common" else 3})
                entries.append({"item_id": materials[1][0], "chance": 0.08 if klass == "common" else 0.35, "minimum": 1, "maximum": 1})
            loot_tables.append({"id": table, "entries": entries})
            enemies.append({
                "id": eid, "name": name, "race_id": biome["race"]["id"], "rank_id": rank, "encounter_class": klass,
                "mechanic": mechanic, "kind": kind, "health": health, "damage": damage, "speed": speed,
                "attack_interval": interval, "loot_table_id": table, "allow_affixes": True, "biome": biome["id"],
                "lore": "%s do bioma %s." % (name, biome["name"]),
            })
            manifest_assets.append({"key": "tower_%s" % eid, "asset_type": "monster", "name": name,
                                    "metadata": {"biome": biome["id"]}, "prompt": MONSTER_PROMPT.format(prompt),
                                    "seeds": [seed_for(eid)], "size": 512})
            art_sprites.append({"key": eid, "group": "tower_enemies", "source": "raw/tower_%s_s%d.png" % (eid, seed_for(eid)),
                                "output": "res://assets/sprites/enemies/%s.png" % eid, "block": 12})
        for item_id, item_name, tier in biome["materials"]:
            items.append({"id": item_id, "name": item_name, "item_type": "material", "slot": "none", "tier": tier, "biome": biome["id"]})
        if biome.get("tile"):
            key = "tile_floor_%s" % biome["id"]
            manifest_assets.append({"key": key, "asset_type": "tile", "name": "Piso %s" % biome["name"],
                                    "metadata": {"biome": biome["id"]}, "prompt": TILE_PROMPT.format(biome["tile"]),
                                    "seeds": [seed_for(key)], "size": 1024})
            art_sprites.append({"key": "floor_%s" % biome["id"], "group": "tower_tiles", "source": "raw/%s_s%d.png" % (key, seed_for(key)),
                                "output": "res://assets/sprites/tiles/floor_%s.png" % biome["id"], "mode": "tile", "block": 8,
                                "palette": False, "contrast": 0.45, "tint": biome["ambient"] + "44", "grade_saturation": 0.8, "grade_value": 0.9})
        if not isinstance(biome["props"][0], str):
            for key, prompt in biome["props"]:
                full = "%s_%s" % (biome["id"], key)
                manifest_assets.append({"key": "prop_%s" % full, "asset_type": "prop", "name": key.replace("_", " ").title(),
                                        "metadata": {"biome": biome["id"]}, "prompt": PROP_PROMPT.format(prompt),
                                        "seeds": [seed_for(full)], "size": 1024})
                art_sprites.append({"key": full, "group": "tower_props", "source": "raw/prop_%s_s%d.png" % (full, seed_for(full)),
                                    "output": "res://assets/sprites/props/%s.png" % full, "block": 8})
        biomes.append({
            "id": biome["id"], "name": biome["name"], "floors": biome["floors"], "ambient": biome["ambient"],
            "mechanic": biome["mechanic"], "hazard": biome["hazard"], "tile": tile, "props": props,
            "enemies": enemy_ids, "materials": [m[0] for m in biome["materials"]],
        })
        for floor in range(biome["floors"][0], biome["floors"][1] + 1):
            boss = boss_floors.get(floor)
            depth = floor - 1
            entry = {
                "floor": floor, "biome": biome["id"], "name": biome["floor_names"].get(floor, biome["name"]),
                "kind": "boss" if boss else "explore",
                "health_multiplier": round(1.0 + 0.085 * depth, 3),
                "damage_multiplier": round(1.0 + 0.03 * depth, 3),
                "hazard_multiplier": round(1.0 + 0.04 * depth, 3),
                "seed": seed_for("andar_%d" % floor),
            }
            if boss:
                entry.update({"boss_id": boss["id"], "size": [1400, 1100], "arena_radius": 430})
            else:
                size = explore_size(floor)
                entry.update({"size": size, "packs": int(size[0] * size[1] / 360000), "kill_quota": int(30 + floor * 0.6)})
            floors.append(entry)
    for boss in BOSSES:
        biome = next(b for b in BIOMES if b["id"] == boss["biome"])
        record = {key: boss[key] for key in ("floor", "biome", "id", "name", "health", "damage", "speed", "abilities", "phases", "enrage")}
        record["health"] = int(round(boss["health"] * BOSS_HEALTH_CALIBRATION.get(boss["id"], 1.0)))
        if boss["id"] == "regente_centesimo":
            record["damage"] = int(round(boss["damage"] * REGENTE_DAMAGE_SCALE))
            record["abilities"] = [dict(a, damage=int(round(a["damage"] * REGENTE_DAMAGE_SCALE))) if "damage" in a else a for a in boss["abilities"]]
        record["loot_table_id"] = "saque_%s" % boss["id"]
        bosses.append(record)
        if boss.get("existing"):
            continue
        materials = biome["materials"] or [("pedra_regenerativa", "", ""), ("argila_de_enxerto", "", "")]
        loot_tables.append({"id": record["loot_table_id"], "entries": [
            {"item_id": "pedra_regenerativa", "chance": 1.0, "minimum": 3, "maximum": 5},
            {"item_id": materials[0][0], "chance": 1.0, "minimum": 4, "maximum": 8},
            {"item_id": materials[1][0], "chance": 1.0, "minimum": 1, "maximum": 3},
        ]})
        enemies.append({
            "id": boss["id"], "name": boss["name"], "race_id": biome["race"]["id"] if biome["race"] else "enxertado",
            "rank_id": "apice", "encounter_class": "boss", "mechanic": "boss_kit", "kind": "boss",
            "health": record["health"], "damage": record["damage"], "speed": boss["speed"], "attack_interval": 1.1,
            "loot_table_id": record["loot_table_id"], "allow_affixes": False, "biome": boss["biome"],
            "lore": "Guardiao do Limiar de %s." % biome["name"],
        })
        manifest_assets.append({"key": "tower_%s" % boss["id"], "asset_type": "monster", "name": boss["name"],
                                "metadata": {"biome": boss["biome"], "boss": True}, "prompt": BOSS_PROMPT.format(boss["prompt"]),
                                "seeds": [seed_for(boss["id"]), seed_for(boss["id"]) + 1], "size": 512})
        art_sprites.append({"key": boss["id"], "group": "tower_bosses", "source": "raw/tower_%s_s%d.png" % (boss["id"], seed_for(boss["id"])),
                            "output": "res://assets/sprites/enemies/%s.png" % boss["id"], "block": 8})
    content = {"version": 1, "biomes": biomes, "floors": floors, "bosses": bosses, "party_abilities": PARTY_ABILITIES,
               "enemies": enemies, "monster_races": races, "items": items, "loot_tables": loot_tables}
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(content, ensure_ascii=False, indent=1), encoding="utf-8")
    _merge_art(manifest_assets, art_sprites)
    write_doc(content)
    print("andares %d, biomas %d, chefes %d, inimigos %d, arte %d" % (len(floors), len(biomes), len(bosses), len(enemies), len(manifest_assets)))

DOC = ROOT / "docs" / "game-design" / "75-torre-andares-biomas-e-chefes.md"
ABILITY_LABELS = {"slam": "golpes em circulo sob os jogadores", "nova": "explosao ao redor do chefe",
                  "donut": "anel (seguro so colado ao chefe)", "line": "linhas a partir do chefe",
                  "gust": "rajada em linha que empurra", "cross": "cruz de quatro linhas", "charge": "investida em linha",
                  "meteor": "chuva de areas pela arena", "zone": "poca persistente (dano e lentidao)",
                  "pull": "puxao para o centro e explosao", "barrage": "rajada radial de projeteis",
                  "summon": "invoca criaturas do bioma"}


def write_doc(content):
    """Documento 75 gerado a partir dos mesmos dados do jogo."""
    enemy_names = {e["id"]: e["name"] for e in content["enemies"]}
    beta = json.loads((ROOT / "data" / "beta" / "beta_content.json").read_text(encoding="utf-8"))
    for enemy in beta["enemies"]:
        enemy_names.setdefault(enemy["id"], enemy["name"])
    out = ["# Torre: Andares, Biomas e Chefes", "", "## Estado", "",
           "**Implementado no jogo (decisoes 553 a 559 e 566).** Gerado a partir de `data/tower/tower_content.json` por "
           "`tools/content/build_tower.py`; edite o gerador e rode-o de novo. Valores calibrados pela sonda "
           "`tools/bench/balance_probe.gd` e ainda provisorios.", "",
           "## Estrutura", "",
           "- Cem andares em dez biomas, seguindo a divisao do documento 05 e os documentos 28 a 37.",
           "- **Andares comuns** sao mapas grandes (3200x2400 no andar 1 ate 4800x3600 a partir do andar 61) com matilhas "
           "que patrulham, cristas de obstaculos, portal de retorno na entrada e escada no extremo oposto. A escada abre ao "
           "cumprir a cota de abates (`30 + 0,6 x andar`).",
           "- **Andares de chefe** sao arenas circulares pequenas (raio 430). A saida fica selada enquanto o chefe vive; a "
           "vitoria abre a escada. O chefe derrotado volta depois de 20 minutos; ate la o andar e passagem.",
           "- O grupo atravessa os andares junto. Com a Torre vazia, a proxima entrada comeca no andar de partida escolhido "
           "no mapa da Torre (ate o mais fundo ja alcancado).",
           "- Profundidade: comuns e elites ganham `1 + 0,085 x (andar - 1)` de Vida e `1 + 0,03 x (andar - 1)` de dano; "
           "perigos, `1 + 0,04 x (andar - 1)`. Chefes usam numeros proprios, calibrados para cerca de 75 s em solo no nivel do andar.",
           "- Monstros patrulham o territorio e so perseguem quem chega a 520 unidades.",
           "- Respawn: intervalo de `14 / (1 + tempo / 120)` segundos, no minimo 2,5, sempre a mais de 480 unidades do grupo.",
           "- Recordes por andar em SOLO, DUO, TRIO e SQUAD.", "",
           "## Biomas", "", "| Andares | Bioma | Mecanica ambiental | Perigo no jogo | Monstros | Materiais |", "|---|---|---|---|---|---|"]
    for biome in content["biomes"]:
        hazard = biome["hazard"]
        kind = "mistura de todos" if hazard["type"] == "mixed" else ABILITY_LABELS.get(hazard["type"], hazard["type"])
        names = ", ".join(enemy_names.get(x, x) for x in biome["enemies"])
        materials = ", ".join(i["name"] for i in content["items"] if i.get("biome") == biome["id"]) or "Pedra Regenerativa e materiais do recorte"
        out.append("| %d-%d | %s | %s | %s (%s) | %s | %s |" % (biome["floors"][0], biome["floors"][1], biome["name"], biome["mechanic"], hazard.get("label", ""), kind, names, materials))
    out += ["", "## Chefes", "",
            "Todo chefe muda de fase pela Vida, entra em furia apos o tempo indicado (dano x1,5 e recargas x0,6) e ganha "
            "combinacoes extras com dois, tres e quatro jogadores. Toda habilidade de area e anunciada no chao antes do golpe.", "",
            "| Andar | Chefe | Vida | Dano | Fases (Vida) | Furia | Habilidades |", "|---|---|---|---|---|---|---|"]
    for boss in content["bosses"]:
        abilities = "; ".join(ABILITY_LABELS.get(a["type"], a["type"]) + (" (fase %d)" % a["phase"] if a.get("phase") else "") for a in boss["abilities"])
        out.append("| %d | %s | %d | %d | %s | %d s | %s |" % (boss["floor"], boss["name"], boss["health"], boss["damage"], ", ".join("%d%%" % int(p * 100) for p in boss["phases"]), boss["enrage"], abilities))
    biome_names = {b["id"]: b["name"] for b in content["biomes"]}
    out += ["", "## Andares", "", "| Andar | Nome | Bioma | Tipo | Cota | Tamanho |", "|---|---|---|---|---|---|"]
    for floor in content["floors"]:
        out.append("| %d | %s | %s | %s | %s | %dx%d |" % (floor["floor"], floor["name"], biome_names[floor["biome"]], "chefe" if floor["kind"] == "boss" else "comum", floor.get("kill_quota", "-"), floor["size"][0], floor["size"][1]))
    DOC.write_text("\n".join(out) + "\n", encoding="utf-8")



def _merge_art(manifest_assets, art_sprites):
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    known = {entry["key"] for entry in manifest["assets"]}
    manifest["assets"].extend(entry for entry in manifest_assets if entry["key"] not in known)
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=1), encoding="utf-8")
    process = json.loads(PROCESS.read_text(encoding="utf-8"))
    known = {entry["key"] for entry in process["sprites"]}
    process["sprites"].extend(entry for entry in art_sprites if entry["key"] not in known)
    PROCESS.write_text(json.dumps(process, ensure_ascii=False, indent=1), encoding="utf-8")


if __name__ == "__main__":
    build()
