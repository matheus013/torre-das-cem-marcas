"""Extend the authored beta skills without rewriting unrelated catalog sections.

Usage: python3 tools/content/build_skill_catalog.py [--check]
Deterministic IDs; existing gems/evolutions remain intact.
"""

import argparse
import json
from pathlib import Path

CONTENT = Path(__file__).resolve().parents[2] / "data/beta/beta_content.json"
MANUAL = CONTENT.parents[2] / "docs/catalogo-gemas.md"
ACTIVE_COUNT = 44


def evolutions(gem):
    mechanic = gem["mechanic"]
    primary = "barrier" if mechanic == "barrier" else "healing" if mechanic == "sanctuary" else "power"
    if mechanic == "dash":
        primary = "trail_damage" if gem.get("trail_damage", 0) > 0 else "arrival_barrier"
    shape = "distance" if mechanic == "dash" else "range" if mechanic in ("projectile", "boomerang", "chain", "beam", "summon", "volley") else "radius"
    choices = [
        [("Potencia Lapidada", {primary + "_multiplier": 1.25, "cooldown_multiplier": 1.1}),
         ("Forma Ampla", {shape + "_multiplier": 1.25, "breath_cost_add": 3})],
        [("Cadencia Afinada", {"cooldown_multiplier": 0.85, primary + "_multiplier": 0.9}),
         ("Reserva de Carga", {"extra_charge": 1, "cooldown_multiplier": 1.2})],
    ]
    finals = {
        "projectile": [("Retorno", {"return_projectile": True}), ("Fragmentacao", {"fork_count": 2, "power_multiplier": 0.85})],
        "boomerang": [("Disco Gemeo", {"projectile_count_add": 1, "power_multiplier": 0.8}), ("Fio Denso", {"power_multiplier": 1.3})],
        "dash": [("Chegada Explosiva", {"arrival_area": 80, "arrival_damage": 25}), ("Guarda de Chegada", {"arrival_barrier": 25})],
        "nova": [("Pulso Remoto", {"remote_nova": True}), ("Anel Oco", {"inner_radius": 55, "power_multiplier": 1.25})],
        "field": [("Campo Itinerante", {"field_follows_player": True}), ("Colapso", {"expire_damage": 50})],
        "barrier": [("Guarda Partilhada", {"allies_receive_barrier": 0.6}), ("Casca Explosiva", {"expire_nova_damage": 40})],
        "chain": [("Ultimo Elo", {"repeat_last_target": True}), ("Rede Ampla", {"chain_count_add": 2, "power_multiplier": 0.85})],
        "summon": [("Vigia Itinerante", {"summon_follows_player": True}), ("Desmonte", {"expire_damage": 40})],
        "sanctuary": [("Colheita Excedente", {"overheal_barrier": True}), ("Cultivo Movel", {"field_follows_player": True})],
        "cone": [("Eco do Corte", {"repeat_count": 1, "power_multiplier": 0.7}), ("Abertura", {"angle_multiplier": 1.3})],
        "beam": [("Feixe Duplo", {"repeat_count": 1, "power_multiplier": 0.7}), ("Lente Larga", {"width_multiplier": 1.5})],
        "orbit": [("Orbita Dupla", {"orbit_count_add": 1, "power_multiplier": 0.8}), ("Orbita Celere", {"angular_speed_multiplier": 1.5})],
        "mine": [("Preparacao Rapida", {"arm_delay_multiplier": 0.5}), ("Carga Ampla", {"radius_multiplier": 1.3, "power_multiplier": 0.9})],
        "meteor": [("Chuva Dupla", {"meteor_count_add": 1, "power_multiplier": 0.7}), ("Impacto Denso", {"power_multiplier": 1.4, "delay_multiplier": 1.25})],
        "volley": [("Folego Predador", {"breath_on_kill": 3}), ("Aljava Dupla", {"arrow_count_add": 12, "power_multiplier": 0.75})],
    }
    choices.append(finals[mechanic])
    return {str(level): [{"id": f"{gem['id']}_e{level}_{index}", "name": name, "modifiers": modifiers}
                         for index, (name, modifiers) in enumerate(entries)]
            for level, entries in enumerate(choices, 1)}


