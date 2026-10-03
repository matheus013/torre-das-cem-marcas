#!/usr/bin/env python3
"""Gera as arvores de evolucao 10-100 das quatro personagens do beta em data/beta/beta_content.json.

Cada marco oferece seis escolhas: duas de Essencia (evolucoes da Passiva Autoral), duas de Adaptacao
e duas de Convergencia. Os niveis 10 e 20 preservam nomes e textos do documento 71; os niveis 30 a 90
usam evolucoes proprias de cada passiva e um catalogo geral de Adaptacao e Convergencia; todas as
opcoes do nivel 100 concedem mecanica nova (documento 66).

Efeitos ("effects"):
  modifiers  -> modificadores da personagem (X_add soma, X_mult multiplica)
  passive    -> parametros da Passiva Autoral (PassiveRuntime.DEFAULTS)
  mechanics  -> mecanicas executadas pela WorldSimulation
Uso: python3 tools/content/build_character_trees.py
"""
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
CONTENT = ROOT / "data" / "beta" / "beta_content.json"
MAX_LEVEL = 100


def choice(cid, name, branch, desc, stats=None, modifiers=None, passive=None, mechanics=None, kind=None):
    effects = {}
    if modifiers:
        effects["modifiers"] = modifiers
    if passive:
        effects["passive"] = passive
    if mechanics:
        effects["mechanics"] = mechanics
    entry = {"id": cid, "name": name, "branch": branch,
             "kind": kind or ("mechanic" if mechanics or passive_is_mechanic(passive) else "buff")}
    if mechanics:
        entry["mechanic_id"] = mechanics[0]["id"]
    if stats:
        entry["stats"] = stats
    entry["effects"] = effects
    entry["description"] = desc
    return entry


MECHANIC_PASSIVE_KEYS = {"conduct_return", "constellation_damage", "prism_barrier", "memory_every", "shift_free",
                         "emergency_free", "counter_damage", "improv_echo", "route_barrier", "max_samples",
                         "crisis_absorb", "discharge_keep", "city_damage", "collapse_chain", "dual_flow",
                         "trace_echo", "sample_keep", "cast_discharge", "pickup_summon", "overload_power",
                         "conduct_barrier", "discard_breath", "sample_barrier", "opportunity_breath"}


def passive_is_mechanic(passive):
    return bool(passive) and any(key.removesuffix("_add").removesuffix("_mult") in MECHANIC_PASSIVE_KEYS and
                                 not key.endswith(("_add", "_mult")) for key in passive)


def m(mechanic_id, **params):
    return dict({"id": mechanic_id}, **params)


# ------------------------------------------------------------------ catalogo geral

