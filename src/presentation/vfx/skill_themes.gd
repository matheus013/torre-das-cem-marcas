class_name SkillThemes
extends RefCounted

## Visual de cada gema pelo seu elemento. Só apresentação: a simulação envia o id da gema
## e aqui se decide projétil, impacto, explosão, ataque do céu, elo, feixe e cor.

## Papéis: projectile (voa até o alvo), impact (acerto), burst (nova/campo/invocação),
## strike (meteoro), link (corrente esticada entre alvos), beam (feixe esticado).
const ELEMENTS := {
	"fire": {"tint": Color("f0873a"), "projectile": "fire_bolt", "impact": "fire_hit", "burst": "fire_blast", "strike": "fire_blast"},
	"ice": {"tint": Color("9fd8ff"), "projectile": "ice_ball", "impact": "ice_burst", "burst": "ice_burst", "strike": "ice_burst"},
	"lightning": {"tint": Color("e8e070"), "projectile": "energy_ball", "impact": "energy_hit", "burst": "energy_hit", "strike": "thunder_strike", "link": "lightning_link"},
	"acid": {"tint": Color("8fe05a"), "projectile": "acid_bolt", "impact": "acid_hit", "burst": "acid_hit", "strike": "acid_hit"},
	"dark": {"tint": Color("b05ad9"), "projectile": "dark_bolt", "impact": "dark_hit", "burst": "dark_rise", "strike": "dark_rise", "beam": "light_beam"},
	"holy": {"tint": Color("f2d16a"), "projectile": "holy_bolt", "impact": "holy_hit", "burst": "holy_pillar", "strike": "holy_pillar", "beam": "light_beam"},
	"nature": {"tint": Color("8bc25a"), "projectile": "wood_bolt", "impact": "wood_hit", "burst": "wood_roots", "strike": "wood_roots"},
	"earth": {"tint": Color("c08a5a"), "impact": "earth_bump", "burst": "earth_bump", "strike": "earth_bump"},
	"arcane": {"tint": Color("7fb0ff"), "projectile": "energy_ball", "impact": "energy_hit", "burst": "energy_hit", "strike": "energy_hit", "beam": "light_beam"},
}

## Gemas físicas (agulha, lança, disco, cortes, passos, lâminas) não têm elemento e
## mantêm o visual neutro.
const GEMS := {
	"pulso_cicatriz": "dark", "prisao_gravitica": "dark", "dreno_em_rede": "dark", "fio_desintegrador": "dark", "cometa_sombrio": "dark",
	"brasa_persistente": "fire", "mina_de_lastro": "fire", "semente_explosiva": "fire", "chuva_ferral": "fire", "bola_de_fogo": "fire",
	"anel_de_geada": "ice", "sopro_criogenico": "ice", "satelites_de_geada": "ice", "cometa_de_vidro": "ice", "esfera_de_gelo": "ice",
	"elo_residual": "lightning", "arco_voltaico": "lightning", "trovao_descendente": "lightning",
	"pantano_acido": "acid", "bolha_corrosiva": "acid",
	"circulo_de_reparo": "holy", "enxame_luminar": "holy", "raio_prismatico": "holy", "pilar_sagrado": "holy",
	"semeadura_vital": "nature", "abrigo_de_escora": "nature", "raizes_presas": "nature",
	"muralha_refeita": "earth", "ruptura_sismica": "earth", "casca_reativa": "earth", "guardiao_de_lastro": "earth", "molde_vigilante": "earth",
	"estilhacos_lunares": "arcane", "orbe_de_ruptura": "arcane", "sentinela_ferral": "arcane",
}


## Linha de cor nas folhas de 9 cores (laranja, magenta, ciano, verde, marrom, branco, malva,
## vermelho, violeta). Gemas sem elemento usam o ciano da interface.
const ROWS := {"fire": 0, "arcane": 1, "ice": 2, "acid": 3, "nature": 3, "earth": 4, "holy": 5, "lightning": 5, "dark": 8}
const NEUTRAL_ROW := 2

const SKILL_ROLES := {
	"brasa_persistente": {"ground": "sk_flame_field"},
	"pantano_acido": {"ground": "sk_acid_pool"},
	"poca_de_veneno": {"ground": "sk_acid_pool"},
	"prisao_gravitica": {"ground": "sk_gravity_field"},
	"raizes_presas": {"ground": "sk_root_field"},
	"circulo_de_reparo": {"ground": "sk_holy_field"},
	"semeadura_vital": {"ground": "sk_living_field"},
	"abrigo_de_escora": {"ground": "sk_living_field"},
	"laminas_orbitais": {"orbit": "sk_steel_blade"},
	"satelites_de_geada": {"orbit": "sk_ice_crystal"},
	"chuva_ferral": {"telegraph": "sh_comet"},
	"cometa_de_vidro": {"telegraph": "sh_comet"},
}


## Elemento do tema: id de gema, ou "element:<nome>" para efeitos que trocam de elemento (flechas).
static func element_of(theme: String) -> String:
	if theme.begins_with("element:"):
		return theme.trim_prefix("element:")
	return String(GEMS.get(theme, ""))


## Tema da gema, ou vazio quando ela não tem elemento.
static func for_gem(gem_id: String) -> Dictionary:
	var result := (ELEMENTS.get(element_of(gem_id), {}) as Dictionary).duplicate()
	result.merge(SKILL_ROLES.get(gem_id, {}) as Dictionary, true)
	return result


static func row(theme: String) -> int:
	return int(ROWS.get(element_of(theme), NEUTRAL_ROW))


## O raio usa a linha branca tingida de amarelo; os demais usam a cor da própria linha.
static func sheet_tint(theme: String) -> Color:
	return Color("fff07a") if element_of(theme) == "lightning" else Color.WHITE


static func tint(gem_id: String, fallback: Color) -> Color:
	return for_gem(gem_id).get("tint", fallback) as Color