def active(identifier, name, mechanic, description, **values):
    tags = {
        "projectile": ["projectile", "physical", "precision"], "boomerang": ["projectile", "physical", "precision"],
        "dash": ["movement", "physical", "defense"], "nova": ["area", "magic", "control"],
        "field": ["area", "magic", "control", "duration"], "barrier": ["protection", "area", "duration"],
        "chain": ["chain", "magic", "precision"], "summon": ["summon", "duration"],
        "sanctuary": ["area", "life", "healing", "duration"], "cone": ["area", "physical", "control"],
        "beam": ["precision", "magic"], "orbit": ["area", "physical", "duration"],
        "mine": ["area", "magic", "duration"], "meteor": ["area", "magic"],
        "volley": ["projectile", "magic", "duration"],
    }[mechanic]
    scaling = ["strength", "agility"] if "physical" in tags else ["intelligence", "wisdom"]
    gem = dict(id=identifier, name=name, description=description, mechanic=mechanic, tags=tags,
               cooldown=4.0, breath_cost=8, power=30, radius=80, range=420, scaling=scaling)
    gem.update(values)
    if mechanic == "summon":
        gem["radius"] = 12
    if gem.get("power", 0) > 0:
        gem["tags"].append("damage")
    gem["evolutions"] = evolutions(gem)
    return gem


