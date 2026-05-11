FROM debian:12

RUN apt update && apt install -y \
	vsftpd \
	&& rm -rf /var/lib/apt/lists/*

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/init_ftp.sh /usr/local/bin/init_ftp.sh

RUN chmod +x /usr/local/bin/init_ftp.sh

EXPOSE 21 21100-21110

ENTRYPOINT ["/usr/local/bin/init_ftp.sh"]