#!/bin/bash

# Initialize variables
url=""
change_password=0  # Control flag for changing the root password
new_password=""    # Initialize the password variable as empty
project=""
servername=""
domain=""
swarmtoken=""
swarmip=""
serverip=$(hostname -I | awk '{print $1}')
apppassword=$(openssl rand -base64 12)
type="manager"

# Function to display usage
usage() {
    echo "Usage: $0 --hookurl=<hookurl> [--newpassword=1] --project=<project_name> --servername=<server_name> --domain=<domain> [--swarmtoken=<swarm_token> [--swarmip=<swarm_ip> [--serverip=<server_ip>]]]"
    exit 1
}

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --hookurl=*)
            hookurl="${arg#*=}"
            shift # Remove --hookurl from processing
            ;;
        --newpassword=1)
            change_password=1
            shift # Remove --newpassword from processing
            ;;
        --project=*)
            project="${arg#*=}"
            shift # Remove --project from processing
            ;;
        --servername=*)
            servername="${arg#*=}"
            shift # Remove --servername from processing
            ;;
        --domain=*)
            domain="${arg#*=}"
            shift # Remove --domain from processing
            ;;
        --swarmtoken=*)
            swarmtoken="${arg#*=}"
            shift # Remove --swarmtoken from processing
            ;;
        --swarmip=*)
            swarmip="${arg#*=}"
            shift # Remove --swarmip from processing
            ;;
        --serverip=*)
            serverip="${arg#*=}"
            shift # Remove --serverip from processing
            ;;
        *)
            usage # Call usage function for unknown options
            ;;
    esac
done

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

# Install Cockpit
if ! command -v cockpit &> /dev/null; then
    echo "Cockpit is not installed. Installing Cockpit from backports..."
    . /etc/os-release
    sudo apt install -t ${VERSION_CODENAME}-backports cockpit -y
    sudo systemctl enable cockpit.socket
    sudo systemctl start cockpit.socket
    echo "Cockpit has been installed from backports."
else
    echo "Cockpit is already installed."
fi

# Check if Docker is installed
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

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    echo "Docker Compose has been installed."
else
    echo "Docker Compose is already installed."
fi

# if swarmtoken or swarmip is not provided, then we are not joining a swarm and we are a manager
if [ -z "$swarmtoken" ] || [ -z "$swarmip" ]; then
    echo "Swarm token or IP not provided. This node will be a manager."
    type="manager"
    docker swarm init
else
    echo "Swarm token and IP provided. This node will be a worker."
    type="worker"
fi

# Determine if this node is a manager and proceed accordingly
if docker node inspect self --format '{{ .Spec.Role }}' 2>/dev/null | grep -qw "manager"; then
    echo "This node is a manager."
    echo "Installing Swarmpit."
    docker run -it --rm \
      --name swarmpit-installer \
      --volume /var/run/docker.sock:/var/run/docker.sock \
      -e INTERACTIVE=0 \
      -e STACK_NAME=swarmpit \
      -e APP_PORT=65003 \
      swarmpit/install:edge
    echo "Running docker-compose..."
    docker build -t custom-jenkins .
    APP_PASSWORD=$apppassword docker-compose -f docker-compose.yml up -d --build
else
    echo "This node is not a manager. Skipping manager-specific installations."
    type="worker"
fi

# Register the server with the backend regardless of the node type
curl -X POST "${hookurl}" \
    -H "Content-Type: application/json" \
    -d "{\"swarmip\": \"$swarmip\", \"serverip\": \"$serverip\", \"swarmtoken\": \"$swarmtoken\", \"password\": \"$new_password\", \"apppassword\": \"$apppassword\", \"project\": \"$project\", \"servername\": \"$servername\", \"domain\": \"$domain\", \"type\": \"$type\"}"
