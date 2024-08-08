FROM infinispan/server:15.0.7.Final

COPY --chown=185:0 config/infinispan/infinispan.xml /opt/infinispan/server/conf/infinispan.xml
COPY --chown=185:0 infinispan-server-libs /opt/infinispan/server/lib

USER root
RUN mkdir -p /opt/infinispan/server/data \
    && chown -R 185:0 /opt/infinispan/server/data \
    && chmod -R g+w /opt/infinispan/server/data
USER 185

VOLUME /opt/infinispan/server/data
