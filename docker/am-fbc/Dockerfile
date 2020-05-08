# Phil's experimental image
FROM gcr.io/engineering-devops/am-fbc:7.0.0-9124a835300631a82200d88fb5dafbbeec0cb5c2

# for testing if we want to override the entrypoint...
COPY  --chown=forgerock:root docker-entrypoint.sh /home/forgerock

# Use a custom logback. Comment out if you want to use the default json logger.
COPY logback.xml /usr/local/tomcat/webapps/am/WEB-INF/classes