def new_actives():
    return [
        active("estilhacos_lunares", "Estilhacos Lunares", "projectile", "Leque de tres impactos curtos para espalhar dano.", projectile_count=2, power=18, range=330, radius=24),
        active("lanca_ferral", "Lanca Ferral", "projectile", "Linha longa que atravessa tres alvos antes do impacto.", pierce=3, power=25, range=600, radius=26, cooldown=3),
        active("orbe_de_ruptura", "Orbe de Ruptura", "projectile", "Impacto largo e lento que rompe grupos compactos.", power=48, impact_area=60, radius=20, speed=0.65, cooldown=6),
        active("corte_vetorial", "Corte Vetorial", "dash", "Avanco ofensivo que corta os inimigos no trajeto.", distance=150, trail_damage=35, invulnerability=0.15, cooldown=4, breath_cost=24),
        active("salto_de_guarda", "Salto de Guarda", "dash", "Retirada longa com barreira na chegada, sem dano direto.", power=0, distance=175, arrival_barrier=32, invulnerability=0.35, cooldown=6, breath_cost=30),
        active("anel_de_geada", "Anel de Geada", "nova", "Pulso proximo que desacelera a horda.", power=22, radius=150, slow=0.45, status_duration=2.5, cooldown=6),
        active("ruptura_sismica", "Ruptura Sismica", "nova", "Explosao curta e forte que afasta ameacas.", power=55, radius=100, knockback=95, cooldown=7),
        active("brasa_persistente", "Brasa Persistente", "field", "Zona fixa de pulsos rapidos que explode ao se extinguir.", power=8, radius=110, duration=5, tick_interval=0.4, expire_damage=30, cooldown=9),
        active("pantano_acido", "Pantano Acido", "field", "Zona que combina lentidao e vulnerabilidade.", power=6, radius=145, duration=5, tick_interval=0.8, slow=0.3, damage_taken=0.12, cooldown=10),
        active("casca_reativa", "Casca Reativa", "barrier", "Barreira que pune contato e explode ao expirar.", power=0, barrier=35, contact_damage=12, expire_nova_damage=40, duration=4, radius=90, cooldown=9),
        active("arco_voltaico", "Arco Voltaico", "chain", "Seis saltos de alcance curto aplicam vulnerabilidade leve.", power=19, chain_count=6, chain_range=110, range=380, damage_taken=0.08, status_duration=2, cooldown=5),
        active("dreno_em_rede", "Dreno em Rede", "chain", "Tres saltos que devolvem Vida ao portador.", power=29, chain_count=3, chain_range=180, heal_per_chain=5, life_steal=0.04, cooldown=7),
        active("sentinela_ferral", "Sentinela Ferral", "summon", "Sentinela fixa de longo alcance prioriza o inimigo com menos Vida.", summon_definition_id="sentinela_ferral", summon_count=1, power=20, duration=12, attack_interval=1.4, range=460, cooldown=12),
        active("enxame_luminar", "Enxame Luminar", "summon", "Tres criaturas leves perseguem o alvo mais proximo.", summon_definition_id="enxame_luminar", summon_count=3, power=4.2, duration=8, attack_interval=0.5, range=85, cooldown=11),
        active("guardiao_de_lastro", "Guardiao de Lastro", "summon", "Guardiao resistente acompanha o portador e repele inimigos.", summon_definition_id="guardiao_de_lastro", summon_count=1, power=16, duration=14, attack_interval=1, range=140, knockback=35, cooldown=14),
        active("circulo_de_reparo", "Circulo de Reparo", "sanctuary", "Cultivo curto com cura forte; excesso vira barreira.", power=0, healing=16, overheal_barrier=True, radius=95, duration=4, tick_interval=1, cooldown=10),
        active("abrigo_de_escora", "Abrigo de Escora", "sanctuary", "Zona ampla de cura leve que prolonga a estabilidade de aliados caidos.", power=0, healing=6, stability=0.3, radius=160, duration=6, tick_interval=1, cooldown=12),
        active("ceifa_ampla", "Ceifa Ampla", "cone", "Corte em cone frontal; nao atinge inimigos atras do portador.", power=40, radius=175, angle=1.7, knockback=30, cooldown=3),
        active("sopro_criogenico", "Sopro Criogenico", "cone", "Cone estreito e longo de lentidao intensa.", power=25, radius=240, angle=0.8, slow=0.55, status_duration=3, cooldown=6),
        active("raio_prismatico", "Raio Prismatico", "beam", "Feixe estreito que atinge todos os inimigos alinhados.", power=38, range=560, width=16, cooldown=4),
        active("fio_desintegrador", "Fio Desintegrador", "beam", "Feixe largo e curto que aplica vulnerabilidade.", power=32, range=320, width=38, damage_taken=0.18, status_duration=3, cooldown=6),
        active("laminas_orbitais", "Laminas Orbitais", "orbit", "Tres laminas giram ao redor do portador e acertam por contato.", power=22, radius=100, orbit_count=3, angular_speed=2.8, collision_radius=22, duration=6, tick_interval=0.35, cooldown=10),
        active("satelites_de_geada", "Satelites de Geada", "orbit", "Duas orbitas externas lentas controlam a aproximacao.", power=16, radius=145, orbit_count=2, angular_speed=1.5, collision_radius=28, slow=0.35, duration=7, tick_interval=0.5, cooldown=12),
        active("mina_de_lastro", "Mina de Lastro", "mine", "Arma apos um segundo e detona quando um inimigo se aproxima, ou ao expirar.", power=48, radius=105, trigger_radius=65, arm_delay=1, duration=8, cooldown=5),
        active("semente_explosiva", "Semente Explosiva", "mine", "Armadilha rapida de explosao ampla e repulsao.", power=35, radius=145, trigger_radius=90, arm_delay=0.35, duration=6, knockback=60, cooldown=7),
        active("chuva_ferral", "Chuva Ferral", "meteor", "Tres impactos atrasados cobrem pontos diferentes ao redor da mira.", power=45, radius=65, meteor_count=3, spread=85, delay=0.65, cooldown=8),
        active("cometa_de_vidro", "Cometa de Vidro", "meteor", "Um impacto grande e lento; exige antecipar o movimento da horda.", power=90, radius=125, meteor_count=1, spread=0, delay=1.2, cooldown=11),
        active("disco_de_retorno", "Disco de Retorno", "boomerang", "Disco corta a linha de ida e retorna pela mesma rota.", power=28, pierce=8, return_projectile=True, radius=24, range=350, cooldown=5),
        # Gemas elementais: cada uma estreia a animacao de um elemento (src/presentation/vfx/skill_themes.gd).
        active("bola_de_fogo", "Bola de Fogo", "projectile", "Projetil flamejante que explode em area no impacto.", tags=["projectile", "magic", "precision"], scaling=["intelligence", "wisdom"], power=34, impact_area=70, radius=22, cooldown=4.5),
        active("bolha_corrosiva", "Bolha Corrosiva", "projectile", "Bolha lenta de acido; o impacto deixa os inimigos vulneraveis.", tags=["projectile", "magic", "precision"], scaling=["intelligence", "vitality"], power=20, impact_area=55, damage_taken=0.15, status_duration=3, speed=0.7, radius=22, cooldown=5),
        active("cometa_sombrio", "Cometa Sombrio", "projectile", "Cometa de sombra que atravessa dois alvos e desacelera.", tags=["projectile", "magic", "precision"], scaling=["intelligence", "fortune"], power=31, pierce=2, slow=0.25, status_duration=2, radius=24, range=520, cooldown=5),
        active("raizes_presas", "Raizes Presas", "field", "Raizes brotam na mira e prendem a horda com lentidao forte.", scaling=["vitality", "wisdom"], power=8.4, radius=130, duration=4, tick_interval=0.6, slow=0.55, status_duration=1.5, cooldown=9),
        active("pilar_sagrado", "Pilar Sagrado", "meteor", "Coluna de luz cai na mira apos breve aviso.", scaling=["wisdom", "intelligence"], power=70, radius=90, meteor_count=1, spread=0, delay=0.8, cooldown=8),
        active("esfera_de_gelo", "Esfera de Gelo", "projectile", "Esfera gelada que estilhaca no impacto e desacelera em area.", tags=["projectile", "magic", "precision"], scaling=["intelligence", "wisdom"], power=24, impact_area=55, slow=0.4, status_duration=2.5, radius=22, cooldown=4),
        active("saraivada_de_flechas", "Saraivada de Flechas", "volley", "Enquanto ativa, dispara flechas que atravessam um inimigo para todos os lados enquanto voce anda; fogo, gelo e raio se alternam a cada rajada. Consome Folego por segundo e segura a regeneracao; usar de novo encerra.", tags=["projectile", "magic", "duration"], scaling=["agility", "intelligence"], power=4, pierce=1, arrow_count=24, tick_interval=0.4, range=300, radius=16, duration=8, breath_cost=6, breath_per_second=9, cooldown=1.5),
        active("trovao_descendente", "Trovao Descendente", "meteor", "Dois raios caem rapido ao redor da mira.", scaling=["intelligence", "agility"], power=36, radius=70, meteor_count=2, spread=60, delay=0.45, damage_taken=0.06, status_duration=2, cooldown=6),
    ]


