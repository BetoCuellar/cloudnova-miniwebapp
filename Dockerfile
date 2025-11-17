FROM nginx:alpine

# Copiar config personalizada de Nginx
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Copiar certificados
COPY certs/server.crt /etc/nginx/certs/server.crt
COPY certs/server.key /etc/nginx/certs/server.key

# Copiar código de la app al directorio web
COPY . /usr/share/nginx/html

# Puerto de escucha (Nginx ya escucha 80/443, pero Docker expone 80)
EXPOSE 80 443