ADAPTATION = {
    30: [("casco_de_campo", "Casco de Campo", "+25 de Vida maxima e 5% menos dano recebido.",
          {"vitality": 5}, {"max_health_add": 25, "damage_taken_mult": 0.95}, None),
         ("passo_treinado", "Passo Treinado", "+6% de movimento e +15% de recuperacao de Folego.",
          {"agility": 5}, {"move_speed_mult": 1.06, "breath_regen_mult": 1.15}, None)],
    40: [("folego_fundo", "Folego Fundo", "+25 de Folego maximo; cada baixa devolve 4 de Folego.",
          {"wisdom": 5}, {"max_breath_add": 25, "breath_on_kill_add": 4}, None),
         ("reflexo_de_corte", "Reflexo de Corte", "Recargas 6% mais rapidas.",
          {"wisdom": 5}, {"cooldown_mult": 0.94}, None)],
    50: [("segunda_respiracao", "Segunda Respiracao", "Abaixo de 30% de Vida, ganha 40 de barreira (uma vez a cada 30 s).",
          {"vitality": 5}, None, [m("last_stand", threshold=0.3, barrier=40, cooldown=30)]),
         ("pele_calejada", "Pele Calejada", "10% menos dano recebido e +30 de Vida maxima.",
          {"vitality": 5}, {"damage_taken_mult": 0.9, "max_health_add": 30}, None)],
    60: [("colheita_de_campo", "Colheita de Campo", "Cada baixa cura 3 de Vida; 3% do dano causado vira Vida.",
          {"vitality": 5}, {"heal_on_kill_add": 3, "life_steal_add": 0.03}, None),
         ("ritmo_constante", "Ritmo Constante", "Ataque automatico 12% mais rapido e 10% mais forte.",
          {"agility": 5}, {"auto_rate_mult": 1.12, "auto_damage_mult": 1.1}, None)],
    70: [("escudo_de_folego", "Escudo de Folego", "Com Folego cheio, a recuperacao excedente vira barreira (ate 40).",
          {"wisdom": 5}, None, [m("breath_shield", cap=40)]),
         ("angulo_morto", "Angulo Morto", "+5% de chance critica e +15% de dano critico.",
          {"fortune": 5}, {"crit_chance_add": 0.05, "crit_damage_add": 0.15}, None)],
    80: [("recarga_de_batalha", "Recarga de Batalha", "Cada baixa reduz em 0,5 s todas as recargas.",
          {"wisdom": 5}, None, [m("cooldown_refund", seconds=0.5)]),
         ("muralha_interior", "Muralha Interior", "Barreiras recebidas +25%, curas +20% e +40 de Vida maxima.",
          {"vitality": 5}, {"barrier_mult": 1.25, "healing_mult": 1.2, "max_health_add": 40}, None)],
    90: [("marca_do_sobrevivente", "Marca do Sobrevivente", "Abaixo de 35% de Vida, ganha 80 de barreira (a cada 25 s); 8% menos dano.",
          {"vitality": 5}, {"damage_taken_mult": 0.92}, [m("last_stand", threshold=0.35, barrier=80, cooldown=25)]),
         ("impulso_final", "Impulso Final", "+8% de movimento, recargas 8% mais rapidas e +5% de potencia.",
          {"agility": 5}, {"move_speed_mult": 1.08, "cooldown_mult": 0.92, "power_mult": 1.05}, None)],
}

CONVERGENCE = {
    30: [("presenca_firme", "Presenca Firme", "Aliados a ate 180 unidades recebem 5% menos dano.",
          {"vitality": 5}, {"ally_damage_reduction_add": 0.05}, None),
         ("sinal_de_avanco", "Sinal de Avanco", "Aliados a ate 180 unidades causam 5% mais dano com gemas.",
          {"wisdom": 5}, {"ally_power_add": 0.05}, None)],
    40: [("laco_de_protecao", "Laco de Protecao", "30% de toda barreira recebida tambem protege aliados proximos.",
          {"intelligence": 5}, None, [m("ally_link", ratio=0.3)]),
         ("pontaria_coletiva", "Pontaria Coletiva", "Acertos em inimigos lentos ou vulneraveis causam 12% a mais.",
          {"fortune": 5}, None, [m("shared_condition", bonus=0.12)])],
    50: [("fogo_cruzado", "Fogo Cruzado", "O ataque automatico salta para mais um inimigo com 50% do dano.",
          {"agility": 5}, None, [m("auto_chain", targets=1, ratio=0.5)]),
         ("resgate_atento", "Resgate Atento", "Aliado proximo abaixo de 30% de Vida recebe 35 de barreira (a cada 20 s).",
          {"wisdom": 5}, None, [m("rescue", threshold=0.3, barrier=35, cooldown=20)])],
    60: [("eco_de_grupo", "Eco de Grupo", "Aliados proximos +8% de dano com gemas; areas 10% maiores.",
          {"intelligence": 5}, {"ally_power_add": 0.08, "radius_mult": 1.1}, None),
         ("muro_compartilhado", "Muro Compartilhado", "Aliados proximos recebem 7% menos dano; cada gema concede 4 de barreira.",
          {"vitality": 5}, {"ally_damage_reduction_add": 0.07, "barrier_on_skill_add": 4}, None)],
    70: [("marca_comum", "Marca Comum", "Acertos em inimigos lentos ou vulneraveis +20%; condicoes duram 15% mais.",
          {"fortune": 5}, {"duration_mult": 1.15}, [m("shared_condition", bonus=0.2)]),
         ("fileira_unida", "Fileira Unida", "45% de toda barreira recebida tambem protege aliados proximos.",
          {"vitality": 5}, None, [m("ally_link", ratio=0.45)])],
    80: [("estilhaco_coletivo", "Estilhaco Coletivo", "Inimigos derrotados explodem: 25 de dano em raio 90.",
          {"strength": 5}, None, [m("kill_burst", radius=90, damage=25)]),
         ("arsenal_aberto", "Arsenal Aberto", "Gemas de area e de projetil +12% de potencia.",
          {"intelligence": 5}, {"power_area_mult": 1.12, "power_projectile_mult": 1.12}, None)],
    90: [("vigilia_mutua", "Vigilia Mutua", "Aliado abaixo de 35% recebe 60 de barreira (a cada 15 s); aliados proximos 5% menos dano.",
          {"wisdom": 5}, {"ally_damage_reduction_add": 0.05}, [m("rescue", threshold=0.35, barrier=60, cooldown=15)]),
         ("convergencia_total", "Convergencia Total", "Aliados proximos +10% de dano com gemas; +6% de potencia propria.",
          {"intelligence": 5}, {"ally_power_add": 0.1, "power_mult": 1.06}, None)],
}

