FROM maven:3.9.16-eclipse-temurin-21-noble AS build

WORKDIR /workspace

COPY frontend/pom.xml frontend/pom.xml
RUN mvn -B -f frontend/pom.xml dependency:go-offline

COPY frontend/src frontend/src
RUN mvn -B -f frontend/pom.xml -DskipTests package

FROM tomcat:10.1.59-jre21-temurin-noble

RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=build /workspace/frontweb/target/*.war /usr/local/tomcat/webapps/frontweb.war

EXPOSE 8080
