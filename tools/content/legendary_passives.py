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


def P(name, description, *triggers, mods=None):
    passive = {"name": name, "description": description}
    if mods:
        passive["mods"] = mods
    if triggers:
        passive["triggers"] = list(triggers)
    return passive


# ------------------------------------------------------------------ armas unicas (uma por gema)

def unique_passives():
    def own(gem):
        return {"gem": gem}

    return {
        # Projeteis
        "agulha_lastro": P("Agulha Fantasma", "A cada 2 lancamentos, tres agulhas fantasmas partem sozinhas contra os inimigos mais proximos com potencia total.",
                           T("cast", A("cast", gem="agulha_lastro", at="nearest", count=3, power=1.0), every=2, **own("agulha_lastro"))),
        "lanca_ferral": P("Presa Dilacerante", "Acertos da Lanca deixam o alvo vulneravel (+35% de dano recebido por 4 s); abates estouram o corpo em area com 100% do golpe.",
                          T("hit", A("vulnerable", amount=0.35, duration=4.0), **own("lanca_ferral")),
                          T("kill", A("burst", at="victim", radius=90, ratio=1.0, element="earth"), **own("lanca_ferral"))),
        "estilhacos_lunares": P("Lua Cheia", "Criticos dos Estilhacos reduzem 1 s da recarga de todas as gemas e devolvem 3 de Folego. Chance critica +10%.",
                                T("hit", A("refund", scope="all", seconds=1.0), A("breath", amount=3), crit=True, **own("estilhacos_lunares")),
                                mods={"crit_chance_add": 0.10}),
        "orbe_de_ruptura": P("Ruptura Continua", "Todo acerto do Orbe rompe em area: 60% do golpe a ate 110 de distancia.",
                             T("hit", A("burst", at="victim", radius=110, ratio=0.6, element="arcane"), **own("orbe_de_ruptura"))),
        "bola_de_fogo": P("Coracao de Fornalha", "Acertos incendeiam (80% do golpe em 3 s). Inimigo em chamas abatido pela Bola de Fogo explode com 80% da potencia da gema.",
                          T("hit", A("burn", ratio=0.8, duration=3.0), **own("bola_de_fogo")),
                          T("kill", A("burst", at="victim", radius=100, gem_power=0.8, element="fire"), burning=True, **own("bola_de_fogo"))),
        "bolha_corrosiva": P("Acido Voraz", "Acertos corroem (+30% de dano recebido por 5 s); cada abate dispara uma nova bolha contra o inimigo mais proximo.",
                             T("hit", A("vulnerable", amount=0.3, duration=5.0), **own("bolha_corrosiva")),
                             T("kill", A("cast", gem="bolha_corrosiva", at="nearest", power=0.7), cooldown=0.2, **own("bolha_corrosiva"))),
        "cometa_sombrio": P("Eclipse Faminto", "Abate com o Cometa Sombrio zera a recarga dele e recupera 4% da Vida.",
                            T("kill", A("refund", scope="trigger", seconds=99), A("heal", ratio=0.04), **own("cometa_sombrio"))),
        "esfera_de_gelo": P("Zero Absoluto", "Acertos congelam (lentidao 85% por 2 s; metade em chefes) e deixam o alvo 30% mais vulneravel.",
                            T("hit", A("freeze", slow=0.85, duration=2.0), A("vulnerable", amount=0.3, duration=2.0), **own("esfera_de_gelo"))),
        "disco_de_retorno": P("Disco Insaciavel", "Cada lancamento solta um segundo disco 0,4 s depois com 70% da potencia; acertos devolvem Folego.",
                              T("cast", A("recast", power=0.7, delay=0.4), **own("disco_de_retorno")),
                              T("hit", A("breath", amount=1), cooldown=0.1, **own("disco_de_retorno"))),
        "saraivada_de_flechas": P("Tempestade Triplice", "Flecha que abate vira um raio no corpo: 250% do golpe em area e 1 de Folego.",
                                  T("kill", A("burst", at="victim", radius=80, ratio=2.5, element="lightning"), A("breath", amount=1), **own("saraivada_de_flechas"))),
        # Dash
        "passo_vetorial": P("Passo Alem", "Depois do Passo, todas as gemas ganham +50% de potencia por 4 s e as outras recargas andam 1,5 s.",
                            T("cast", A("buff", id="passo_alem", mods={"power_mult": 1.5}, duration=4.0), A("refund", scope="all", seconds=1.5), **own("passo_vetorial"))),
        "corte_vetorial": P("Gume do Horizonte", "Ao chegar, o Corte explode em volta com 150% da potencia da gema e deixa os atingidos vulneraveis.",
                            T("cast", A("burst", at="self", radius=130, gem_power=1.5, element="arcane", vulnerable=0.3, vulnerable_duration=3.0), **own("corte_vetorial"))),
        "salto_de_guarda": P("Asa Inquebravel", "O Salto da 1,2 s de invulnerabilidade, barreira de 25% da Vida e cura 8%.",
                             T("cast", A("invulnerable", seconds=1.2), A("barrier", ratio=0.25, duration=6.0), A("heal", ratio=0.08), **own("salto_de_guarda"))),
        # Nova
        "pulso_cicatriz": P("Cicatriz Viva", "Cada inimigo atingido pelo Pulso cura 2% da Vida; abates com ele reduzem 0,8 s da recarga.",
                            T("hit", A("heal", ratio=0.02), cooldown=0.04, **own("pulso_cicatriz")),
                            T("kill", A("refund", scope="trigger", seconds=0.8), **own("pulso_cicatriz"))),
        "anel_de_geada": P("Inverno Eterno", "O Anel congela (lentidao 90% por 2,5 s; metade em chefes) e deixa os atingidos 40% mais vulneraveis.",
                           T("hit", A("freeze", slow=0.9, duration=2.5), A("vulnerable", amount=0.4, duration=2.5), **own("anel_de_geada"))),
        "ruptura_sismica": P("Falha Viva", "Cada Ruptura gera dois tremores seguidos com 60% da potencia.",
                             T("cast", A("recast", power=0.6, count=2, delay=0.45), **own("ruptura_sismica"))),
        # Campo
        "prisao_gravitica": P("Singularidade", "Inimigo abatido pela Prisao colapsa: 200% da potencia da gema em area.",
                              T("kill", A("burst", at="victim", radius=120, gem_power=2.0, element="dark"), **own("prisao_gravitica"))),
        "brasa_persistente": P("Brasa Eterna", "Os pulsos da Brasa incendeiam com o dobro do golpe em 4 s. Gemas de fogo +15%.",
                               T("hit", A("burn", ratio=2.0, duration=4.0), **own("brasa_persistente")),
                               mods={"power_fire_mult": 1.15}),
        "pantano_acido": P("Pantano Vivo", "Quem pisa no Pantano fica 40% mais vulneravel e 40% mais lento.",
                           T("hit", A("vulnerable", amount=0.4, duration=1.5), A("freeze", slow=0.4, duration=1.5), **own("pantano_acido"))),
        "raizes_presas": P("Raiz Mestra", "As Raizes prendem de vez (lentidao 95% por 1 s) e cada pulso cura 1% da Vida.",
                           T("hit", A("freeze", slow=0.95, duration=1.0), A("heal", ratio=0.01), cooldown=0.15, **own("raizes_presas"))),
        # Barreira
        "muralha_refeita": P("Muralha Viva", "Erguer a Muralha da +40% de potencia e -30% de dano recebido por 6 s.",
                             T("cast", A("buff", id="muralha_viva", mods={"power_mult": 1.4, "damage_taken_mult": 0.7}, duration=6.0), **own("muralha_refeita"))),
        "casca_reativa": P("Casca Espelhada", "Todo golpe recebido volta em area com 400% do dano. Dano recebido -15%.",
                           T("hurt", A("burst", at="self", radius=140, ratio=4.0, element="earth"), cooldown=0.4),
                           mods={"damage_taken_mult": 0.85}),
        # Corrente
        "elo_residual": P("Elo Infinito", "Inimigo abatido pelo Elo dispara um novo Elo contra o inimigo mais proximo com 80% da potencia.",
                          T("kill", A("cast", gem="elo_residual", at="nearest", power=0.8), cooldown=0.2, **own("elo_residual"))),
        "arco_voltaico": P("Bobina Sobrecarregada", "Cada salto do Arco reduz 0,25 s da recarga dele; criticos descarregam 150% do golpe em area.",
                           T("hit", A("refund", scope="trigger", seconds=0.25), **own("arco_voltaico")),
                           T("hit", A("burst", at="victim", radius=90, ratio=1.5, element="lightning"), crit=True, **own("arco_voltaico"))),
        "dreno_em_rede": P("Rede Faminta", "Cada alvo drenado cura 2% da Vida e soma 2% em barreira.",
                           T("hit", A("heal", ratio=0.02), A("barrier", ratio=0.02, duration=4.0), cooldown=0.05, **own("dreno_em_rede"))),
        # Invocacao
        "molde_vigilante": P("Matriz Viva", "Um Molde novo surge sozinho a cada 8 s ao lado do inimigo mais proximo.",
                             T("interval", A("cast", gem="molde_vigilante", at="nearest", power=1.0), seconds=8.0)),
        "sentinela_ferral": P("Matilha", "Uma Sentinela extra se ergue sozinha a cada 10 s; abates das sentinelas devolvem 2 de Folego.",
                              T("interval", A("cast", gem="sentinela_ferral", at="nearest", power=1.0), seconds=10.0),
                              T("kill", A("breath", amount=2), **own("sentinela_ferral"))),
        "enxame_luminar": P("Enxame Solar", "Um enxame extra a cada 9 s; cada ferroada cura 1% da Vida.",
                            T("interval", A("cast", gem="enxame_luminar", at="nearest", power=1.0), seconds=9.0),
                            T("hit", A("heal", ratio=0.01), cooldown=0.1, **own("enxame_luminar"))),
        "guardiao_de_lastro": P("Guardiao Imortal", "Ao ser ferida, um Guardiao surge de graca (uma vez a cada 15 s) com barreira de 20% da Vida.",
                                T("hurt", A("cast", gem="guardiao_de_lastro", at="self", power=1.0), A("barrier", ratio=0.2, duration=5.0), cooldown=15.0)),
        # Santuario
        "semeadura_vital": P("Jardim Eterno", "Semear cura 15% da Vida e da 15% em barreira; a cada 6 s em combate o jardim cura mais 4%.",
                             T("cast", A("heal", ratio=0.15), A("barrier", ratio=0.15, duration=6.0), **own("semeadura_vital")),
                             T("interval", A("heal", ratio=0.04), seconds=6.0)),
        "circulo_de_reparo": P("Circulo Sagrado", "O Circulo cura 20% da Vida e adianta 3 s a recarga de todas as gemas.",
                               T("cast", A("heal", ratio=0.2), A("refund", scope="all", seconds=3.0), **own("circulo_de_reparo"))),
        "abrigo_de_escora": P("Abrigo Inabalavel", "Erguer o Abrigo da 2 s de invulnerabilidade e metade do dano recebido por 6 s.",
                              T("cast", A("invulnerable", seconds=2.0), A("buff", id="abrigo", mods={"damage_taken_mult": 0.5}, duration=6.0), **own("abrigo_de_escora"))),
        # Cone
        "ceifa_ampla": P("Grande Ceifa", "Cada abate da Ceifa reduz 0,6 s da recarga dela e cura 1,5% da Vida.",
                         T("kill", A("refund", scope="trigger", seconds=0.6), A("heal", ratio=0.015), **own("ceifa_ampla"))),
        "sopro_criogenico": P("Folego do Inverno", "O Sopro congela (lentidao 80% por 2 s) e cada alvo devolve 1 de Folego.",
                              T("hit", A("freeze", slow=0.8, duration=2.0), A("breath", amount=1), **own("sopro_criogenico"))),
        # Feixe
        "raio_prismatico": P("Prisma Solar", "O Raio deixa o alvo 25% mais vulneravel; criticos explodem em luz com 80% da potencia da gema.",
                             T("hit", A("vulnerable", amount=0.25, duration=3.0), **own("raio_prismatico")),
                             T("hit", A("burst", at="victim", radius=100, gem_power=0.8, element="holy"), crit=True, cooldown=0.2, **own("raio_prismatico"))),
        "fio_desintegrador": P("Desintegracao", "O Fio executa inimigos comuns e elites abaixo de 30% da Vida.",
                               T("hit", A("execute", below=0.3), **own("fio_desintegrador"))),
        # Orbita
        "laminas_orbitais": P("Ciclone de Laminas", "Cada corte das Laminas cura 0,6% da Vida e devolve Folego. Velocidade de movimento +15%.",
                              T("hit", A("heal", ratio=0.006), A("breath", amount=0.5), cooldown=0.1, **own("laminas_orbitais")),
                              mods={"move_speed_mult": 1.15}),
        "satelites_de_geada": P("Orbita Glacial", "Os Satelites congelam (70% por 1,5 s) e, a cada 3 s em combate, pulsam gelo em volta com 100% da potencia da gema.",
                                T("hit", A("freeze", slow=0.7, duration=1.5), **own("satelites_de_geada")),
                                T("interval", A("burst", at="self", radius=130, gem_power=1.0, element="ice"), seconds=3.0)),
        # Mina
        "mina_de_lastro": P("Campo Minado", "Cada Mina vem com mais duas em volta, com potencia total.",
                            T("cast", A("recast", power=1.0, count=2, delay=0.15, scatter=70), **own("mina_de_lastro"))),
        "semente_explosiva": P("Semente Fertil", "Inimigo abatido pela Semente planta outra no lugar com 60% da potencia.",
                               T("kill", A("cast", gem="semente_explosiva", at="target", power=0.6), cooldown=0.4, **own("semente_explosiva"))),
        # Meteoro
        "chuva_ferral": P("Diluvio Ferral", "Cada Chuva traz uma segunda onda 1 s depois com 80% da potencia.",
                          T("cast", A("recast", power=0.8, delay=1.0), **own("chuva_ferral"))),
        "cometa_de_vidro": P("Vidro Estilhacado", "Inimigo abatido pelo Cometa estilhaca: 60% do golpe em area e lentidao de 60%.",
                             T("kill", A("burst", at="victim", radius=120, ratio=0.6, element="ice", slow=0.6, slow_duration=2.0), **own("cometa_de_vidro"))),
        "pilar_sagrado": P("Pilar Eterno", "Erguer o Pilar cura 10% da Vida e da 10% em barreira; quem e atingido fica 30% mais vulneravel.",
                           T("cast", A("heal", ratio=0.1), A("barrier", ratio=0.1, duration=5.0), **own("pilar_sagrado")),
                           T("hit", A("vulnerable", amount=0.3, duration=3.0), **own("pilar_sagrado"))),
        # Venenos (decisao 586)
        "esporos": P("Colonia Primordial", "Cada lancamento infecta tambem os dois inimigos mais proximos do alvo.",
                     T("cast", A("cast", gem="esporos", at="nearest", count=3, power=1.0), **own("esporos"))),
        "poca_de_veneno": P("Lodo Gemeo", "Cada Poca de Veneno abre uma segunda poca ao lado com 70% da potencia.",
                            T("cast", A("recast", power=0.7, scatter=110), **own("poca_de_veneno"))),
        "trovao_descendente": P("Ceu Partido", "Cada raio tem 40% de chance de ramificar no alvo: 60% do golpe em area.",
                                T("hit", A("burst", at="victim", radius=90, ratio=0.6, element="lightning"), chance=0.4, **own("trovao_descendente"))),
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
