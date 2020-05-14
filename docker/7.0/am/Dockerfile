# Phil's experimental image
FROM gcr.io/engineering-devops/am-fbc:7.0.0-9124a835300631a82200d88fb5dafbbeec0cb5c2

USER root

RUN apt-get update && apt-get install -y git

USER forgerock

# for testing if we want to override the entrypoint...
COPY  --chown=forgerock:root docker-entrypoint.sh /home/forgerock

COPY  --chown=forgerock:root config/ /home/forgerock/openam/config/

# Use a custom logback. Comment out if you want to use the default json logger.
COPY logback.xml /usr/local/tomcat/webapps/am/WEB-INF/classes

WORKDIR /home/forgerock/openam

# This lets the user see what FBC files have been modified
RUN git config --global user.email "cloud-deployment@forgerock.com" && \
    git config --global user.name "Cloud Deployment" && \
    git add . && \
    git commit -m "CDM file-based configuration overlay"

WORKDIR /home/forgerock
