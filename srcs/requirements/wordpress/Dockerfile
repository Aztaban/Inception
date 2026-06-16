FROM debian:12

RUN apt update && apt install -y \
	php8.2-fpm \
	php8.2-mysql \
	php8.2-curl \
	php8.2-gd \
	php8.2-intl \
	php8.2-mbstring \
	php8.2-soap \
	php8.2-xml \
	php8.2-redis \
	php8.2-zip \
	mariadb-client \
	curl \
	ca-certificates \
	tar \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x wp-cli.phar \
	&& mv wp-cli.phar /usr/local/bin/wp

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/init_wordpress.sh /usr/local/bin/init_wordpress.sh

RUN chmod +x /usr/local/bin/init_wordpress.sh

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/init_wordpress.sh"]