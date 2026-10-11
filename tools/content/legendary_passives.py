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
        "saraivada_de_flechas": P("Tempestade Triplice", "Flecha que abate vira um raio no corpo: 250% do golpe em area e 1 de Folego.",
                                  T("kill", A("burst", at="victim", radius=80, ratio=2.5, element="lightning"), A("breath", amount=1), **own("saraivada_de_flechas"))),
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
        "sentinela_ferral": P("Matilha", "Uma Sentinela extra se ergue sozinha a cada 10 s; abates das sentinelas devolvem 2 de Folego.",
                              T("interval", A("cast", gem="sentinela_ferral", at="nearest", power=1.0), seconds=10.0),
                              T("kill", A("breath", amount=2), **own("sentinela_ferral"))),
        "enxame_luminar": P("Enxame Faminto", "Cada abate do Enxame gera um enxame novo no lugar (no maximo um por segundo).",
                            T("kill", A("cast", gem="enxame_luminar", at="target", power=0.6), cooldown=1.0, **own("enxame_luminar"))),
        "guardiao_de_lastro": P("Guardiao Imortal", "Ao ser ferida, um Guardiao surge de graca (uma vez a cada 15 s) com barreira de 20% da Vida.",
                                T("hurt", A("cast", gem="guardiao_de_lastro", at="self", power=1.0), A("barrier", ratio=0.2, duration=5.0), cooldown=15.0)),
        # Santuario
        "semeadura_vital": P("Jardim Andante", "O Jardim acompanha a personagem enquanto dura.",
                             transform={"field_follows_player": True}),
        "circulo_de_reparo": P("Circulo Sagrado", "O Circulo cura 20% da Vida e adianta 3 s a recarga de todas as gemas.",
                               T("cast", A("heal", ratio=0.2), A("refund", scope="all", seconds=3.0), **own("circulo_de_reparo"))),
        "abrigo_de_escora": P("Abrigo Inabalavel", "Erguer o Abrigo da 2 s de invulnerabilidade e metade do dano recebido por 6 s.",
                              T("cast", A("invulnerable", seconds=2.0), A("buff", id="abrigo", mods={"damage_taken_mult": 0.5}, duration=6.0), **own("abrigo_de_escora"))),
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
        "satelites_de_geada": P("Orbita Glacial", "Os Satelites congelam (70% por 1,5 s) e, a cada 3 s em combate, pulsam gelo em volta com 100% da potencia da gema.",
                                T("hit", A("freeze", slow=0.7, duration=1.5), **own("satelites_de_geada")),
                                T("interval", A("burst", at="self", radius=130, gem_power=1.0, element="ice"), seconds=3.0)),
        # Mina
        "mina_de_lastro": P("Campo Minado", "Cada Mina vem com mais duas em volta, com potencia total.",
                            T("cast", A("recast", power=1.0, count=2, delay=0.15, scatter=70), **own("mina_de_lastro"))),
        "semente_explosiva": P("Semente Fertil", "Inimigo abatido pela Semente planta outra no lugar com 60% da potencia.",
                               T("kill", A("cast", gem="semente_explosiva", at="target", power=0.6), cooldown=0.4, **own("semente_explosiva"))),
        # Meteoro
        "chuva_ferral": P("Artilharia Ferral", "A Chuva cai sozinha a cada 2 s no inimigo mais proximo.",
                          T("interval", A("cast", gem="chuva_ferral", use_slot=True, at="nearest", power=1.0), seconds=2.0)),
        "cometa_de_vidro": P("Vidro Estilhacado", "Inimigo abatido pelo Cometa estilhaca: 60% do golpe em area e lentidao de 60%.",
                             T("kill", A("burst", at="victim", radius=120, ratio=0.6, element="ice", slow=0.6, slow_duration=2.0), **own("cometa_de_vidro"))),
        "pilar_sagrado": P("Pilar Fixo", "O Pilar fica de pe por 8 s ferindo quem chega perto.",
                           transform={"mechanic": "field", "duration": 8.0, "tick_interval": 0.8, "radius": 140},
                           transform_from={"power": ["power", 0.3]}),
        # Venenos (decisao 586)
        "esporos": P("Colonia Primordial", "Cada lancamento infecta tambem os dois inimigos mais proximos do alvo.",
                     T("cast", A("cast", gem="esporos", at="nearest", count=3, power=1.0), **own("esporos"))),
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
             P("Fogo que Nao Apaga", "Gemas de fogo +40%. Acertos delas incendeiam (60% do golpe em 3 s) e quem morre em chamas explode.",
               T("hit", A("burn", ratio=0.6, duration=3.0), element="fire"),
               T("kill", A("burst", at="victim", radius=100, power=30, element="fire"), burning=True),
               mods={"power_fire_mult": 1.4})),
        item("lendario_manto_do_inverno", "Manto do Inverno Longo", "armor", "armor",
             {"health": 60, "defense": 20, "vitality": 8},
             P("Inverno Interior", "Gemas de gelo +40%; acertos delas congelam (70% por 1,5 s) e expoem o alvo (+20%). Dano recebido -15%.",
               T("hit", A("freeze", slow=0.7, duration=1.5), A("vulnerable", amount=0.2, duration=1.5), element="ice"),
               mods={"power_ice_mult": 1.4, "damage_taken_mult": 0.85})),
        item("lendario_luvas_da_tempestade", "Luvas da Tempestade", "gloves", "armor",
             {"attack_speed": 8, "agility": 10, "intelligence": 8, "critical_chance": 3},
             P("Tempestade nas Maos", "Gemas de raio +40%; metade dos acertos delas ramifica em area com 70% do golpe.",
               T("hit", A("burst", at="victim", radius=90, ratio=0.7, element="lightning"), element="lightning", chance=0.5, cooldown=0.1),
               mods={"power_lightning_mult": 1.4})),
        item("lendario_botas_do_brejo", "Botas do Brejo Antigo", "boots", "armor",
             {"movement_speed": 10, "vitality": 8, "wisdom": 8, "breath": 10},
             P("Raiz e Acido", "Gemas de acido e natureza +35%. Acido deixa o alvo 30% mais vulneravel; natureza cura a cada acerto.",
               T("hit", A("vulnerable", amount=0.3, duration=4.0), element="acid"),
               T("hit", A("heal", ratio=0.008), element="nature", cooldown=0.1),
               mods={"power_acid_mult": 1.35, "power_nature_mult": 1.35})),
        item("lendario_veu_do_eclipse", "Veu do Eclipse", "pants", "armor",
             {"health": 40, "intelligence": 10, "fortune": 8, "vitality": 7},
             P("Fome do Eclipse", "Gemas de trevas +40%; cada abate delas cura 4% da Vida e devolve 3 de Folego.",
               T("kill", A("heal", ratio=0.04), A("breath", amount=3), element="dark"),
               mods={"power_dark_mult": 1.4})),
        item("lendario_anel_do_sol_partido", "Anel do Sol Partido", "ring", "accessory",
             {"wisdom": 10, "intelligence": 8, "cooldown_recovery": 5, "health": 28},
             P("Sol Partido", "Gemas sagradas +40%; lancar uma delas cura 8% da Vida e da 8% em barreira.",
               T("cast", A("heal", ratio=0.08), A("barrier", ratio=0.08, duration=5.0), element="holy"),
               mods={"power_holy_mult": 1.4})),
        item("lendario_anel_da_terra_viva", "Anel da Terra Viva", "ring", "accessory",
             {"strength": 10, "vitality": 10, "defense": 25},
             P("Pedra Viva", "Gemas de terra +40% e dano recebido -10%; lancar uma delas da 12% da Vida em barreira.",
               T("cast", A("barrier", ratio=0.12, duration=5.0), element="earth"),
               mods={"power_earth_mult": 1.4, "damage_taken_mult": 0.9})),
        item("lendario_lente_arcana", "Lente Arcana", "offhand", "offhand",
             {"intelligence": 10, "critical_chance": 5, "area": 8, "wisdom": 7},
             P("Lente Arcana", "Gemas arcanas +40%; todo critico de gema adianta 0,5 s a recarga de todas as gemas.",
               T("hit", A("refund", scope="all", seconds=0.5), source="gem", crit=True, cooldown=0.5),
               mods={"power_arcane_mult": 1.4})),
        # Tipo de dano
        item("lendario_punho_da_montanha", "Punho da Montanha", "gloves", "armor",
             {"strength": 12, "agility": 8, "attack_speed": 6, "critical_chance": 3},
             P("Peso da Montanha", "Gemas fisicas e autoataque +35%; criticos fisicos racham o chao com 100% do golpe em area.",
               T("hit", A("burst", at="victim", radius=80, ratio=1.0, element="earth"), tag="physical", crit=True, cooldown=0.2),
               mods={"power_physical_mult": 1.35, "auto_damage_mult": 1.35})),
        item("lendario_tomo_do_erudito", "Tomo do Erudito", "offhand", "offhand",
             {"intelligence": 12, "wisdom": 12, "breath": 20, "area": 2},
             P("Erudicao Absoluta", "Gemas magicas +30%; cada lancamento magico devolve 4 de Folego.",
               T("cast", A("breath", amount=4), tag="magic"),
               mods={"power_magic_mult": 1.3})),
        # Autoataque
        item("lendario_gatilho_ancestral", "Gatilho Ancestral", "ring", "accessory",
             {"agility": 12, "attack_speed": 8, "critical_chance": 3, "strength": 5},
             P("Gatilho Ancestral", "Autoataque +40% de dano e +15% de cadencia; a cada 4 acertos ele dispara a gema de Q de graca com 60% da potencia.",
               T("hit", A("cast", slot=0, at="target", power=0.6), source="auto", every=4),
               mods={"auto_damage_mult": 1.4, "auto_rate_mult": 1.15})),
        # Invocacoes
        item("lendario_calca_do_pastor", "Calca do Pastor de Moldes", "pants", "armor",
             {"wisdom": 12, "intelligence": 10, "health": 52},
             P("Rebanho Fiel", "Invocacoes +50% de potencia e duram 25% mais; invocar cura 5% da Vida.",
               T("cast", A("heal", ratio=0.05), tag="summon"),
               mods={"power_summon_mult": 1.5, "duration_mult": 1.25})),
        # Sobrevivencia e ritmo
        item("lendario_coracao_imortal", "Coracao Imortal", "relic", "relic",
             {"health": 80, "vitality": 15},
             P("Recusa da Morte", "Golpe fatal nao derruba: volta com 60% da Vida, 3 s de invulnerabilidade e uma explosao sagrada (uma vez a cada 90 s).",
               T("lethal", A("revive", ratio=0.6, invulnerable=3.0), A("burst", at="self", radius=160, power=60, element="holy"), cooldown=90.0))),
        item("lendario_ampulheta_partida", "Ampulheta Partida", "relic", "relic",
             {"cooldown_recovery": 8, "wisdom": 10, "intelligence": 9},
             P("Tempo Roubado", "Cada abate adianta 0,35 s a recarga de todas as gemas. Recargas -10%.",
               T("kill", A("refund", scope="all", seconds=0.35)),
               mods={"cooldown_mult": 0.9})),
        item("lendario_folego_primordial", "Folego Primordial", "amulet", "accessory",
             {"breath": 40, "vitality": 8, "agility": 7},
             P("Pulmao do Mundo", "Folego maximo +40 e regeneracao +60%; cada abate devolve 3 de Folego.",
               T("kill", A("breath", amount=3)),
               mods={"breath_regen_mult": 1.6, "max_breath_add": 40})),
        item("lendario_couraca_do_colosso", "Couraca do Colosso", "armor", "armor",
             {"health": 80, "defense": 25},
             P("Colosso", "Dano recebido -25%; ao ser ferida, ganha barreira de 15% da Vida (a cada 6 s).",
               T("hurt", A("barrier", ratio=0.15, duration=5.0), cooldown=6.0),
               mods={"damage_taken_mult": 0.75})),
        # Venenos (decisao 586)
        item("lendario_presa_da_serpente", "Presa da Serpente", "amulet", "accessory",
             {"intelligence": 10, "vitality": 8, "wisdom": 7, "area": 6, "health": 16},
             P("Mordida Final", "Inimigo envenenado (qualquer veneno) que morre explode com 20% da propria Vida maxima em volta e deixa uma Poca de Veneno: com todas as melhorias se a gema estiver equipada; senao, de nivel 1. Toda Presa traz alcance de proliferacao de veneno de +30% a +100%, que amplia a explosao, a poca e o espalhamento dos esporos.",
               T("kill", A("burst", at="victim", radius=110, victim_health_ratio=0.2, element="acid", spread_scaled=True),
                 A("cast", gem="poca_de_veneno", use_slot=True, at="target", power=1.0, spread_scaled=True), poisoned=True)),
             fixed_affixes=[{"id": "proliferacao", "min": 0.3, "max": 1.0}]),
        item("lendario_botas_do_cacador", "Botas do Cacador", "boots", "armor",
             {"movement_speed": 12, "agility": 10, "strength": 7},
             P("Frenesi da Caca", "Cada abate da +8% de potencia e +4% de velocidade por 6 s, acumulando ate 6 vezes.",
               T("kill", A("buff", id="frenesi", mods={"power_mult": 1.08, "move_speed_mult": 1.04}, duration=6.0, stacks=6)))),
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
    ]


# O Lastro Partido ja existia como reliquia lendaria; ganha a passiva no lugar do efeito pendente.
LASTRO_PARTIDO = P("Peso Vetorial", "Toda gema de movimento abre uma Prisao Gravitica no ponto de chegada com 120% da potencia. Velocidade +10%.",
                   T("cast", A("cast", gem="prisao_gravitica", at="self", power=1.2), mechanic="dash"),
                   mods={"move_speed_mult": 1.1})
