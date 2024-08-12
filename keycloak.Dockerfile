FROM registry.access.redhat.com/ubi9 AS ubi-micro-build
RUN mkdir -p /mnt/rootfs
RUN dnf install --installroot /mnt/rootfs curl jq --releasever 9 --setopt install_weak_deps=false --nodocs -y && \
    dnf --installroot /mnt/rootfs clean all && \
    rpm --root /mnt/rootfs -e --nodeps setup

FROM cr.smartbank.uz/dockerhub/keycloak/keycloak:24.0.3

# Enable health and metrics support & configure a database vendor
ENV KC_HEALTH_ENABLED=true KC_METRICS_ENABLED=true KC_DB=postgres

COPY --from=ubi-micro-build /mnt/rootfs /

COPY --chown=keycloak:keycloak config/keycloak/* /opt/keycloak/conf/

RUN /opt/keycloak/bin/kc.sh build --features=scripts,multi-site --cache-config-file=cache-ispn-remote.xml
