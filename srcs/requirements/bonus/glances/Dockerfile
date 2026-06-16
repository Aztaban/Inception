FROM debian:12

RUN apt update && apt install -y \
    python3 \
    python3-venv \
    python3-pip \
    procps \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/glances \
    && /opt/glances/bin/pip install --no-cache-dir "glances[web]"

COPY tools/init_glances.sh /usr/local/bin/init_glances.sh

RUN chmod +x /usr/local/bin/init_glances.sh

EXPOSE 61208

ENTRYPOINT ["/usr/local/bin/init_glances.sh"]