"""Modificadores de maestria das gemas ativas (decisao 588).

Cada gema vai do nivel 1 ao 21. Nos niveis 5, 10, 15 e 20 o jogador escolhe 1 de 3 modificadores
(2 de sinergia com a mecanica e 1 generico); no 21, 1 de 2 grandes modificadores. Os campos usam a
convencao dos suportes: `campo_multiplier` multiplica, `campo_add` soma, o resto define o valor.
Toda chave aqui e lida pela simulacao para a mecanica correspondente.
"""

MASTERY_LEVELS = (5, 10, 15, 20, 21)

# Oito modificadores de sinergia por mecanica: os niveis 5, 10, 15 e 20 oferecem dois deles cada.
SYNERGY = {
    "projectile": [
        ("Disparo Gemeo", {"projectile_count_add": 1, "power_multiplier": 0.85}),
        ("Perfuracao Funda", {"pierce_add": 2}),
        ("Ricochete", {"ricochet_add": 2}),
        ("Impacto Amplo", {"impact_area_add": 45}),
        ("Busca Certeira", {"homing": True, "range_multiplier": 1.15}),
        ("Ponta Critica", {"critical_chance_add": 0.12}),
        ("Disparo Veloz", {"speed_multiplier": 1.4, "power_multiplier": 1.1}),
        ("Estilhacos", {"fork_count_add": 2, "power_multiplier": 0.9}),
    ],
    "boomerang": [
        ("Disco Gemeo", {"projectile_count_add": 1, "power_multiplier": 0.85}),
        ("Fio Denso", {"power_multiplier": 1.25}),
        ("Corte Fundo", {"pierce_add": 3}),
        ("Arco Largo", {"impact_area_add": 35}),
        ("Retorno Faminto", {"breath_per_hit_add": 1}),
        ("Gume Critico", {"critical_chance_add": 0.12}),
        ("Disco Veloz", {"speed_multiplier": 1.4}),
        ("Disco Pesado", {"knockback_add": 40, "power_multiplier": 1.1}),
    ],
    "dash": [
        ("Passo Longo", {"distance_multiplier": 1.3}),
        ("Esquiva Plena", {"invulnerability_multiplier": 1.5}),
        ("Rastro Cortante", {"trail_damage_add": 20}),
        ("Chegada Explosiva", {"arrival_area_add": 80, "arrival_damage_add": 25}),
        ("Guarda de Chegada", {"arrival_barrier_add": 25}),
        ("Passo Leve", {"breath_cost_multiplier": 0.6}),
        ("Retomada", {"cooldown_multiplier": 0.8}),
        ("Segunda Rota", {"extra_charge": 1}),
    ],
    "nova": [
        ("Raio Amplo", {"radius_multiplier": 1.25}),
        ("Pulso Remoto", {"remote_nova": True}),
        ("Anel Oco", {"inner_radius_add": 55, "power_multiplier": 1.25}),
        ("Onda de Choque", {"knockback_add": 60}),
        ("Eco do Pulso", {"repeat_count_add": 1, "power_multiplier": 0.7}),
        ("Pulso Gelido", {"slow_add": 0.3}),
        ("Fissura", {"damage_taken_add": 0.15}),
        ("Pulso Vampiro", {"life_steal_add": 0.05}),
    ],
    "field": [
        ("Campo Amplo", {"radius_multiplier": 1.25}),
        ("Campo Duradouro", {"duration_multiplier": 1.4}),
        ("Pulsos Rapidos", {"tick_interval_multiplier": 0.75}),
        ("Atracao", {"pull_strength_add": 60}),
        ("Campo Itinerante", {"field_follows_player": True}),
        ("Colapso", {"expire_damage_add": 50}),
        ("Campo Lento", {"slow_add": 0.3}),
        ("Exposicao", {"damage_taken_add": 0.15}),
    ],
    "barrier": [
        ("Barreira Densa", {"barrier_multiplier": 1.3}),
        ("Barreira Duradoura", {"duration_multiplier": 1.4}),
        ("Guarda Partilhada", {"allies_receive_barrier_add": 0.6}),
        ("Casca Explosiva", {"expire_nova_damage_add": 40}),
        ("Espinhos", {"contact_damage_add": 15}),
        ("Reerguer", {"cooldown_multiplier": 0.8}),
        ("Barreira Reserva", {"extra_charge": 1}),
        ("Barreira Leve", {"breath_cost_multiplier": 0.6}),
    ],
    "chain": [
        ("Mais Saltos", {"chain_count_add": 2}),
        ("Salto Longo", {"chain_range_multiplier": 1.35}),
        ("Ultimo Elo", {"repeat_last_target": True}),
        ("Corrente Vital", {"heal_per_chain_add": 3}),
        ("Elo Critico", {"critical_chance_add": 0.12}),
        ("Choque", {"slow_add": 0.25}),
        ("Elo Exposto", {"damage_taken_add": 0.15}),
        ("Elo Sedento", {"life_steal_add": 0.05}),
    ],
    "summon": [
        ("Mais Um", {"summon_count_add": 1, "power_multiplier": 0.8}),
        ("Vigilia Longa", {"duration_multiplier": 1.4}),
        ("Ataque Rapido", {"attack_interval_multiplier": 0.75}),
        ("Alcance do Vigia", {"range_multiplier": 1.3}),
        ("Vigia Itinerante", {"summon_follows_player": True}),
        ("Desmonte", {"expire_damage_add": 40}),
        ("Forja Forte", {"power_multiplier": 1.25}),
        ("Golpe Preciso", {"critical_chance_add": 0.1}),
    ],
    "sanctuary": [
        ("Cura Farta", {"healing_multiplier": 1.3}),
        ("Circulo Amplo", {"radius_multiplier": 1.25}),
        ("Cultivo Longo", {"duration_multiplier": 1.4}),
        ("Firmeza", {"stability_add": 0.15}),
        ("Colheita Excedente", {"overheal_barrier": True}),
        ("Pulsos Rapidos", {"tick_interval_multiplier": 0.75}),
        ("Cultivo Movel", {"field_follows_player": True}),
        ("Espinhos do Jardim", {"power_multiplier": 1.4}),
    ],
    "cone": [
        ("Abertura", {"angle_multiplier": 1.3}),
        ("Corte Longo", {"radius_multiplier": 1.25}),
        ("Eco do Corte", {"repeat_count_add": 1, "power_multiplier": 0.7}),
        ("Empurrao", {"knockback_add": 60}),
        ("Corte Gelido", {"slow_add": 0.3}),
        ("Ferida Aberta", {"damage_taken_add": 0.15}),
        ("Gume Critico", {"critical_chance_add": 0.12}),
        ("Corte Sedento", {"life_steal_add": 0.05}),
    ],
    "beam": [
        ("Lente Larga", {"width_multiplier": 1.5}),
        ("Feixe Longo", {"range_multiplier": 1.3}),
        ("Feixe Duplo", {"repeat_count_add": 1, "power_multiplier": 0.7}),
        ("Luz Exposta", {"damage_taken_add": 0.2}),
        ("Foco Critico", {"critical_chance_add": 0.12}),
        ("Luz Pesada", {"slow_add": 0.3}),
        ("Feixe Sedento", {"life_steal_add": 0.05}),
        ("Recarga Focada", {"cooldown_multiplier": 0.8}),
    ],
    "orbit": [
        ("Orbita Extra", {"orbit_count_add": 1, "power_multiplier": 0.85}),
        ("Orbita Celere", {"angular_speed_multiplier": 1.5}),
        ("Orbita Larga", {"radius_multiplier": 1.3}),
        ("Laminas Largas", {"collision_radius_multiplier": 1.35}),
        ("Giro Longo", {"duration_multiplier": 1.4}),
        ("Corte Vampiro", {"life_steal_add": 0.04}),
        ("Orbita Gelida", {"slow_add": 0.25}),
        ("Fio Critico", {"critical_chance_add": 0.1}),
    ],
    "mine": [
        ("Preparacao Rapida", {"arm_delay_multiplier": 0.5}),
        ("Carga Ampla", {"radius_multiplier": 1.3}),
        ("Gatilho Sensivel", {"trigger_radius_multiplier": 1.4}),
        ("Carga Pesada", {"power_multiplier": 1.25}),
        ("Mina Reserva", {"extra_charge": 1}),
        ("Estilhaco Lento", {"slow_add": 0.4}),
        ("Estilhaco Exposto", {"damage_taken_add": 0.2}),
        ("Mina Paciente", {"duration_multiplier": 1.5}),
    ],
    "meteor": [
        ("Chuva Dupla", {"meteor_count_add": 1, "power_multiplier": 0.75}),
        ("Impacto Denso", {"power_multiplier": 1.3, "delay_multiplier": 1.2}),
        ("Queda Rapida", {"delay_multiplier": 0.7}),
        ("Cratera", {"radius_multiplier": 1.25}),
        ("Chuva Espalhada", {"spread_multiplier": 1.3}),
        ("Impacto Gelido", {"slow_add": 0.3}),
        ("Impacto Exposto", {"damage_taken_add": 0.15}),
        ("Impacto Critico", {"critical_chance_add": 0.12}),
    ],
    "volley": [
        ("Folego Predador", {"breath_on_kill_add": 3}),
        ("Aljava Dupla", {"arrow_count_add": 12, "power_multiplier": 0.75}),
        ("Flechas Perfurantes", {"pierce_add": 1}),
        ("Rajadas Rapidas", {"tick_interval_multiplier": 0.8}),
        ("Pulmoes Fortes", {"breath_per_second_multiplier": 0.7}),
        ("Saraivada Longa", {"duration_multiplier": 1.4}),
        ("Alcance do Arco", {"range_multiplier": 1.3}),
        ("Ponta Critica", {"critical_chance_add": 0.1}),
    ],
    "spores": [
        ("Colonia Voraz", {"poison_growth_add": 0.05}),
        ("Germinacao Rapida", {"tick_interval_multiplier": 0.75}),
        ("Nuvem de Esporos", {"spread_radius_multiplier": 1.5}),
        ("Esporos Densos", {"power_multiplier": 1.4}),
        ("Alcance da Infeccao", {"range_multiplier": 1.3}),
        ("Infeccao Rapida", {"cooldown_multiplier": 0.7}),
        ("Esporo Leve", {"breath_cost_multiplier": 0.6}),
        ("Dois Esporos", {"extra_charge": 1}),
    ],
    "poison_pool": [
        ("Pantano Profundo", {"radius_multiplier": 1.4}),
        ("Toxina Densa", {"power_multiplier": 1.3}),
        ("Poca Duradoura", {"duration_multiplier": 1.4}),
        ("Veneno Persistente", {"poison_linger_multiplier": 2.0}),
        ("Poca Itinerante", {"field_follows_player": True}),
        ("Reabrir a Poca", {"cooldown_multiplier": 0.75}),
        ("Poca Leve", {"breath_cost_multiplier": 0.6}),
        ("Duas Pocas", {"extra_charge": 1}),
    ],
}

