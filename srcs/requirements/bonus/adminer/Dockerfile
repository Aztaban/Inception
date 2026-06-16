FROM debian:12

RUN apt update && apt install -y \
	php8.2-cli \
	php8.2-mysql \
	php8.2-common \
	curl \
	ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/adminer

RUN curl -L https://www.adminer.org/latest.php -o /var/www/adminer/index.php

COPY tools/init_adminer.sh /usr/local/bin/init_adminer.sh

RUN chmod +x /usr/local/bin/init_adminer.sh \
	&& chown -R www-data:www-data /var/www/adminer

WORKDIR /var/www/adminer

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/init_adminer.sh"]