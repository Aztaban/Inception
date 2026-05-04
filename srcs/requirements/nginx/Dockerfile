FROM debian:12

RUN apt update && apt install -y \
    nginx \
    openssl \
	gettext-base \
    && rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/nginx.conf.template
COPY tools/init_nginx.sh /usr/local/bin/init_nginx.sh

RUN chmod +x /usr/local/bin/init_nginx.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/init_nginx.sh"]