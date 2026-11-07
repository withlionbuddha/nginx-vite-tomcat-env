# Java 21 JDK-based Tomcat image. Override at build time if required.
ARG TOMCAT_VERSION=10.1-jdk21-temurin

#Tomcat + JDK21
FROM tomcat:${TOMCAT_VERSION}


# Restore Tomcat's default applications for a standalone health check.
# Remove this step for production if the default applications are not needed.
RUN cp -a /usr/local/tomcat/webapps.dist/. /usr/local/tomcat/webapps/

EXPOSE 8080
