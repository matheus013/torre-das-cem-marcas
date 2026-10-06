#!/bin/sh
set -eu

# Copia/converte os assets listados em third_party_assets.tsv a partir de assets/new.
# Requer bsdtar (zip e rar) e ffmpeg. Uso: sh tools/art/import_third_party.sh

cd "$(dirname "$0")/../.." || exit 1
source_root="assets/new"
tab="$(printf '\t')"
count=0
work="$(mktemp -d -t aresta-assets.XXXXXX)"
trap 'rm -rf "$work"' EXIT INT TERM

# Extrai a origem para um arquivo temporário; "pacote::membro" lê de dentro de zip/rar.
fetch() {
	case "$1" in
		*::*) bsdtar -xOf "$source_root/${1%%::*}" "${1#*::}" > "$2" ;;
		*) cp "$source_root/$1" "$2" ;;
	esac
}

# PNG com transparência preservada; filtro vazio só copia.
image() {
	if [ -z "$3" ]; then
		cp "$1" "$2"
	else
		ffmpeg -nostdin -hide_banner -loglevel error -y -i "$1" -vf "$3" -pix_fmt rgba -frames:v 1 "$2"
	fi
}

while IFS="$tab" read -r kind dest origin filter; do
	case "$kind" in ''|'#'*) continue ;; esac
	source="$work/source"
	fetch "$origin" "$source"
	case "$kind" in
		vfx)
			mkdir -p assets/sprites/vfx/anim
			image "$source" "assets/sprites/vfx/anim/$dest.png" "${filter:-}"
			;;
		icon)
			image "$source" "assets/sprites/icons/$dest.png" "${filter:-}"
			;;
		item)
			mkdir -p assets/sprites/items
			image "$source" "assets/sprites/items/$dest.png" "${filter:-}"
			;;
		sfx)
			mkdir -p assets/audio/sfx
			# Invertido, o fim vira o inicio: corta o silencio e aplica um fade-in
			# que, desinvertido, encerra o som sem estalo no ponto de corte.
			ffmpeg -nostdin -hide_banner -loglevel error -y -i "$source" \
				-af "areverse,silenceremove=start_periods=1:start_threshold=-55dB,afade=t=in:d=0.03,areverse" \
				-ac 1 -ar 44100 -c:a pcm_s16le "assets/audio/sfx/$dest.wav"
			;;
		*)
			printf 'Tipo desconhecido: %s\n' "$kind" >&2
			exit 1
			;;
	esac
	count=$((count + 1))
done < tools/art/third_party_assets.tsv

printf 'THIRD_PARTY_IMPORTED: %d\n' "$count"