def support(identifier, name, category, mechanics, description, drain=2, **modifiers):
    requires = ["damage"] if identifier in ("potencia_bruta", "precisao_lapidada", "sifao_de_folego", "aegis_por_acerto") else []
    return dict(id=identifier, name=name, category=category, requires=requires, allowed_mechanics=mechanics,
                description=description, drain=drain, modifiers=modifiers)


def new_supports():
    projectile = ["projectile", "boomerang"]
    damaging = ["projectile", "boomerang", "nova", "field", "chain", "summon", "sanctuary", "cone", "beam", "orbit", "mine", "meteor", "volley"]
    return [
        support("retorno_vetorial", "Retorno Vetorial", "mechanic", projectile, "Projeteis retornam pela linha de ida; -15% de potencia.", return_projectile=True, power_multiplier=0.85),
        support("bifurcacao_residual", "Bifurcacao Residual", "mechanic", projectile, "Do impacto saem duas linhas divergentes; -20% de potencia.", fork_count=2, power_multiplier=0.8, drain=3),
        support("explosao_de_contato", "Explosao de Contato", "mechanic", projectile, "Impacto ganha 55 unidades de area; -15% de potencia.", impact_area_add=55, power_multiplier=0.85, drain=3),
        support("novas_remotas", "Novas Remotas", "mechanic", ["nova"], "Pulso nasce na mira em vez do portador; recarga +15%.", remote_nova=True, cooldown_multiplier=1.15),
        support("anel_vazio", "Anel Vazio", "mechanic", ["nova"], "Nao atinge o centro de 55 unidades; potencia +25%.", inner_radius=55, power_multiplier=1.25),
        support("zona_itinerante", "Zona Itinerante", "mechanic", ["field", "sanctuary"], "Zona acompanha o portador; duracao -20%.", field_follows_player=True, duration_multiplier=0.8),
        support("detonacao_tardia", "Detonacao Tardia", "mechanic", ["field", "sanctuary", "orbit"], "Explode com 45 de dano ao expirar; pulsos -20%.", expire_damage_add=45, power_multiplier=0.8, drain=3),
        support("eco_triplo", "Eco Triplo", "mechanic", ["nova", "cone", "beam", "projectile", "chain", "meteor"], "Repete duas vezes com 0,45 s entre ecos; -50% de potencia.", repeat_count_add=2, repeat_delay=0.45, power_multiplier=0.5, drain=4),
        support("guarda_partilhada", "Guarda Partilhada", "mechanic", ["barrier"], "Aliados proximos recebem 60% da barreira; barreira propria -15%.", allies_receive_barrier=0.6, barrier_multiplier=0.85),
        support("vigia_itinerante", "Vigia Itinerante", "mechanic", ["summon"], "Invocacao segue o portador; alcance -20%.", summon_follows_player=True, range_multiplier=0.8),
        support("enxame_duplo", "Enxame Duplo", "mechanic", ["summon"], "Cria uma invocacao adicional respeitando o limite do tipo; -25% de potencia.", summon_count_add=1, power_multiplier=0.75, drain=3),
        support("corrente_de_retorno", "Corrente de Retorno", "mechanic", ["chain"], "Ultimo alvo recebe um segundo acerto; -15% de potencia.", repeat_last_target=True, power_multiplier=0.85),
        support("conversao_cultivo", "Conversao de Cultivo", "mechanic", ["sanctuary"], "Cura excedente vira barreira; cura -15%.", overheal_barrier=True, healing_multiplier=0.85),
        support("salto_explosivo", "Salto Explosivo", "mechanic", ["dash"], "Chegada causa 25 de dano em raio 80; custo +8 Folego.", arrival_area=80, arrival_damage=25, breath_cost_add=8),
        support("potencia_bruta", "Potencia Bruta", "buff", damaging, "Potencia +22%; recarga +10%.", power_multiplier=1.22, cooldown_multiplier=1.1),
        support("precisao_lapidada", "Precisao Lapidada", "buff", damaging, "Chance critica +12 pontos percentuais; potencia -10%.", critical_chance_add=0.12, power_multiplier=0.9),
        support("alcance_treinado", "Alcance Treinado", "buff", ["projectile", "boomerang", "chain", "beam", "summon", "field", "mine", "meteor", "volley"], "Alcance +35%; recarga +8%.", range_multiplier=1.35, cooldown_multiplier=1.08),
        support("barreira_densa", "Barreira Densa", "buff", ["barrier"], "Barreira +35%; duracao -15%.", barrier_multiplier=1.35, duration_multiplier=0.85),
        support("cura_reforcada", "Cura Reforcada", "buff", ["sanctuary"], "Cura por pulso +35%; intervalo +20%.", healing_multiplier=1.35, tick_interval_multiplier=1.2),
        support("ritmo_de_cultivo", "Ritmo de Cultivo", "buff", ["field", "sanctuary", "orbit"], "Intervalo dos pulsos -25%; potencia, cura e duracao -15%.", tick_interval_multiplier=0.75, power_multiplier=0.85, healing_multiplier=0.85, duration_multiplier=0.85),
        support("passo_extenso", "Passo Extenso", "buff", ["dash"], "Distancia +30%; custo +5 Folego.", distance_multiplier=1.3, breath_cost_add=5),
        support("passo_seguro", "Passo Seguro", "buff", ["dash"], "Invulnerabilidade +40%; distancia -15%.", invulnerability_multiplier=1.4, distance_multiplier=0.85),
        support("invocacao_celere", "Invocacao Celere", "buff", ["summon"], "Intervalo de ataque -25%; potencia -15%.", attack_interval_multiplier=0.75, power_multiplier=0.85),
        support("elo_amplo", "Elo Amplo", "buff", ["chain"], "Alcance dos saltos +35%; potencia -10%.", chain_range_multiplier=1.35, power_multiplier=0.9),
        support("estabilidade_solida", "Estabilidade Solida", "buff", ["sanctuary"], "Estabilidade +20 pontos percentuais; cura -10%.", stability_add=0.2, healing_multiplier=0.9),
        support("sifao_de_folego", "Sifao de Folego", "buff", damaging, "Cada acerto devolve 2 Folego, ate 8 por segundo; potencia -15%.", breath_per_hit_add=2, power_multiplier=0.85),
        support("aegis_por_acerto", "Aegis por Acerto", "buff", damaging, "Barreira +2 por acerto; potencia -15%.", barrier_per_hit_add=2, power_multiplier=0.85),
        support("cadencia_precisa", "Cadencia Precisa", "buff", [], "Recarga -15%; custo +4 Folego.", cooldown_multiplier=0.85, breath_cost_add=4),
    ]