# Dois grandes modificadores por mecanica, escolhidos no nivel 21.
CAPSTONES = {
    "projectile": [("Retorno", {"return_projectile": True, "power_multiplier": 1.2}),
                   ("Leque Total", {"projectile_count_add": 3, "pierce_add": 2})],
    "boomerang": [("Tempestade de Discos", {"projectile_count_add": 3, "power_multiplier": 0.8}),
                  ("Disco Vampiro", {"life_steal_add": 0.08, "power_multiplier": 1.2})],
    "dash": [("Tempestade Vetorial", {"arrival_damage_add": 60, "arrival_area_add": 120}),
             ("Passo Fantasma", {"invulnerability_multiplier": 2.0, "extra_charge": 1})],
    "nova": [("Supernova", {"radius_multiplier": 1.5, "power_multiplier": 1.3}),
             ("Pulso Triplo", {"repeat_count_add": 2, "repeat_delay": 0.35, "power_multiplier": 0.8})],
    "field": [("Buraco Negro", {"pull_strength_add": 140, "expire_damage_add": 120}),
              ("Campo Eterno", {"duration_multiplier": 2.0, "field_follows_player": True})],
    "barrier": [("Fortaleza", {"barrier_multiplier": 1.8, "duration_multiplier": 1.5}),
                ("Explosao Final", {"expire_nova_damage_add": 120, "contact_damage_add": 30})],
    "chain": [("Rede Total", {"chain_count_add": 5, "power_multiplier": 0.85}),
              ("Tempestade em Cadeia", {"repeat_count_add": 1, "chain_count_add": 2})],
    "summon": [("Legiao", {"summon_count_add": 2, "duration_multiplier": 1.3}),
               ("Colosso", {"power_multiplier": 1.8, "attack_interval_multiplier": 0.85})],
    "sanctuary": [("Santuario Eterno", {"duration_multiplier": 2.0, "healing_multiplier": 1.3}),
                  ("Bastiao", {"stability_add": 0.3, "overheal_barrier": True})],
    "cone": [("Leque da Ceifa", {"angle_multiplier": 2.0, "radius_multiplier": 1.3}),
             ("Ceifa Tripla", {"repeat_count_add": 2, "power_multiplier": 0.8})],
    "beam": [("Lanca de Luz", {"width_multiplier": 2.0, "power_multiplier": 1.4}),
             ("Prisma", {"repeat_count_add": 2, "power_multiplier": 0.75})],
    "orbit": [("Ciclone", {"orbit_count_add": 3, "angular_speed_multiplier": 1.3}),
              ("Orbita Eterna", {"duration_multiplier": 2.5, "power_multiplier": 1.2})],
    "mine": [("Campo Minado", {"extra_charge": 2, "arm_delay_multiplier": 0.5}),
             ("Mina Colossal", {"radius_multiplier": 1.6, "power_multiplier": 1.5})],
    "meteor": [("Chuva de Fogo", {"meteor_count_add": 3, "power_multiplier": 0.8}),
               ("Cataclismo", {"radius_multiplier": 1.5, "power_multiplier": 1.5})],
    "volley": [("Tempestade de Flechas", {"arrow_count_add": 24, "tick_interval_multiplier": 0.85}),
               ("Saraivada Infinita", {"breath_per_second_multiplier": 0.3, "duration_multiplier": 2.0})],
    "spores": [("Praga", {"poison_growth_add": 0.1, "spread_radius_multiplier": 1.5}),
               ("Esporangio Vivo", {"power_multiplier": 2.0, "tick_interval_multiplier": 0.7})],
    "poison_pool": [("Pantano Sem Fim", {"radius_multiplier": 1.6, "duration_multiplier": 1.5}),
                    ("Toxina Letal", {"power_multiplier": 1.8})],
}


