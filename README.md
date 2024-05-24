# Docker, Jenkins, and Portainer Installation

Use the following commands to install Docker, Jenkins, and Portainer on your Ubuntu 18.04 server.

```bash
chmod +x start.sh && ./start.sh
```

-----------------


This script will install Docker and Docker Compose if they are not already installed. After that, it will start Jenkins
and Portainer, Swarmpit containers.

Help us improve this script by contributing to this repository.

This script will change your root password if you send as parameter --newpassword=1 and register this server after install under your "url". Its builded for swarm cluster.
-------------

## Server Installation

To clone the repository, execute the following `git clone` command. Replace the URL with the actual GitHub repository
URL.

```bash
git clone https://github.com/digitaltim-de/server-installation-docker-jenkins-portainer.git
```

This command will clone the entire repository into a directory named `server-installation-docker-jenkins-portainer` in
your current directory.

Navigate to the cloned directory:

```bash
cd server-installation-docker-jenkins-portainer
```

You can now run the `start.sh` script:

```bash
chmod +x start.sh && ./start.sh
```

## On Production

On production you can use the following command to install the server with a new password, register the server under
your url and set the project name, servername and domain.

Just select an "ubuntu image" create your new server or droplet and after that execute the following command:

```bash
git clone https://github.com/digitaltim-de/server-installation-docker-jenkins-portainer.git && cd server-installation-docker-jenkins-portainer && chmod +x start.sh && ./start.sh --url=https://webhook.site/d564f0bf-8014-4df5-8059-93b7479f35de --newpassword=1 --project=myprojectname --servername=servername-like-myprojectname.php --domain=serverdomain
```

Your Server will be registered under your url and you will get a webhook notification with the servername and domain.

## After Installation ##

### Jenkins ###

Jenkins will be available at `http://<your-server-ip>:65000`. You will need to enter the initial admin password to
unlock Jenkins. You can get the initial admin password by executing the following command:

```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### Portainer ###

Portainer will be available at `http://<your-server-ip>:65002`. You will need to create an admin user to login to
Portainer. You can do this by following the on-screen instructions.

### NGINX Manager ###

NGINX Manager will be available at `http://<your-server-ip>:65003`. You will need to create an admin user to login to
NGINX Manager. You can do this by following the on-screen instructions.
