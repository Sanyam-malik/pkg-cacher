FROM nginx:1.27-alpine

RUN apk add --no-cache bash curl gettext nano

# Remove default config
RUN rm -rf /etc/nginx/conf.d/*

# Copy configs
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY templates/ /etc/nginx/templates/
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

# Cache dir
RUN mkdir -p /var/cache/nginx \
    && chown -R nginx:nginx /var/cache/nginx

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]