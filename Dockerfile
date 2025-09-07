FROM nginx:alpine

# Para json.dumps en el entrypoint (puedes usar python3-minimal en debian)
RUN apk add --no-cache bash python3 gettext

# Copia tu UI (usa tu index.html del frontend que ya tienes)
# Asegúrate de que index.html referencie <script src="config.js"></script>
COPY index.html /usr/share/nginx/html/index.html

# Copiamos la plantilla y el entrypoint
COPY config.tpl.js /usr/share/nginx/html/config.tpl.js
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80
CMD ["/entrypoint.sh"]