def update_existing(gems, supports):
    descriptions = {
        "agulha_lastro": "Projetil de precisao que acerta no destino da mira.",
        "passo_vetorial": "Esquiva com invulnerabilidade breve e custo de Folego.",
        "pulso_cicatriz": "Pulso circular de dano ao redor do portador.",
        "prisao_gravitica": "Campo persistente de pulsos; evolucoes adicionam atracao e colapso.",
        "muralha_refeita": "Barreira pessoal; evolucoes adicionam contato, partilha ou explosao.",
        "elo_residual": "Corrente que salta entre inimigos distintos.",
        "molde_vigilante": "Invocacao fixa ataca inimigos proximos durante dez segundos.",
        "semeadura_vital": "Cultivo que cura aliados dentro da zona e causa dano aos inimigos.",
    }
    for gem in gems:
        gem["description"] = descriptions.get(gem["id"], gem.get("description", ""))
        gem["scaling"] = ["fortune" if stat == "luck" else stat for stat in gem["scaling"]]
        if gem.get("power", 0) > 0 and "damage" not in gem["tags"]:
            gem["tags"].append("damage")
    mechanic_ids = {"projeteis_gemeos", "perfuracao_refeita", "ricochete_de_junta", "eco_atrasado", "impulso_de_impacto", "busca_residual"}
    damaging = ["projectile", "boomerang", "nova", "field", "chain", "summon", "sanctuary", "cone", "beam", "orbit", "mine", "meteor", "volley"]
    descriptions = {
        "projeteis_gemeos": "Projeteis +1; potencia -22%.", "perfuracao_refeita": "Atravessa mais dois alvos; potencia -10%.",
        "ricochete_de_junta": "Salta para mais dois alvos; alcance -15%.", "area_expandida": "Raio +30%; potencia -10%.",
        "foco_concentrado": "Raio -28%; potencia +38%.", "eco_atrasado": "Repete apos 0,7 s; potencia -32%.",
        "fluxo_rapido": "Recarga -22%; potencia -14%.", "duracao_estendida": "Duracao +45%.",
        "drenagem_vital": "Recupera 8% do dano como Vida; potencia -10%.", "impulso_de_impacto": "Repulsao +65; potencia -8%.",
        "busca_residual": "Corrige o destino para um inimigo proximo da mira; velocidade visual -18%.",
        "sobrecarga_instavel": "Potencia +55%; recarga +30%; custo +12 Folego.",
    }
    for entry in supports:
        if entry["id"] not in descriptions:
            continue
        entry["category"] = "mechanic" if entry["id"] in mechanic_ids else "buff"
        entry["description"] = descriptions[entry["id"]]
        if "projectile" in entry["requires"]:
            entry["allowed_mechanics"] = ["projectile", "boomerang"]
        if entry["id"] in ("drenagem_vital", "impulso_de_impacto", "sobrecarga_instavel"):
            entry["allowed_mechanics"] = damaging
            if "damage" not in entry["requires"]:
                entry["requires"].append("damage")
        if entry["id"] == "duracao_estendida":
            entry["allowed_mechanics"] = ["barrier", "field", "sanctuary", "orbit", "mine", "summon"]


