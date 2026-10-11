"""Passivas exclusivas de armas unicas e itens lendarios (decisao 580).

Cada passiva e dados para o motor src/gameplay/items/item_passives.gd: `mods` fixos e `triggers`
(gatilho + filtros + acoes). Usado por build_unique_weapons.py (uma passiva por gema, focada nela)
e por build_legendary_items.py (lendarios genericos: elemento, tipo de dano, autoataque,
invocacoes e sobrevivencia). Meta de design: uma unica peca destas deve bastar para levar a
personagem ate o fim da historia; sao a base das dificuldades do pos-jogo.
"""


def T(on, *actions, **filters):
    """Gatilho: tipo (cast, hit, kill, hurt, lethal, interval), filtros e acoes."""
    return dict(on=on, **filters, actions=list(actions))


def A(do, **params):
    return dict(do=do, **params)


def P(name, description, *triggers, mods=None, transform=None, transform_from=None):
    """Passiva. `transform` sobrescreve campos da gema da arma unica (ate a mecanica) e
    `transform_from` deriva campos de outros: {"campo": ["origem", fator]} (decisao 598)."""
    passive = {"name": name, "description": description}
    if mods:
        passive["mods"] = mods
    if triggers:
        passive["triggers"] = list(triggers)
    if transform:
        passive["transform"] = transform
    if transform_from:
        passive["transform_from"] = transform_from
    return passive


# ------------------------------------------------------------------ armas unicas (uma por gema)

