FROM debian:12

RUN apt update && apt install -y \
    glances \
    python3-bottle \
    && rm -rf /var/lib/apt/lists/*

COPY tools/init_glances.sh /usr/local/bin/init_glances.sh

RUN chmod +x /usr/local/bin/init_glances.sh

EXPOSE 61208

ENTRYPOINT ["/usr/local/bin/init_glances.sh"]