def new_summons():
    values = [("sentinela_ferral", "stationary", 65, 0, 34, 1.4, 460, 12, 2),
              ("enxame_luminar", "chase_target", 18, 180, 7, 0.5, 85, 8, 4),
              ("guardiao_de_lastro", "follow_owner", 120, 90, 20, 1, 140, 14, 2)]
    return [dict(id=identifier, name=identifier.replace("_", " ").title(), behavior=behavior,
                 targeting="lowest_health_hostile" if identifier == "sentinela_ferral" else "nearest_hostile", replacement_policy="oldest", health=health,
                 movement_speed=speed, power=power, attack_interval=interval, range=reach,
                 duration=duration, owner_limit=limit, collision_radius=12, can_be_damaged=True,
                 blocks_movement=False, persists_between_areas=False)
            for identifier, behavior, health, speed, power, interval, reach, duration, limit in values]


def collection_text(entries):
    lines = ["["]
    for index, entry in enumerate(entries):
        lines.append("    {")
        for position, (key, value) in enumerate(entry.items()):
            comma = "," if position < len(entry) - 1 else ""
            lines.append("      " + json.dumps(key) + ": " + json.dumps(value, ensure_ascii=False) + comma)
        lines.append("    }" + ("," if index < len(entries) - 1 else ""))
    lines.append("  ]")
    return "\n".join(lines)