def unique_passives():
    def own(gem):
        return {"gem": gem}

    return {
        # Projeteis
        "agulha_lastro": P("Agulha Errante", "A Agulha nao para no primeiro alvo: ricocheteia entre ate 6 inimigos e volta a mao.",
                           transform={"ricochet": 6, "return_projectile": True}),
        "lanca_ferral": P("Lanca de Ida e Volta", "A Lanca atravessa todos os inimigos no caminho e volta atravessando de novo.",
                          transform={"pierce": 99, "return_projectile": True}),
        "estilhacos_lunares": P("Lua Cheia", "Criticos dos Estilhacos reduzem 1 s da recarga de todas as gemas e devolvem 3 de Folego. Chance critica +10%.",
                                T("hit", A("refund", scope="all", seconds=1.0), A("breath", amount=3), crit=True, **own("estilhacos_lunares")),
                                mods={"crit_chance_add": 0.10}),
        "orbe_de_ruptura": P("Orbe Gravitacional", "O Orbe para no ponto mirado como um campo que puxa os inimigos por 3 s e explode com o dobro do golpe.",
                             transform={"mechanic": "field", "duration": 3.0, "pull_strength": 140, "tick_interval": 0.5, "radius": 150},
                             transform_from={"expire_damage": ["power", 2.0], "power": ["power", 0.15]}),
        "bola_de_fogo": P("Sol Cativo", "A Bola de Fogo vira um sol que acompanha a personagem por 6 s, queimando quem chega perto (acertos incendeiam com 60% do golpe em 3 s).",
                          T("hit", A("burn", ratio=0.6, duration=3.0), **own("bola_de_fogo")),
                          transform={"mechanic": "field", "field_follows_player": True, "duration": 6.0, "tick_interval": 0.5, "radius": 120},
                          transform_from={"power": ["power", 0.3]}),
        "bolha_corrosiva": P("Bolha que se Divide", "Ao estourar, a Bolha se divide em 3 bolhas que seguem viagem.",
                             transform={"fork_count": 3}),
        "cometa_sombrio": P("Eclipse Faminto", "Abate com o Cometa Sombrio zera a recarga dele e recupera 4% da Vida.",
                            T("kill", A("refund", scope="trigger", seconds=99), A("heal", ratio=0.04), **own("cometa_sombrio"))),
        "esfera_de_gelo": P("Zero Absoluto", "Inimigo comum ou elite atingido pela Esfera abaixo de 25% da Vida se estilhaca, soltando 3 esferas menores (40% do golpe) contra os mais proximos.",
                            T("hit", A("execute", below=0.25), **own("esfera_de_gelo")),
                            T("kill", A("cast", gem="esfera_de_gelo", at="nearest", count=3, power=0.4), **own("esfera_de_gelo"))),
        "disco_de_retorno": P("Discos Gemeos", "O Disco nao e lancado: dois discos orbitam a personagem por 8 s cortando quem chega perto.",
                              transform={"mechanic": "orbit", "orbit_count": 2, "duration": 8.0, "radius": 110, "angular_speed": 3.5, "collision_radius": 26, "tick_interval": 0.3, "deploy_limit": 1},
                              transform_from={"power": ["power", 0.6]}),
        "saraivada_de_flechas": P("Olho da Tempestade", "A Saraivada fica ancorada onde foi lancada, girando com o dobro de flechas; a personagem fica livre para andar.",
                                  transform={"volley_anchor": True},
                                  transform_from={"arrow_count": ["arrow_count", 2.0]}),
        # Dash
        "passo_vetorial": P("Passo Alem", "Depois do Passo, todas as gemas ganham +50% de potencia por 4 s e as outras recargas andam 1,5 s.",
                            T("cast", A("buff", id="passo_alem", mods={"power_mult": 1.5}, duration=4.0), A("refund", scope="all", seconds=1.5), **own("passo_vetorial"))),
        "corte_vetorial": P("Corte em Cadeia", "Abater um inimigo com o Corte zera a recarga dele: com alvos por perto, da para cortar sem parar.",
                            T("kill", A("refund", scope="trigger", seconds=99), **own("corte_vetorial"))),
        "salto_de_guarda": P("Salto do Martelo", "O Salto vira um golpe de aterrissagem: esmaga em volta com 250% da barreira de chegada e repele os atingidos.",
                             transform={"arrival_area": 140, "knockback": 130},
                             transform_from={"arrival_damage": ["arrival_barrier", 2.5]}),
        # Nova
        "pulso_cicatriz": P("Pulso Constante", "O Pulso dispara sozinho a cada 1,5 s enquanto houver inimigos perto, sem custo.",
                            T("interval", A("cast", gem="pulso_cicatriz", use_slot=True, at="self", power=1.0), seconds=1.5)),
        "anel_de_geada": P("Inverno que Prende", "O Anel imobiliza por completo por 1,5 s (metade em chefes), mas quase nao causa dano.",
                           transform={"root": True, "status_duration": 1.5},
                           transform_from={"power": ["power", 0.1]}),
        "ruptura_sismica": P("Fenda", "A Ruptura vira uma fissura em linha reta ate o alvo, atingindo e repelindo tudo no caminho.",
                             transform={"mechanic": "beam", "width": 80, "range": 520}),
        # Campo
        "prisao_gravitica": P("Repulsao", "A Prisao acompanha a personagem e expulsa os inimigos de perto, ferindo quem insiste.",
                              transform={"field_follows_player": True, "pull_strength": -220, "radius": 150, "deploy_limit": 1}),
        "brasa_persistente": P("Fogueira Perene", "A Brasa nao se apaga: so pode haver uma, e lancar de novo a muda de lugar.",
                               transform={"duration": 3600.0, "expire_damage": 0, "deploy_limit": 1}),
        "pantano_acido": P("Pantano Contagioso", "Inimigo que morre dentro do Pantano abre um novo Pantano no lugar (60% da potencia).",
                           T("kill", A("cast", gem="pantano_acido", at="target", power=0.6), **own("pantano_acido"))),
        "raizes_presas": P("Trilha de Raizes", "As Raizes acompanham a personagem e prendem quem chega perto.",
                           transform={"field_follows_player": True, "deploy_limit": 1}),
        # Barreira
        "muralha_refeita": P("Muralha Ofensiva", "A barreira que sobrar quando a Muralha acaba explode em volta com 3x o valor.",
                             transform_from={"expire_nova_damage": ["barrier", 3.0]}),
        "casca_reativa": P("Casca Espelhada", "Todo golpe recebido volta em area com 400% do dano. Dano recebido -15%.",
                           T("hurt", A("burst", at="self", radius=140, ratio=4.0, element="earth"), cooldown=0.4),
                           mods={"damage_taken_mult": 0.85}),
        # Corrente
        "elo_residual": P("Elo Infinito", "Inimigo abatido pelo Elo dispara um novo Elo contra o inimigo mais proximo com 80% da potencia.",
                          T("kill", A("cast", gem="elo_residual", at="nearest", power=0.8), cooldown=0.2, **own("elo_residual"))),
        "arco_voltaico": P("Arco Infinito", "O Arco salta ate 30 vezes entre inimigos proximos.",
                           transform={"chain_count": 30}),
        "dreno_em_rede": P("Fome da Rede", "Cada abate feito pela Rede da +2% de dano de trevas ate sair da Torre (ate +200%).",
                           T("kill", A("buff", id="fome_da_rede", mods={"power_dark_mult": 1.02}, duration=86400.0, stacks=100), **own("dreno_em_rede"))),
        # Invocacao
        "molde_vigilante": P("Matriz Viva", "Um Molde novo surge sozinho a cada 8 s ao lado do inimigo mais proximo.",
                             T("interval", A("cast", gem="molde_vigilante", at="nearest", power=1.0), seconds=8.0)),
        "sentinela_ferral": P("Sentinela Eterna", "As Sentinelas nao expiram; lancar de novo substitui as mais antigas.",
                              transform={"duration": 3600.0}),
        "enxame_luminar": P("Enxame Faminto", "Cada abate do Enxame gera um enxame novo no lugar (no maximo um por segundo).",
                            T("kill", A("cast", gem="enxame_luminar", at="target", power=0.6), cooldown=1.0, **own("enxame_luminar"))),
        "guardiao_de_lastro": P("Guardiao Imortal", "Ao ser ferida, um Guardiao surge de graca (uma vez a cada 15 s) com barreira de 20% da Vida.",
                                T("hurt", A("cast", gem="guardiao_de_lastro", at="self", power=1.0), A("barrier", ratio=0.2, duration=5.0), cooldown=15.0)),
        # Santuario
        "semeadura_vital": P("Jardim Andante", "O Jardim acompanha a personagem enquanto dura.",
                             transform={"field_follows_player": True}),
        "circulo_de_reparo": P("Circulo do Tempo", "Dentro do Circulo, as recargas de todo o grupo andam 3x mais rapido.",
                               transform={"cooldown_rate": 3.0}),
        "abrigo_de_escora": P("Abrigo Inquebravel", "Dentro do Abrigo ninguem do grupo cai: o golpe fatal deixa com 1 de Vida.",
                              transform={"prevents_fall": True}),
        # Cone
        "ceifa_ampla": P("Ceifa Giratoria", "A Ceifa corta em 360 graus em volta da personagem.",
                         transform={"angle": 6.3}),
        "sopro_criogenico": P("Raio Congelante", "O Sopro vira um feixe longo e fino que congela tudo em linha.",
                              transform={"mechanic": "beam", "range": 700, "width": 60}),
        # Feixe
        "raio_prismatico": P("Prisma Dividido", "Cada lancamento do Raio sai em 3 feixes, um para cada inimigo diferente (os extras com 70%).",
                             T("cast", A("cast", gem="raio_prismatico", at="nearest", count=2, power=0.7, skip_target=True), **own("raio_prismatico"))),
        "fio_desintegrador": P("Desintegracao", "O Fio executa inimigos comuns e elites abaixo de 30% da Vida.",
                               T("hit", A("execute", below=0.3), **own("fio_desintegrador"))),
        # Orbita
        "laminas_orbitais": P("Ciclone Perpetuo", "As Laminas nao expiram: ficam girando ate a personagem sair do andar.",
                              transform={"duration": 3600.0, "deploy_limit": 1}),
        "satelites_de_geada": P("Constelacao", "Os Satelites orbitam o inimigo mais proximo em vez da personagem, congelando quem estiver em volta dele.",
                                transform={"orbit_target": "nearest"}),
        # Mina
        "mina_de_lastro": P("Mina Viva", "Armadas, as Minas andam ate o inimigo mais proximo.",
                            transform={"seek_speed": 150}),
        "semente_explosiva": P("Semente Fertil", "Inimigo abatido pela Semente planta outra no lugar com 60% da potencia.",
                               T("kill", A("cast", gem="semente_explosiva", at="target", power=0.6), cooldown=0.4, **own("semente_explosiva"))),
        # Meteoro
        "chuva_ferral": P("Artilharia Ferral", "A Chuva cai sozinha a cada 2 s no inimigo mais proximo.",
                          T("interval", A("cast", gem="chuva_ferral", use_slot=True, at="nearest", power=1.0), seconds=2.0)),
        "cometa_de_vidro": P("Cometa Guiado", "O Cometa cai sempre no inimigo com mais Vida perto do ponto mirado.",
                             transform={"target_strongest": True}),
        "pilar_sagrado": P("Pilar Fixo", "O Pilar fica de pe por 8 s ferindo quem chega perto.",
                           transform={"mechanic": "field", "duration": 8.0, "tick_interval": 0.8, "radius": 140},
                           transform_from={"power": ["power", 0.3]}),
        # Venenos (decisao 586)
        "esporos": P("Cogumelos", "Hospedeiro dos Esporos que morre vira um cogumelo que reinfecta quem passa por perto por 10 s.",
                     T("kill", A("cast", gem="poca_de_veneno", at="target", power=0.0, override={"poison_type": "esporo", "duration": 10.0, "radius": 90}), poisoned=True, **own("esporos"))),
        "poca_de_veneno": P("Poca Viva", "A Poca de Veneno acompanha a personagem.",
                            transform={"field_follows_player": True, "deploy_limit": 1}),
        "trovao_descendente": P("Raio em Cadeia", "O Trovao salta entre ate 5 inimigos proximos.",
                                transform={"mechanic": "chain", "chain_count": 5, "chain_range": 170}),
    }


