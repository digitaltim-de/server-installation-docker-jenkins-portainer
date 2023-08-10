# Verwende das offizielle Jenkins-Basisimage
FROM jenkins/jenkins:lts

# Root-Benutzer werden, um Pakete zu installieren
USER root

# Installiere Abhängigkeiten und Docker
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    apt-get update && \
    apt-get install -y docker-ce

# Setze den Benutzer wieder auf den Jenkins-Benutzer
USER jenkins
