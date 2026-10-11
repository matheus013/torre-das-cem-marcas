#!/bin/sh
set -eu
exec sh tests/narrative_online_smoke.sh "${1:-17995}" cicatrization
