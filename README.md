# Unbound DNS - Personal Config

[![Docker Pulls](https://img.shields.io/docker/pulls/hechopure/unbound)](https://hub.docker.com/r/hechopure/unbound)


DNS forwarding resolver pointing to Quad9 over DNS-over-TLS.
Designed to sit behind Pi-hole.



## Architecture

    LAN Clients
         |
         v
    Pi-hole (dnsmasq)          <- ad blocking, local DNS, query log
         |
         v
    Unbound (this container)   <- cache, DoT, private address filtering
         |
         v  DNS-over-TLS :853
    Quad9 (9.9.9.9)            <- DNSSEC validation, malware blocking

## Quick Start

    docker run -d --name unbound \
      --restart unless-stopped \
      --read-only \
      --security-opt no-new-privileges \
      --cap-drop ALL \
      --memory 400m \
      -p 5353:5353/tcp -p 5353:5353/udp \
      hechopure/unbound:latest

## With Pi-hole

1. Run this container
2. Pi-hole -> Settings -> DNS -> Custom DNS servers
3. Add: `UNBOUND_IP#5353`
4. Untick any public upstream that may be selected
5. **Untick "Use DNSSEC"** in the DNSSEC section

Step 5 matters: validation is performed by Quad9, and the
unbound-to-Quad9 hop is encrypted with DoT. Enabling validation in
Pi-hole adds a second independent validator that can disagree with the
first, producing sporadic SERVFAIL on domains that should resolve fine.

## Configuration notes

- **Port 5353**, not 53. This allows running as an unprivileged user.
- **`access-control` is closed.** Queries are only accepted from
  `127.0.0.0/8`, `172.16.0.0/12` (Docker bridges) and `192.168.200.0/24`.