def primary_field(gem):
    mechanic = gem["mechanic"]
    if mechanic == "barrier":
        return "barrier"
    if mechanic == "sanctuary":
        return "healing"
    if mechanic == "dash":
        return "trail_damage" if gem.get("trail_damage", 0) > 0 else "arrival_barrier"
    return "power"


def generic(gem):
    primary = primary_field(gem)
    return [
        ("Potencia Refinada", {primary + "_multiplier": 1.2}),
        ("Cadencia Treinada", {"cooldown_multiplier": 0.85}),
        ("Economia de Folego", {"breath_cost_multiplier": 0.7}),
        ("Reserva Profunda", {"extra_charge": 1}),
        ("Alcance Treinado", {"range_multiplier": 1.2}),
        ("Golpe Certeiro", {"critical_chance_add": 0.08}),
        ("Duracao Estendida", {"duration_multiplier": 1.3}),
    ]


def mastery(gem):
    """Escolhas por nivel: {"5": [3], "10": [3], "15": [3], "20": [3], "21": [2]}."""
    synergy = SYNERGY[gem["mechanic"]]
    base = generic(gem)
    result = {}
    used = set()
    for index, level in enumerate(MASTERY_LEVELS[:4]):
        pair = [synergy[index * 2], synergy[index * 2 + 1]]
        keys = {key.rsplit("_", 1)[0] for _, modifiers in pair for key in modifiers}
        # Generico que nao repita campo das duas sinergias do nivel nem um generico ja oferecido.
        candidates = base[index:4] + base[:index] + base[4:]
        extra = next((option for option in candidates
                      if option[0] not in used and not keys & {key.rsplit("_", 1)[0] for key in option[1]}), candidates[0])
        used.add(extra[0])
        offered = pair + [extra]
        result[str(level)] = [{"id": "%s_m%d_%d" % (gem["id"], level, option), "name": name, "modifiers": modifiers}
                              for option, (name, modifiers) in enumerate(offered)]
    result["21"] = [{"id": "%s_m21_%d" % (gem["id"], option), "name": name, "modifiers": modifiers, "capstone": True}
                    for option, (name, modifiers) in enumerate(CAPSTONES[gem["mechanic"]])]
    return result
