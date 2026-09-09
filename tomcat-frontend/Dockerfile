FROM tomcat:10.1.59-jre21-temurin-noble

# Keep the WAS runnable even when no application source or WAR is available.
RUN rm -rf /usr/local/tomcat/webapps/* \
    && mkdir -p /usr/local/tomcat/webapps/ROOT \
    && printf '%s\n' \
       '<!doctype html>' \
       '<html><head><meta charset="utf-8"><title>Tomcat Frontend</title></head>' \
       '<body><h1>Tomcat Frontend is running</h1><p>No application WAR is deployed.</p></body></html>' \
       > /usr/local/tomcat/webapps/ROOT/index.html

EXPOSE 8080
