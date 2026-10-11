class_name NumberFormat
extends RefCounted

## Números grandes legíveis (épico E1, fase 1; G8.13): na dificuldade 5 Vida e dano chegam a
## bilhões. Abaixo de 10 mil mostra o número inteiro; acima, abrevia com uma casa decimal e vírgula:
## 12,4 mil; 3,2 mi; 1,7 bi; 2,0 tri.

const STEPS := [[1.0e12, "tri"], [1.0e9, "bi"], [1.0e6, "mi"], [1.0e4, "mil"]]


static func short(value: float) -> String:
	if not is_finite(value):
		return "?"
	var magnitude := absf(value)
	for step: Array in STEPS:
		var unit := float(step[0])
		if magnitude >= unit:
			var scaled := value / unit if String(step[1]) != "mil" else value / 1000.0
			var text := ("%.1f" % scaled).replace(".", ",")
			return "%s %s" % [text.trim_suffix(",0"), step[1]]
	return "%d" % roundi(value)
