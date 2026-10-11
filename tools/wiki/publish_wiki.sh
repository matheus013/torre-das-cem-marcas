#!/bin/sh
set -eu

# Regenera a wiki pública e publica no repositório só de documentação (decisão 604):
#   - paginas/ do repositório, com links .md para navegar direto no GitHub;
#   - a wiki do repositório (.wiki.git), com links no formato da wiki.
# Uso: sh tools/wiki/publish_wiki.sh
# A wiki do GitHub só aceita push depois que a primeira página é criada pela web
# (github.com/matheus013/torre-das-cem-marcas-wiki/wiki > Create the first page).

cd "$(dirname "$0")/../.." || exit 1
REPO="https://github.com/matheus013/torre-das-cem-marcas-wiki"
WORK="$(mktemp -d -t aresta-wiki.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT INT TERM

godot --headless --path . --script tools/wiki/build_wiki.gd
REV="$(git rev-parse --short HEAD)"

git clone -q "$REPO.git" "$WORK/repo"
rm -f "$WORK/repo/paginas/"*.md
mkdir -p "$WORK/repo/paginas"
for page in docs/wiki/*.md; do
	# Links da wiki (Pagina e Pagina#ancora) viram Pagina.md no repositório.
	sed -E 's/\]\(([A-Z][A-Za-z-]*)(#[^)]*)?\)/](\1.md\2)/g' "$page" >"$WORK/repo/paginas/$(basename "$page")"
done
git -C "$WORK/repo" add -A paginas
if ! git -C "$WORK/repo" diff --cached --quiet; then
	git -C "$WORK/repo" commit -q -m "docs: paginas regeneradas (jogo $REV)"
	git -C "$WORK/repo" push -q
	echo "paginas/ atualizado"
else
	echo "paginas/ sem mudancas"
fi

if git clone -q "$REPO.wiki.git" "$WORK/wiki" 2>/dev/null; then
	rm -f "$WORK/wiki/"*.md
	cp docs/wiki/*.md "$WORK/wiki/"
	git -C "$WORK/wiki" add -A
	if ! git -C "$WORK/wiki" diff --cached --quiet; then
		git -C "$WORK/wiki" commit -q -m "docs: wiki regenerada (jogo $REV)"
		git -C "$WORK/wiki" push -q
		echo "wiki atualizada"
	else
		echo "wiki sem mudancas"
	fi
else
	echo "A wiki ainda nao existe: crie a primeira pagina em $REPO/wiki e rode de novo." >&2
	exit 2
fi
