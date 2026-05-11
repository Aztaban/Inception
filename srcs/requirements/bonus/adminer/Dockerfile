FROM debian:12

RUN apt upgdate && apt install -y \
	php8.2-cli \
	php8.2-mysql \
	php8.2-session \
	curl \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/html/adminer

RUN curl -L https://www.adminer.org/latest.php -o /var/www/adminer/index.php

COPY tools/init_adminer.sh /usr/local/bin/init_adminer.sh

WORKDIR /var/www/adminer

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/init_adminer.sh"]