def replace_collections(source, collections):
    # Decode root members and splice only their value spans, preserving unrelated authored text.
    decoder = json.JSONDecoder()
    index = source.index("{") + 1
    replacements = []
    while True:
        while source[index].isspace() or source[index] == ",":
            index += 1
        if source[index] == "}":
            break
        key, index = decoder.raw_decode(source, index)
        while source[index].isspace() or source[index] == ":":
            index += 1
        start = index
        _, index = decoder.raw_decode(source, index)
        if key in collections:
            replacements.append((start, index, collection_text(collections[key])))
    for start, end, replacement in reversed(replacements):
        source = source[:start] + replacement + source[end:]
    json.loads(source)
    return source


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    source = CONTENT.read_text(encoding="utf-8")
    data = json.loads(source)
    additions = new_actives()
    new_ids = {entry["id"] for entry in additions}
    base = [entry for entry in data["active_gems"] if entry["id"] not in new_ids]
    support_additions = new_supports()
    new_support_ids = {entry["id"] for entry in support_additions}
    supports = [entry for entry in data["support_gems"] if entry["id"] not in new_support_ids]
    update_existing(base, supports)
    gems = base + additions
    supports += support_additions
    summons = [entry for entry in data["summons"] if entry["id"] not in {v["id"] for v in new_summons()}] + new_summons()
    assert len(gems) == ACTIVE_COUNT and len(supports) == 40
    assert sum(entry["category"] == "mechanic" for entry in supports) == 20
    assert sum(entry["category"] == "buff" for entry in supports) == 20
    result = replace_collections(source, dict(active_gems=gems, support_gems=supports, summons=summons))
    manual = catalog_manual(gems, supports)
    if args.check:
        if source != result or not MANUAL.exists() or MANUAL.read_text(encoding="utf-8") != manual:
            raise SystemExit("Skill catalog differs from generator; run it and review the diff")
    else:
        CONTENT.write_text(result, encoding="utf-8")
        MANUAL.write_text(manual, encoding="utf-8")
    print("SKILL_CATALOG_OK: %d active, 20 mechanic supports, 20 buff supports" % ACTIVE_COUNT)


