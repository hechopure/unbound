# Unbound DNS - Personal Config

[![GitHub](https://img.shields.io/badge/GitHub-hechopure%2Funbound-blue?logo=github)](https://github.com/hechopure/unbound)
[![Docker Pulls](https://img.shields.io/docker/pulls/hechopure/unbound)](https://hub.docker.com/r/hechopure/unbound)
[![License](https://img.shields.io/github/license/hechopure/unbound)](https://github.com/hechopure/unbound/blob/main/LICENSE)

Resolver DNS de reenvío (forwarder) hacia Quad9 mediante DNS-over-TLS.
Diseñado para colocarse detrás de Pi-hole.

**Código fuente y documentación completa:**
https://github.com/hechopure/unbound

## Arquitectura

    Clientes LAN
         |
         v
    Pi-hole (dnsmasq)          <- bloqueo de anuncios, DNS local, query log
         |
         v
    Unbound (este contenedor)  <- caché, DoT, filtrado de direcciones privadas
         |
         v  DNS-over-TLS :853
    Quad9 (9.9.9.9)            <- validación DNSSEC, bloqueo de malware

## Quick Start

    docker run -d --name unbound \
      --restart unless-stopped \
      --read-only \
      --security-opt no-new-privileges \
      --cap-drop ALL \
      --memory 400m \
      -p 5353:5353/tcp -p 5353:5353/udp \
      hechopure/unbound:latest

## Con Pi-hole

1. Correr este contenedor
2. Pi-hole → Settings → DNS → Custom DNS servers
3. Agregar: `IP_DE_UNBOUND#5353`
4. Desmarcar cualquier upstream público que esté seleccionado
5. **Desmarcar "Use DNSSEC"** en la sección DNSSEC

El punto 5 es importante: la validación la hace Quad9, y el tramo
unbound-Quad9 va cifrado con DoT. Activar la validación en Pi-hole
agrega un segundo validador que puede discrepar del primero y producir
SERVFAIL esporádicos.

## Notas sobre la configuración

- **Puerto 5353**, no 53. Permite correr como usuario sin privilegios.
- **`access-control` cerrado.** Solo se permite consultar desde `127.0.0.0/8`,
  `172.16.0.0/12` (bridges de Docker) y `192.168.200.0/24`. Todo lo demás
  recibe REFUSED. **Adaptá las subredes a tu red antes de usar.**
- **`private-address`** filtra respuestas que apunten a rangos RFC1918
  (protección contra DNS rebinding). No afecta a los registros locales
  de Pi-hole, que los responde dnsmasq.
- **`log-queries: yes`** registra cada consulta. Redundante con Pi-hole;
  se puede desactivar.
- **Sin validación DNSSEC local.** Delegada en Quad9.

## Aviso importante

Esta imagen **no es un open resolver**. La configuración usa
`access-control: 0.0.0.0/0 refuse` como regla final, por lo que rechaza
consultas de cualquier origen no listado explícitamente.

Antes de usarla, editá `unbound.conf` y ajustá `access-control` a tu
subred real. Si tu LAN no es `192.168.200.0/24`, esa regla no te sirve.

Si necesitás exponer el resolver fuera de tu LAN, no lo hagas agregando
`0.0.0.0/0 allow` — eso convierte el contenedor en un amplificador DDoS.
Usá reglas específicas por subred.

## Actualización

    docker pull hechopure/unbound:latest
    docker rm -f unbound
    docker run -d --name unbound \
      --restart unless-stopped \
      --read-only \
      --security-opt no-new-privileges \
      --cap-drop ALL \
      --memory 400m \
      -p 5353:5353/tcp -p 5353:5353/udp \
      hechopure/unbound:latest

Reconstruir mensualmente para incorporar parches de seguridad de Debian.
El Dockerfile no ejecuta `apt-get upgrade`.

