#!/usr/bin/env sh
set -eu

# Valores por defecto (seguro dejar todo vacío si no se pasan)
: "${TITLE:=Treasure Hunt}"
: "${STUDENT:=student}"
: "${SALT:=}"
: "${KEY_HASH:=}"
: "${CLUE:=No clue configured.}"
: "${REDIRECT_TO:=}"

# Convertir CLUE a JSON seguro (preserva comillas y saltos de línea)
CLUE_JSON=$(printf '%s' "$CLUE" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')

# Renderizar plantilla -> config.js
export TITLE STUDENT SALT KEY_HASH CLUE_JSON REDIRECT_TO
envsubst '${TITLE} ${STUDENT} ${SALT} ${KEY_HASH} ${CLUE_JSON} ${REDIRECT_TO}' \
  < /usr/share/nginx/html/config.tpl.js \
  > /usr/share/nginx/html/config.js

# Arrancar Nginx en primer plano
exec nginx -g 'daemon off;'
