FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        unbound \
        ca-certificates \
        tini \
    && rm -rf /var/lib/apt/lists/*

COPY unbound.conf /etc/unbound/unbound.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh && \
    chown unbound:unbound /etc/unbound/unbound.conf && \
    unbound-checkconf /etc/unbound/unbound.conf

USER unbound

EXPOSE 5353/tcp 5353/udp

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD bash -c 'exec 3<>"/dev/tcp/127.0.0.1/5353"' || exit 1

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
