ARG TOMCAT_VERSION
FROM tomcat:${TOMCAT_VERSION}

# The official image keeps the default Tomcat web applications in webapps.dist.
# Restore them so the WAS can be verified without application source or a WAR.
RUN cp -a /usr/local/tomcat/webapps.dist/. /usr/local/tomcat/webapps/

EXPOSE 8080