FINAL_GENERAL = {
    "adaptation": [
        ("folego_transbordante", "Folego Transbordante",
         "Excesso de Folego vira escudo (ate 90) e o Folego recupera 25% mais rapido.",
         {"wisdom": 5}, {"breath_regen_mult": 1.25}, [m("breath_shield", cap=90)]),
        ("impressao_do_golpe", "Impressao do Golpe",
         "O ataque automatico copia lentidao, vulnerabilidade e roubo de vida da ultima gema e causa 20% mais dano.",
         {"agility": 5}, {"auto_damage_mult": 1.2}, [m("auto_imprint", ratio=1.0)]),
    ],
    "convergence": [
        ("condicao_partilhada", "Condicao Partilhada",
         "Acertos em inimigos lentos ou vulneraveis +30%; toda gema deixa o alvo vulneravel (10%).",
         {"fortune": 5}, None, [m("shared_condition", bonus=0.3, apply_vulnerable=0.1)]),
        ("eco_duplo", "Eco Duplo", "A cada terceira gema, ela se repete com 50% da potencia.",
         {"intelligence": 5}, None, [m("skill_echo", every=3, ratio=0.5)]),
    ],
}

# ------------------------------------------------------------------ essencia por personagem

ESSENCE = {
    "eloa": {
        30: [("fio_longo", "Fio Longo", "Conducoes alcancam 80 unidades a mais e causam +4.", {"intelligence": 5},
              {"conduct_range_add": 80, "conduct_amount_add": 4}),
             ("brasa_residual", "Brasa Residual", "Residuos duram 2 s a mais e conduzem +3.", {"intelligence": 5},
              {"residue_lifetime_add": 2, "conduct_amount_add": 3})],
        40: [("malha_densa", "Malha Densa", "Mantem um residuo adicional.", {"wisdom": 5}, {"max_residues_add": 1}),
             ("retorno_aceso", "Retorno Aceso", "Conducoes retornam com +25% da potencia.", {"intelligence": 5},
              {"conduct_return_add": 0.25})],
        50: [("circuito_pleno", "Circuito Pleno", "Conducoes 30% mais fortes.", {"intelligence": 5},
              {"conduct_amount_mult": 1.3}),
             ("sobrecarga_domada", "Sobrecarga Domada", "Cada residuo consumido +6% de potencia na gema; conducao concede 6 de barreira.",
              {"wisdom": 5}, {"overload_power_add": 0.06, "conduct_barrier_add": 6})],
        60: [("constelacao_menor", "Constelacao Menor", "Tres residuos formam circuito: +25 de dano no centro ao conduzir.",
              {"intelligence": 5}, {"constellation_damage_add": 25}),
             ("residuo_persistente", "Residuo Persistente", "Residuos duram 3 s a mais e um residuo adicional.",
              {"wisdom": 5}, {"residue_lifetime_add": 3, "max_residues_add": 1})],
        70: [("arco_duplo", "Arco Duplo", "Conducoes retornam com +35% da potencia.", {"intelligence": 5},
              {"conduct_return_add": 0.35}),
             ("prisma_atento", "Prisma Atento", "Com residuos cheios, dano grave gera +25 de barreira e onda.",
              {"vitality": 5}, {"prism_barrier_add": 25})],
        80: [("corrente_ferral", "Corrente Ferral", "Conducoes 35% mais fortes e 60 unidades mais longas.",
              {"intelligence": 5}, {"conduct_amount_mult": 1.35, "conduct_range_add": 60}),
             ("memoria_viva", "Memoria Viva", "A cada segunda conducao, ela se repete por completo.", {"wisdom": 5},
              {"memory_every": 2})],
        90: [("malha_soberana", "Malha Soberana", "Mantem dois residuos adicionais.", {"wisdom": 5},
              {"max_residues_add": 2}),
             ("luz_concentrada", "Luz Concentrada", "Cada residuo consumido +10% de potencia; constelacao +30.",
              {"intelligence": 5}, {"overload_power_add": 0.1, "constellation_damage_add": 30})],
        100: [("circuito_eterno", "Circuito Eterno", "Toda conducao se repete por completo e retorna com mais 50%.",
               {"intelligence": 5}, {"memory_every": 1, "conduct_return_add": 0.5}),
              ("coracao_de_residuo", "Coracao de Residuo", "Conduzir com tres residuos explode o circuito (+45) e concede 15 de barreira.",
               {"wisdom": 5}, {"constellation_damage_add": 45, "conduct_barrier_add": 15})],
    },
    "sena": {
        30: [("traco_firme", "Traco Firme", "Cada Tracado +3% de potencia.", {"strength": 5}, {"trace_power_add": 0.03}),
             ("desvio_leve", "Desvio Leve", "Cada Desvio -5% de Folego e +2% de movimento.", {"agility": 5},
              {"deviation_breath_add": 0.05, "deviation_speed_add": 0.02})],
        40: [("rota_longa", "Rota Longa", "Tracado e Desvio acumulam um ponto a mais.", {"wisdom": 5},
              {"max_currents_add": 1}),
             ("contrapeso", "Contrapeso", "Sofrer dano com Tracado devolve +10 de dano por ponto ao redor.",
              {"strength": 5}, {"counter_damage_add": 10})],
        50: [("plano_mestre", "Plano Mestre", "Cada Tracado +5% de potencia e improvisar nao o reduz.", {"strength": 5},
              {"trace_power_add": 0.05, "trace_loss": 0}),
             ("salto_improvisado", "Salto Improvisado", "Em Desvio maximo, a acao diferente ecoa com +30% de potencia.",
              {"agility": 5}, {"improv_echo_add": 0.3})],
        60: [("correnteza", "Correnteza", "Cada Desvio +4% de movimento.", {"agility": 5}, {"deviation_speed_add": 0.04}),
             ("guarda_de_rota", "Guarda de Rota", "Gemas com Tracado protegem aliados proximos (+6 por ponto).",
              {"vitality": 5}, {"route_barrier_add": 6})],
        70: [("rota_ampla", "Rota Ampla", "Um ponto a mais em cada corrente e +2% de potencia por Tracado.",
              {"wisdom": 5}, {"max_currents_add": 1, "trace_power_add": 0.02}),
             ("desvio_perfeito", "Desvio Perfeito", "Em Desvio maximo, a proxima acao diferente e gratuita.",
              {"agility": 5}, {"emergency_free": 1, "deviation_breath_add": 0.05})],
        80: [("contrarrota_afiada", "Contrarrota Afiada", "Dano recebido com Tracado devolve +20 por ponto.",
              {"strength": 5}, {"counter_damage_add": 20}),
             ("eco_de_caravana", "Eco de Caravana", "Eco do improviso +30% de potencia.", {"agility": 5},
              {"improv_echo_add": 0.3})],
        90: [("mapa_completo", "Mapa Completo", "Cada Tracado +6% de potencia.", {"strength": 5}, {"trace_power_add": 0.06}),
             ("vento_contrario", "Vento Contrario", "Cada Desvio +5% de movimento; trocar de rota com Tracado alto e gratuito.",
              {"agility": 5}, {"deviation_speed_add": 0.05, "shift_free": 1})],
        100: [("correntes_unidas", "Correntes Unidas", "Improvisar tambem gera Tracado: as duas correntes deixam de se anular.",
               {"wisdom": 5}, {"dual_flow": 1, "trace_loss": 0}),
              ("rota_absoluta", "Rota Absoluta", "Repetir com Tracado maximo ecoa a gema com 60% da potencia.",
               {"strength": 5}, {"trace_echo": 0.6})],
    },
    "cira": {
        30: [("placa_espessa", "Placa Espessa", "Amostra reduz mais 5% do dano.", {"vitality": 5},
              {"sample_reduction_add": 0.05}),
             ("reacao_viva", "Reacao Viva", "Descarga causa +20 de dano.", {"intelligence": 5},
              {"discharge_amount_add": 20})],
        40: [("amostra_dupla", "Amostra Dupla", "Armazena uma amostra adicional.", {"wisdom": 5}, {"max_samples_add": 1}),
             ("instabilidade_util", "Instabilidade Util", "Instabilidade sobe 30% mais rapido; descarga 20 unidades maior.",
              {"intelligence": 5}, {"instability_gain_mult": 1.3, "discharge_radius_add": 20})],
        50: [("infusao_forte", "Infusao Forte", "Amostra consumida +20% de potencia na gema.", {"intelligence": 5},
              {"sample_power_add": 0.2}),
             ("revestimento_reativo", "Revestimento Reativo", "Armazenar amostra concede +10 de barreira.",
              {"vitality": 5}, {"sample_barrier_add": 10})],
        60: [("crise_controlada", "Crise Controlada", "Abaixo de 35% de Vida, 20% do dano vira Instabilidade.",
              {"vitality": 5}, {"crisis_absorb_add": 0.2}),
             ("descarga_contida", "Descarga Contida", "Descarga conserva +30% da Instabilidade.", {"wisdom": 5},
              {"discharge_keep_add": 0.3})],
        70: [("camadas_vivas", "Camadas Vivas", "Uma amostra adicional e mais 5% de reducao.", {"vitality": 5},
              {"max_samples_add": 1, "sample_reduction_add": 0.05}),
             ("catalise", "Catalise", "Amostra consumida +25% de potencia.", {"intelligence": 5},
              {"sample_power_add": 0.25})],
        80: [("grande_reacao", "Grande Reacao", "Descarga 60% mais forte e 40 unidades maior.", {"intelligence": 5},
              {"discharge_amount_mult": 1.6, "discharge_radius_add": 40}),
             ("pele_de_crise", "Pele de Crise", "Mais 20% do dano sob Vida baixa vira Instabilidade.", {"vitality": 5},
              {"crisis_absorb_add": 0.2})],
        90: [("laboratorio_completo", "Laboratorio Completo", "Uma amostra adicional e +10 de barreira ao armazenar.",
              {"wisdom": 5}, {"max_samples_add": 1, "sample_barrier_add": 10}),
             ("ruptura_total", "Ruptura Total", "Descarga causa +60.", {"intelligence": 5}, {"discharge_amount_add": 60})],
        100: [("forma_adaptada", "Forma Adaptada", "Gemas aproveitam a amostra sem consumi-la.", {"vitality": 5},
               {"sample_keep": 1}),
              ("nucleo_instavel", "Nucleo Instavel", "Com metade da Instabilidade, cada gema dispara uma descarga menor.",
               {"intelligence": 5}, {"cast_discharge": 0.5})],
    },
    "rui": {
        30: [("viga_extra", "Viga Extra", "Uma Oportunidade adicional.", {"strength": 5}, {"max_opportunities_add": 1}),
             ("impacto_calculado", "Impacto Calculado", "Oportunidades causam +10 de dano.", {"strength": 5},
              {"opportunity_damage_add": 10})],
        40: [("canteiro_rapido", "Canteiro Rapido", "Oportunidades surgem a cada terceiro acerto.", {"agility": 5},
              {"hits_per_opportunity": 3}),
             ("abrigo_de_obra", "Abrigo de Obra", "Oportunidades concedem +10 de barreira.", {"vitality": 5},
              {"opportunity_barrier_add": 10})],
        50: [("demolicao_fina", "Demolicao Fina", "Oportunidades 40% mais fortes e 20 unidades maiores.",
              {"strength": 5}, {"opportunity_damage_mult": 1.4, "opportunity_radius_add": 20}),
             ("obra_duravel", "Obra Duravel", "Oportunidades duram 6 s a mais e devolvem 8 de Folego.", {"wisdom": 5},
              {"opportunity_lifetime_add": 6, "opportunity_breath_add": 8})],
        60: [("colapso_em_serie", "Colapso em Serie", "Usar uma Oportunidade abala as proximas (+40%).",
              {"strength": 5}, {"collapse_chain_add": 0.4}),
             ("cidade_rapida", "Cidade Rapida", "Tres Oportunidades em 6 s erguem obra maior (+40 de dano).",
              {"intelligence": 5}, {"city_damage_add": 40})],
        70: [("fundacao_larga", "Fundacao Larga", "Uma Oportunidade adicional e +20 de raio.", {"strength": 5},
              {"max_opportunities_add": 1, "opportunity_radius_add": 20}),
             ("escora_forte", "Escora Forte", "Oportunidades concedem +15 de barreira.", {"vitality": 5},
              {"opportunity_barrier_add": 15})],
        80: [("grande_obra", "Grande Obra", "Obra maior causa +60.", {"intelligence": 5}, {"city_damage_add": 60}),
             ("demolicao_total", "Demolicao Total", "Oportunidades 50% mais fortes.", {"strength": 5},
              {"opportunity_damage_mult": 1.5})],
        90: [("engenharia_plena", "Engenharia Plena", "Duas Oportunidades adicionais.", {"wisdom": 5},
              {"max_opportunities_add": 2}),
             ("andaime_vivo", "Andaime Vivo", "Oportunidades devolvem +12 de Folego e +10 de barreira.", {"vitality": 5},
              {"opportunity_breath_add": 12, "opportunity_barrier_add": 10})],
        100: [("cidade_viva", "Cidade Viva", "Oportunidades surgem a cada segundo acerto e duas bastam para a obra maior.",
               {"strength": 5}, {"hits_per_opportunity": 2, "city_threshold": 2, "city_damage_add": 50}),
              ("geometria_final", "Geometria Final", "Cada Oportunidade usada ergue um Molde Vigilante por 8 s.",
               {"intelligence": 5}, {"pickup_summon": 8})],
    },
}

