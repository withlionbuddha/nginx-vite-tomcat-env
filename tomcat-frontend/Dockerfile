# syntax=docker/dockerfile:1
FROM maven:3.9.16-eclipse-temurin-21-noble AS build

WORKDIR /workspace/frontend

# The external Maven project must produce one deployable WAR.
RUN --mount=type=bind,from=frontwas_source,target=/source \
    tar -C /source --exclude=target --exclude=.git -cf /tmp/frontwas-source.tar . \
    && tar -C /workspace/frontend -xf /tmp/frontwas-source.tar \
    && rm /tmp/frontwas-source.tar
RUN mvn -B -DskipTests package

FROM tomcat:10.1.59-jre21-temurin-noble

RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=build /workspace/frontend/target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
