FROM gcr.io/distroless/java11-debian11@sha256:a24bdd8a401a0c9e8fdddce980f09e3d38cc243e392f1cc58bcf898e7ea1d405

COPY target/worker-0.0.1.jar worker.jar

ENTRYPOINT ["java", \
"-XX:+UseContainerSupport", \
"-Xmx256m", \
"-Dcom.sun.management.jmxremote=true", \
"-Dcom.sun.management.jmxremote.port=9010", \
"-Dcom.sun.management.jmxremote.local.only=false", \
"-Dcom.sun.management.jmxremote.authenticate=false", \
"-Dcom.sun.management.jmxremote.ssl=false", \
"-Dcom.sun.management.jmxremote.rmi.port=9010", \
"-Djava.rmi.server.hostname=localhost", \
"-jar", "worker.jar"]

EXPOSE 8080
EXPOSE 9010