# Efeitos concretos dos niveis 10 e 20 ja nomeados no documento 71 (valores provisorios).
EARLY_EFFECTS = {
    "eloa_malha_estavel": {"passive": {"max_residues_add": 1, "conduct_amount_mult": 0.85}},
    "eloa_sobretensao": {"passive": {"overload_power": 0.12}},
    "eloa_dissipador_ferral": {"passive": {"discard_breath": 8}, "modifiers": {"damage_taken_mult": 0.95}},
    "eloa_fio_de_guarda": {"passive": {"conduct_barrier": 10}},
    "eloa_circuito_partilhado": {"mechanics": [m("ally_feed")]},
    "eloa_no_material": {"passive": {"residue_lifetime_add": 3}, "modifiers": {"barrier_on_skill_add": 4}},
    "eloa_arco_recursivo": {"passive": {"conduct_return": 0.5}},
    "eloa_constelacao_residual": {"passive": {"constellation_damage": 30}},
    "eloa_passo_luminar": {"mechanics": [m("dash_nova", radius=80, damage=22)]},
    "eloa_prisma_de_emergencia": {"passive": {"prism_barrier": 30}},
    "eloa_rede_expedicionaria": {"passive": {"max_residues_add": 1}, "mechanics": [m("ally_feed")]},
    "eloa_memoria_de_circuito": {"passive": {"memory_every": 3}},
    "sena_plano_cumprido": {"passive": {"trace_loss": 0, "trace_power_add": 0.03}},
    "sena_mudanca_de_rumo": {"passive": {"shift_free": 1}},
    "sena_passo_de_emergencia": {"passive": {"emergency_free": 1}},
    "sena_ponto_movel": {"passive": {"deviation_speed_add": 0.04}, "modifiers": {"move_speed_mult": 1.04}},
    "sena_via_compartilhada": {"passive": {"route_barrier": 6}},
    "sena_retirada_ordenada": {"mechanics": [m("rescue", threshold=0.4, barrier=25, cooldown=20)]},
    "sena_cartografia_cinetica": {"mechanics": [m("skill_echo", every=4, ratio=0.4)]},
    "sena_contrarrota": {"passive": {"counter_damage": 12}},
    "sena_rota_impossivel": {"mechanics": [m("dash_nova", radius=90, damage=25)]},
    "sena_improviso_perfeito": {"passive": {"improv_echo": 0.5}},
    "sena_rede_de_caravana": {"passive": {"route_barrier": 8}, "modifiers": {"ally_power_add": 0.05}},
    "sena_todos_retornam": {"mechanics": [m("rescue", threshold=0.3, barrier=50, cooldown=15)]},
    "cira_reacao_em_cadeia": {"passive": {"discharge_keep": 0.3, "discharge_radius_add": 30}},
    "cira_saturacao_escolhida": {"passive": {"sample_power_add": 0.2, "instability_gain_mult": 1.2}},
    "cira_placas_de_abrigo": {"passive": {"sample_barrier": 6}, "mechanics": [m("ally_link", ratio=0.3)]},
    "cira_compatibilidade_forcada": {"passive": {"sample_reduction_add": 0.1}},
    "cira_transposicao_segura": {"passive": {"discharge_amount_add": 15}, "modifiers": {"damage_taken_mult": 0.95}},
    "cira_amostra_partilhada": {"modifiers": {"ally_power_add": 0.06}},
    "cira_catalisador_vivo": {"mechanics": [m("auto_imprint", ratio=1.0)]},
    "cira_ruptura_controlada": {"passive": {"discharge_amount_mult": 2.0, "discharge_keep": 0.2}},
    "cira_pele_de_muitas_camadas": {"passive": {"max_samples": 2}},
    "cira_metabolismo_de_crise": {"passive": {"crisis_absorb": 0.3}},
    "cira_laboratorio_ambulante": {"passive": {"sample_barrier": 10, "instability_gain_mult": 1.25}},
    "cira_reacao_coletiva": {"mechanics": [m("shared_condition", bonus=0.15)], "modifiers": {"ally_power_add": 0.05}},
    "rui_obra_reutilizavel": {"passive": {"opportunity_breath": 10, "opportunity_lifetime_add": 4}},
    "rui_demolicao_calculada": {"passive": {"opportunity_damage_mult": 1.4}},
    "rui_kit_autonomo": {"passive": {"hits_per_opportunity": 3}},
    "rui_escora_movel": {"passive": {"max_opportunities_add": 1}},
    "rui_planta_partilhada": {"mechanics": [m("ally_feed")]},
    "rui_ponto_de_trabalho": {"modifiers": {"ally_damage_reduction_add": 0.06}},
    "rui_cidade_instantanea": {"passive": {"city_damage": 60}},
    "rui_colapso_dirigido": {"passive": {"collapse_chain": 0.6}},
    "rui_geometria_portatil": {"mechanics": [m("summon_on_kill", chance=0.15, duration=8)]},
    "rui_obra_sem_chao": {"mechanics": [m("dash_nova", radius=90, damage=20)]},
    "rui_mutirao": {"mechanics": [m("ally_link", ratio=0.35)]},
    "rui_arquitetura_viva": {"mechanics": [m("summon_on_kill", chance=0.2, duration=8)]},
}


