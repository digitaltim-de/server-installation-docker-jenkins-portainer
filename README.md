
# Docker, Jenkins, and Portainer Installation

Use the following commands to install Docker, Jenkins, and Portainer on your Ubuntu 18.04 server.

```bash
chmod +x start.sh && ./start.sh
```

-----------------


This script will install Docker and Docker Compose if they are not already installed. After that, it will start Jenkins and Portainer containers.

Help us improve this script by contributing to this repository.

-------------

## Server Installation
To clone the repository, execute the following `git clone` command. Replace the URL with the actual GitHub repository URL.

```bash
git clone https://github.com/digitaltim-de/server-installation-docker-jenkins-portainer.git
```

This command will clone the entire repository into a directory named `server-installation-docker-jenkins-portainer` in your current directory.

Navigate to the cloned directory:
```bash
cd server-installation-docker-jenkins-portainer
```

You can now run the `start.sh` script:
```bash
chmod +x start.sh && ./start.sh
```


## After Installation ##

### Jenkins ###

Jenkins will be available at `http://<your-server-ip>:65000`. You will need to enter the initial admin password to unlock Jenkins. You can get the initial admin password by executing the following command:

```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### Portainer ###
Portainer will be available at `http://<your-server-ip>:65002`. You will need to create an admin user to login to Portainer. You can do this by following the on-screen instructions.

### NGINX Manager ###
NGINX Manager will be available at `http://<your-server-ip>:65003`. You will need to create an admin user to login to NGINX Manager. You can do this by following the on-screen instructions.
