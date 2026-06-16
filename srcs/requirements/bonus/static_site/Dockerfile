FROM debian:12

RUN apt update && apt install -y \
	nginx \
	&& rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY html/ /var/www/static_site/
COPY tools/init_static_site.sh /usr/local/bin/init_static_site.sh

RUN chmod +x /usr/local/bin/init_static_site.sh \
	&& chown -R www-data:www-data /var/www/static_site

EXPOSE 80

ENTRYPOINT [ "/usr/local/bin/init_static_site.sh" ]