def general(prefix, level, spec, branch, kind=None):
    slug, name, desc, stats, modifiers, mechanics = spec
    return choice("%s_%s" % (prefix, slug), name, branch, desc, stats, modifiers, None, mechanics, kind)


def build_tree(character, early):
    tree = {}
    for level_text in ("10", "20"):
        entries = []
        for entry in early[level_text]:
            entry = dict(entry)
            entry["effects"] = EARLY_EFFECTS[entry["id"]]
            description = entry.pop("description")
            entry["description"] = description
            entries.append(entry)
        tree[level_text] = entries
    for level in range(30, MAX_LEVEL + 1, 10):
        final = level == MAX_LEVEL
        kind = "mechanic" if final else None
        entries = []
        for slug, name, desc, stats, passive in ESSENCE[character][level]:
            entries.append(choice("%s_%s" % (character, slug), name, "essence", desc, stats, None, passive, None,
                                  "mechanic" if final else "buff"))
        if final:
            for spec in FINAL_GENERAL["adaptation"]:
                entries.append(general("geral", level, spec, "adaptation", "mechanic"))
            for spec in FINAL_GENERAL["convergence"]:
                entries.append(general("geral", level, spec, "convergence", "mechanic"))
        else:
            for spec in ADAPTATION[level]:
                entries.append(general("geral", level, spec, "adaptation", kind))
            for spec in CONVERGENCE[level]:
                entries.append(general("geral", level, spec, "convergence", kind))
        tree[str(level)] = entries
    return tree


