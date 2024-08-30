#!/bin/bash

# Initialize variables
hookurl=""
change_password=0
new_password=""
project=""
servername=""
domain=""
swarmtoken=""
swarmip=""
serverip=$(hostname -I | awk '{print $1}')
apppassword=$(openssl rand -base64 12)
type="manager"
swapsize=8  # Default swap size in GB

## Change the hostname
sudo hostnamectl set-hostname $servername

# Function to display usage
usage() {
    echo "Usage: $0 --hookurl=<hookurl> [--newpassword=1] --project=<project_name> --servername=<server_name> --domain=<domain> [--swarmtoken=<swarm_token> [--swarmip=<swarm_ip> [--serverip=<server_ip> [--swap=<swap_size>]]]]"
    exit 1
}

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --hookurl=*)
            hookurl="${arg#*=}"
            shift
            ;;
        --newpassword=1)
            change_password=1
            shift
            ;;
        --project=*)
            project="${arg#*=}"
            shift
            ;;
        --servername=*)
            servername="${arg#*=}"
            shift
            ;;
        --domain=*)
            domain="${arg#*=}"
            shift
            ;;
        --swarmtoken=*)
            swarmtoken="${arg#*=}"
            shift
            ;;
        --swarmip=*)
            swarmip="${arg#*=}"
            shift
            ;;
        --serverip=*)
            serverip="${arg#*=}"
            shift
            ;;
        --swap=*)
            swapsize="${arg#*=}"
            shift
            ;;
        *)
            usage
            ;;
    esac
done

# Function to configure swap
configure_swap() {
    echo "Configuring a new swap file with size ${swapsize}G..."
    sudo swapoff -a && sudo dd if=/dev/zero of=/swapfile bs=1G count=${swapsize} && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
    echo "Swap configuration complete."
}

# Check if swapsize is provided and is a numerical value
if [ -z "${swapsize}" ]; then
    echo "Swap size is not set. Exiting..."
    exit 1
elif ! [[ "${swapsize}" =~ ^[0-9]+$ ]]; then
    echo "Swap size must be a number. Exiting..."
    exit 1
fi

# Configure swap if swapsize is not the default (8G), or always configure if you prefer
if [ "${swapsize}" -ne 8 ]; then
    configure_swap
else
    echo "Swap size is the default (8G). No changes made."
fi


# Check for required arguments
if [ -z "$hookurl" ] || [ -z "$project" ] || [ -z "$servername" ] || [ -z "$domain" ]; then
    echo "Error: hookurl, project, servername, and domain are required."
    usage
fi

echo "Using Hookurl: $hookurl"
echo "Project: $project"
echo "Server Name: $servername"
echo "Domain: $domain"
echo "Swarm IP: ${swarmip:-'Not Provided'}"
echo "Server IP: $serverip"
echo "App Password: $apppassword"

# Generate a random password and update root password if requested
if [ "$change_password" -eq 1 ]; then
    new_password=$(openssl rand -base64 12)
    echo "root:$new_password" | sudo chpasswd
    echo "Root password has been changed."
else
    echo "Root password change was not requested."
fi

# Install and configure Docker environment
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    sudo systemctl enable docker
    sudo systemctl start docker
    echo "Docker has been installed."
else
    echo "Docker is already installed."
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    echo "Docker Compose has been installed."
else
    echo "Docker Compose is already installed."
fi

# Handle Docker Swarm operations
if [ -z "$swarmtoken" ] || [ -z "$swarmip" ]; then
    echo "Swarm token or IP not provided. This node will initialize a new Swarm as a manager."
    docker swarm init
    swarmtoken=$(docker swarm join-token manager -q)
    swarmip=$serverip
    type="manager"
else
    echo "Swarm token and IP provided. This node will join the Swarm as a worker."
    docker swarm join --token $swarmtoken $swarmip:2377
    type="worker"
fi

# Install Cockpit
if ! command -v cockpit &> /dev/null; then
    echo "Cockpit is not installed. Installing Cockpit from backports..."
    . /etc/os-release
    sudo apt install -t ${VERSION_CODENAME}-backports cockpit -y
    sudo systemctl enable cockpit.socket
    sudo systemctl start cockpit.socket
    echo "Cockpit has been installed from backports."
    sudo rm -rf /etc/cockpit/disallowed-users
else
    echo "Cockpit is already installed."
fi

# Determine if this node is a manager and proceed accordingly
if [ "$type" = "manager" ]; then
    echo "This node is a manager."
    echo "Running docker-compose..."
    APP_PASSWORD=$apppassword docker compose -f docker-compose.server.yml up -d --build
    APP_PASSWORD=$apppassword docker stack deploy -c docker-stack.swarmpit.yml swarmpit
    echo "Docker services have been started."
else
    echo "This node is not a manager. Skipping manager-specific installations."
fi

# Register the server with the backend regardless of the node type
curl -X POST "${hookurl}" \
    -H "Content-Type: application/json" \
    -d "{\"serverip\": \"$serverip\", \"swarmip\": \"$swarmip\", \"swarmtoken\": \"$swarmtoken\", \"password\": \"$new_password\", \"apppassword\": \"$apppassword\", \"project\": \"$project\", \"servername\": \"$servername\", \"domain\": \"$domain\", \"type\": \"$type\"}"

exit 0
