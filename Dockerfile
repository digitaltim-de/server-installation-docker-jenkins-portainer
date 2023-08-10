# Verwende das offizielle Jenkins-Basisimage
FROM jenkins/jenkins:lts

# Root-Benutzer werden, um Pakete zu installieren
USER root

# Installiere Abhängigkeiten und Docker
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common && \
    curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh

# Setze den Benutzer wieder auf den Jenkins-Benutzer
USER jenkins