# ------------------------------------------------------------------ lendarios genericos

def legendary_items():
    lore = {
        "lendario_coroa_de_brasa": "Diadema de cinza viva achado no fundo de uma forja apagada ha geracoes.",
        "lendario_manto_do_inverno": "Pele de geada costurada por quem atravessou um inverno que nunca terminou.",
        "lendario_luvas_da_tempestade": "Luvas de couro queimado que ainda zumbem quando o ceu escurece.",
        "lendario_botas_do_brejo": "Botas cobertas de musgo acido que nunca afundam no lodo.",
        "lendario_veu_do_eclipse": "Tecido escuro que bebe a luz de quem cai perto dele.",
        "lendario_anel_do_sol_partido": "Anel de ouro rachado ao meio; a luz escapa pela fenda.",
        "lendario_anel_da_terra_viva": "Anel de pedra que cresce devagar no dedo de quem o usa.",
        "lendario_lente_arcana": "Lente de cristal que mostra o instante antes de cada acerto.",
        "lendario_punho_da_montanha": "Manoplas de rocha macica que pesam so para quem e golpeado.",
        "lendario_tomo_do_erudito": "Tomo sem fim, escrito por geracoes de conjuradores de Aresta.",
        "lendario_gatilho_ancestral": "Anel de cacador antigo com um gatilho gravado por dentro.",
        "lendario_calca_do_pastor": "Roupa de quem guiava moldes vivos pelas galerias da Torre.",
        "lendario_coracao_imortal": "Frasco com um coracao que ainda bate e se recusa a parar.",
        "lendario_ampulheta_partida": "Ampulheta quebrada cuja areia escorre para cima.",
        "lendario_folego_primordial": "Garrafa com o primeiro sopro de vento que entrou na Torre.",
        "lendario_couraca_do_colosso": "Placa arrancada do peito de um colosso que nunca caiu.",
        "lendario_botas_do_cacador": "Botas leves que aceleram a cada presa abatida.",
        "lendario_presa_da_serpente": "Presa de uma serpente do brejo, ainda pingando veneno.",
        "lendario_botas_do_vendaval": "Botas costuradas com o couro de quem atravessou o Bosque contra o vento.",
        "lendario_anel_da_corda_infinita": "Anel de arqueira cuja corda gravada nunca termina de vibrar.",
        "lendario_anel_do_furor": "Anel trancado que esquenta a cada volta da chuva de flechas.",
        "lendario_sino_do_folego_leve": "Sino de bronze que, ao tocar, faz o ar pesar menos nos pulmoes.",
        "lendario_pacto_de_sangue": "Cranio selado com cera escura; quem o carrega deixa de sarar.",
    }

    def item(identifier, name, slot, item_type, stats, passive, power=50, fixed_affixes=None):
        entry = {"id": identifier, "name": name, "item_type": item_type, "slot": slot, "tier": "legendary",
                 "power": power, "stats": stats, "description": lore[identifier], "passive": passive}
        if fixed_affixes:
            entry["fixed_affixes"] = fixed_affixes
        return entry

    return [
        # Elementos
        item("lendario_coroa_de_brasa", "Coroa de Brasa", "amulet", "accessory",
             {"intelligence": 10, "wisdom": 8, "cooldown_recovery": 5, "area": 7},
             P("Fogo que Nao Apaga", "Queimaduras nao expiram e, quando um inimigo morre em chamas, o fogo passa aos vizinhos. Acertos de fogo incendeiam (60% do golpe por segundo). Gemas de fogo +20%.",
               T("hit", A("burn", ratio=0.6, duration=3.0), element="fire"),
               T("kill", A("spread_burn", radius=130), burning=True),
               mods={"burn_lasting": 1, "power_fire_mult": 1.2})),
        item("lendario_manto_do_inverno", "Manto do Inverno Longo", "armor", "armor",
             {"health": 60, "defense": 20, "vitality": 8},
             P("Inverno Interior", "Acertos de gelo estilhacam inimigos comuns e elites abaixo de 20% da Vida. Gemas de gelo +20%.",
               T("hit", A("execute", below=0.2), element="ice"),
               mods={"power_ice_mult": 1.2})),
        item("lendario_luvas_da_tempestade", "Luvas da Tempestade", "gloves", "armor",
             {"attack_speed": 8, "agility": 10, "intelligence": 8, "critical_chance": 3},
             P("Sobrecarga", "Gemas de raio nao tem recarga, mas custam o dobro de Folego.",
               T("cast", A("refund", scope="trigger", seconds=99), element="lightning"),
               mods={"breath_cost_lightning_mult": 2.0})),
        item("lendario_botas_do_brejo", "Botas do Brejo Antigo", "boots", "armor",
             {"movement_speed": 10, "vitality": 8, "wisdom": 8, "breath": 10},
             P("Raiz e Acido", "Todo acerto de gema de acido ou natureza tambem envenena (toxina com 40% do golpe em 3 s). Gemas de acido e natureza +15%.",
               T("hit", A("poison", ratio=0.4, duration=3.0), element="acid"),
               T("hit", A("poison", ratio=0.4, duration=3.0), element="nature"),
               mods={"power_acid_mult": 1.15, "power_nature_mult": 1.15})),
        item("lendario_veu_do_eclipse", "Veu do Eclipse", "pants", "armor",
             {"health": 40, "intelligence": 10, "fortune": 8, "vitality": 7},
             P("Pacto Sombrio", "Gemas de trevas custam Vida em vez de Folego (0,5% da Vida maxima por ponto de Folego) e causam +60%.",
               mods={"health_cost_dark": 1, "power_dark_mult": 1.6})),
        item("lendario_anel_do_sol_partido", "Anel do Sol Partido", "ring", "accessory",
             {"wisdom": 10, "intelligence": 8, "cooldown_recovery": 5, "health": 28},
             P("Luz Excedente", "Toda cura acima da Vida maxima vira barreira, ate metade da Vida. Gemas sagradas +30%.",
               mods={"overheal_barrier": 1, "power_holy_mult": 1.3})),
        item("lendario_anel_da_terra_viva", "Anel da Terra Viva", "ring", "accessory",
             {"strength": 10, "vitality": 10, "defense": 25},
             P("Pedra Viva", "Parada por 1 s, voce recebe 40% menos dano. Gemas de terra +20%.",
               mods={"still_damage_reduction": 0.4, "power_earth_mult": 1.2})),
        item("lendario_lente_arcana", "Lente Arcana", "offhand", "offhand",
             {"intelligence": 10, "critical_chance": 5, "area": 8, "wisdom": 7},
             P("Clarividencia", "Voce nunca critica por chance: todo 5o acerto direto de gema e critico com +200%.",
               mods={"crit_cadence": 5})),
        # Tipo de dano
        item("lendario_punho_da_montanha", "Punho da Montanha", "gloves", "armor",
             {"strength": 12, "agility": 8, "attack_speed": 6, "critical_chance": 3},
             P("Peso da Montanha", "Voce fica 25% mais lenta, mas cada ponto de Forca da +1% de dano as gemas fisicas e ao autoataque fisico.",
               mods={"move_speed_mult": 0.75, "strength_physical_conversion": 0.01})),
        item("lendario_tomo_do_erudito", "Tomo do Erudito", "offhand", "offhand",
             {"intelligence": 12, "wisdom": 12, "breath": 20, "area": 2},
             P("Erudicao Absoluta", "Todas as gemas custam Vida em vez de Folego (0,5% da Vida maxima por ponto de Folego). Vida maxima +30%.",
               mods={"health_cost_all": 1, "max_health_mult": 1.3})),
        # Autoataque
        item("lendario_gatilho_ancestral", "Gatilho Ancestral", "ring", "accessory",
             {"agility": 12, "attack_speed": 8, "critical_chance": 3, "strength": 5},
             P("Gatilho Ancestral", "O autoataque passa a lancar a gema do Q a cada acerto, com 40% da potencia; a gema do Q nao pode mais ser lancada a mao.",
               T("hit", A("cast", slot=0, at="target", power=0.4), source="auto"),
               mods={"slot_locked_q": 1})),
        # Invocacoes
        item("lendario_calca_do_pastor", "Calca do Pastor de Moldes", "pants", "armor",
             {"wisdom": 12, "intelligence": 10, "health": 52},
             P("Rebanho Eterno", "Invocacoes nao expiram (ate sair do andar), mas sua Vida maxima cai 25%.",
               mods={"summon_duration_mult": 100.0, "max_health_mult": 0.75})),
        # Sobrevivencia e ritmo
        item("lendario_coracao_imortal", "Coracao Imortal", "relic", "relic",
             {"health": 80, "vitality": 15},
             P("Recusa da Morte", "Golpe fatal nao derruba: volta com 60% da Vida, 3 s de invulnerabilidade e uma explosao sagrada (uma vez a cada 90 s).",
               T("lethal", A("revive", ratio=0.6, invulnerable=3.0), A("burst", at="self", radius=160, power=60, element="holy"), cooldown=90.0))),
        item("lendario_ampulheta_partida", "Ampulheta Partida", "relic", "relic",
             {"cooldown_recovery": 8, "wisdom": 10, "intelligence": 9},
             P("Tempo Roubado", "As recargas nao andam com o tempo: cada abate adianta 1 s de todas as gemas.",
               T("kill", A("refund", scope="all", seconds=1.0)),
               mods={"cooldown_kill_only": 1})),
        item("lendario_folego_primordial", "Folego Primordial", "amulet", "accessory",
             {"breath": 40, "vitality": 8, "agility": 7},
             P("Pulmao do Mundo", "Andando, as gemas nao custam Folego; parada, custam o dobro.",
               mods={"moving_free_cast": 1})),
        item("lendario_couraca_do_colosso", "Couraca do Colosso", "armor", "armor",
             {"health": 80, "defense": 25},
             P("Colosso", "Voce fica 30% mais lenta, mas e imune ao dano de contato dos inimigos (projeteis e habilidades ainda acertam).",
               mods={"move_speed_mult": 0.7, "contact_immunity": 1})),
        # Venenos (decisao 586)
        item("lendario_presa_da_serpente", "Presa da Serpente", "amulet", "accessory",
             {"intelligence": 10, "vitality": 8, "wisdom": 7, "area": 6, "health": 16},
             P("Mordida Final", "Inimigo envenenado (qualquer veneno) que morre explode com 20% da propria Vida maxima em volta e deixa uma Poca de Veneno: com todas as melhorias se a gema estiver equipada; senao, de nivel 1. Toda Presa traz alcance de proliferacao de veneno de +30% a +100%, que amplia a explosao, a poca e o espalhamento dos esporos.",
               T("kill", A("burst", at="victim", radius=110, victim_health_ratio=0.2, element="acid", spread_scaled=True),
                 A("cast", gem="poca_de_veneno", use_slot=True, at="target", power=1.0, spread_scaled=True), poisoned=True)),
             fixed_affixes=[{"id": "proliferacao", "min": 0.3, "max": 1.0}]),
        item("lendario_botas_do_cacador", "Botas do Cacador", "boots", "armor",
             {"movement_speed": 12, "agility": 10, "strength": 7},
             P("Rastro de Caca", "Enquanto anda, a cada 0,4 s voce deixa um rastro que fere quem esta perto (escala com o nivel).",
               T("interval", A("burst", at="self", radius=70, power=10), seconds=0.4, moving=True))),
        # Pedidos de 2026-10-08 (decisao 596)
        item("lendario_botas_do_vendaval", "Botas do Vendaval", "boots", "armor",
             {"movement_speed": 25, "agility": 12, "vitality": 6},
             P("Passo de Vendaval", "Velocidade de movimento +60%.",
               mods={"move_speed_mult": 1.6})),
        item("lendario_anel_da_corda_infinita", "Anel da Corda Infinita", "ring", "accessory",
             {"agility": 12, "intelligence": 11, "cooldown_recovery": 6},
             P("Rajada Sem Fim", "Cada volta completa da Saraivada de Flechas lanca de graca a gema do W no inimigo mais proximo, ignorando a recarga e o Folego.",
               T("volley", A("cast", slot=1, at="nearest", power=1.0)))),
        item("lendario_anel_do_furor", "Anel do Furor", "ring", "accessory",
             {"agility": 12, "vitality": 12, "strength": 11},
             P("Furor do Arqueiro", "Cada volta completa da Saraivada de Flechas da 1 acumulo por 10 s (ganhar outro renova todos): +2% de velocidade, +4% de dano e -1,5% de dano recebido por acumulo, ate 25 (+50%, +100% e -37,5%).",
               T("volley", A("buff", id="furor_do_arqueiro", mods={"move_speed_mult": 1.02, "power_mult": 1.04, "damage_taken_mult": 0.985}, duration=10.0, stacks=25)))),
        item("lendario_sino_do_folego_leve", "Sino do Folego Leve", "relic", "relic",
             {"breath": 30, "wisdom": 12, "vitality": 8},
             P("Ar Leve", "Todas as gemas custam 50% menos Folego, inclusive o custo por segundo da Saraivada de Flechas.",
               mods={"breath_cost_mult": 0.5})),
        # Revisao revolucionaria (decisao 598)
        item("lendario_pacto_de_sangue", "Pacto de Sangue", "relic", "relic",
             {"vitality": 15, "health": 60, "strength": 8},
             P("Pacto de Sangue", "Nenhuma cura funciona em voce (nem suprimentos); todo abate da barreira de 3% da Vida maxima.",
               T("kill", A("barrier", ratio=0.03, duration=6.0)),
               mods={"no_healing": 1})),
    ]


# O Lastro Partido ja existia como reliquia lendaria; ganha a passiva no lugar do efeito pendente.
LASTRO_PARTIDO = P("Peso Vetorial", "Toda gema de movimento abre uma Prisao Gravitica no ponto de chegada com 120% da potencia. Velocidade +10%.",
                   T("cast", A("cast", gem="prisao_gravitica", at="self", power=1.2), mechanic="dash"),
                   mods={"move_speed_mult": 1.1})