def catalog_manual(gems, supports):
    lines = ["# Catalogo de gemas: %d ativas + 40 suportes" % len(gems), "",
             "Gerado por `python3 tools/content/build_skill_catalog.py`; confirme com `--check`.",
             "Referencia de design: [GGG: suporte, especializacao e contrapartidas](https://www.pathofexile.com/forum/view-thread/3147753).",
             "Inspiracao estrutural, sem copiar nomes, arte ou valores de Path of Exile. Fonte historica, nao guia de patch atual.", "",
             "## Regras atuais", "",
             "Quatro ativas equipadas; troca e ligacao em Aresta. Ate dois suportes por ativa, capacidade 2 + nivel da gema (3-5 no beta).",
             "Categorias mecanica/buff compartilham slots e capacidade. Uma copia de cada suporte por personagem, sem equipar o mesmo suporte em dois slots.",
             "",
             "Autoataque (2026-10-04): dois suportes com capacidade fixa 6, na secao",
             "AUTOATAQUE da aba Skills. Compatibilidade depende da arma; Foco aceita",
             "multishot, perfuracao, ricochete, retorno, bifurcacao e impacto em area.",
             "Lanca/Bastao aceitam modificadores de area; Manoplas mantem acerto unico.",
             "Dano, alcance, cadencia, critico, repulsao, roubo de Vida, Folego e barreira",
             "por acerto seguem a compatibilidade do catalogo e consumidores existentes.",
             "Suportes de eco, teleguiado, duracao/invocacao e outros campos sem consumidor",
             "no autoataque nao sao ofertados. Custos adicionais de Folego sao pagos a cada",
             "ataque; sem recurso suficiente, espera regenerar. Trocas continuam em Aresta.",
             "Uma copia nao pode ficar ligada a skill e autoataque simultaneamente.",
             "Trocar arma preserva suportes incompativeis como inativos; reativam com arma",
             "compativel. Saves antigos iniciam sem suportes no autoataque, sem perder skills.",
             f"{len(gems)} ativas disponiveis no catalogo do beta; nao sao desbloqueios por loot. Saves antigos recebem novas entradas de progresso no carregamento.",
             "IDs anteriores e escolhas salvas preservados. Graus 1-3 oferecem duas evolucoes por grau; nao confundir com marcos permanentes de personagem.",
             "Valores sao ponto de partida de balanceamento, nao prova de viabilidade equivalente. Efeitos visuais/icone provisorios em pixel art; audio individual ainda pendente.", "",
             "## Ativas", "", "| Gema | Familia | Comportamento |", "| --- | --- | --- |"]
    for gem in gems:
        lines.append(f"| {gem['name']} | `{gem['mechanic']}` | {gem.get('description', '')} |")
    for category, title in [("mechanic", "20 suportes mecanicos"), ("buff", "20 suportes de buff")]:
        lines += ["", f"## {title}", "", "| Suporte | Dreno | Efeito e contrapartida |", "| --- | --- | --- |"]
        for entry in supports:
            if entry["category"] == category:
                lines.append(f"| {entry['name']} | {entry['drain']} | {entry['description']} |")
    lines += ["", "## Limites e semantica", "",
              "Projeteis atuais resolvem acertos imediatamente e animam o trajeto; nao simulam fisica balistica ou colisao de projeteis com paredes.",
              "Bifurcacao nasce no ponto de impacto; nao e um proc recursivo. Retorno e ricochetes mantem a semantica existente de acertos instantaneos.",
              "Cone tem direcao e abertura; feixe tem largura. Orbitas acertam ao redor do portador, nao em todo o disco. Minas detonam uma vez apos armar/proximidade ou ao expirar.",
              "Meteoros marcam locais fixos e atingem apos atraso; ecos/impactos agendados sao descartados ao mudar de andar/zona.",
              "Limites: oito projeteis, oito orbitas, oito impactos e quatro ecos por ativacao; oito zonas/minas por gema/portador, substituindo a mais antiga.",
              "Summons usam limites por definicao (2 sentinelas, 4 criaturas do enxame, 2 guardioes). Suporte de quantidade nao ultrapassa esses limites.",
              "Sifao recupera ate oito pontos de Folego por segundo por portador, compartilhado entre suas habilidades; nao amplia Folego maximo.",
              "UI lista apenas compatibilidade de familia/tags; as combinacoes e contrapartidas precisam de playtest. Raridades, aquisicao por contratos e balanceamento final continuam fora desta entrega.", ""]
    return "\n".join(lines)


if __name__ == "__main__":
    main()
