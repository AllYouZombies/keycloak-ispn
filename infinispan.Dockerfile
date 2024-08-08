FROM infinispan/server:15.0.7.Final

COPY --chown=1000:0 config/infinispan/infinispan.xml /opt/infinispan/server/conf/infinispan.xml
COPY --chown=1000:0 infinispan-server-libs /opt/infinispan/server/lib