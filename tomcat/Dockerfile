FROM tomcat:10.1.59-jre21-temurin-noble

# The official image keeps the default Tomcat web applications in webapps.dist.
# Restore them so the WAS can be verified without application source or a WAR.
RUN cp -a /usr/local/tomcat/webapps.dist/. /usr/local/tomcat/webapps/

EXPOSE 8080