def format_tree(tree):
    lines = ['      "milestones":{']
    keys = list(tree.keys())
    for index, level in enumerate(keys):
        lines.append('        "%s":[' % level)
        entries = tree[level]
        for position, entry in enumerate(entries):
            text = json.dumps(entry, ensure_ascii=False, separators=(",", ":"))
            lines.append("          %s%s" % (text, "," if position < len(entries) - 1 else ""))
        lines.append("        ]%s" % ("," if index < len(keys) - 1 else ""))
    lines.append("      }")
    return lines


def main():
    data = json.loads(CONTENT.read_text(encoding="utf-8"))
    characters = {entry["id"]: entry for entry in data["playable_characters"]}
    lines = CONTENT.read_text(encoding="utf-8").split("\n")
    output = []
    index = 0
    current = None
    while index < len(lines):
        line = lines[index]
        match = re.match(r'\s+"id":"(\w+)","name":"[^"]+","people"', line)
        if match:
            current = match.group(1)
            line = re.sub(r'"max_level":\d+', '"max_level":%d' % MAX_LEVEL, line)
        if current and line.strip() == '"milestones":{':
            early = characters[current]["milestones"]
            output.extend(format_tree(build_tree(current, early)))
            depth = 1
            index += 1
            while depth > 0:
                depth += lines[index].count("{") - lines[index].count("}")
                index += 1
            current = None
            continue
        output.append(line)
        index += 1
    CONTENT.write_text("\n".join(output), encoding="utf-8")
    json.loads(CONTENT.read_text(encoding="utf-8"))
    print("arvores 10-%d geradas para %s" % (MAX_LEVEL, ", ".join(characters)))


if __name__ == "__main__":
    main()
