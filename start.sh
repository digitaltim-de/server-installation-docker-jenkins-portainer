#!/bin/bash

# Initialize variables
url=""
change_password=0  # Control flag for changing the root password
new_password=""    # Initialize the password variable as empty
project=""
servername=""
domain=""
join=""
serverip=$(hostname -I | awk '{print $1}')

# Function to display usage
usage() {
    echo "Usage: $0 --url=<url> [--newpassword=1] --project=<project_name> --servername=<server_name> --domain=<domain> [--join=<DOCKERSWARMJOINTOKEN> [--serverip=<server_ip>]]"
    exit 1
}

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --url=*)
            url="${arg#*=}"
            shift # Remove --url from processing
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
        --join=*)
            join="${arg#*=}"
            shift # Remove --join from processing
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

# Check if required parameters were provided
if [ -z "$url" ] || [ -z "$project" ] || [ -z "$servername" ] || [ -z "$domain" ] || [ -z "$serverip" ]; then
    echo "Error: URL, project name, server name, serverip, and domain are required."
    usage
fi

echo "Using URL: $url"
echo "Project: $project"
echo "Server Name: $servername"
echo "Domain: $domain"
echo "Server IP: $serverip"

# Handle Docker Swarm initialization or joining
if [ -n "$join" ]; then
    echo "Joining Docker Swarm with token: $join"
    docker swarm join --token $join $serverip:2377
else
    echo "Initializing new Docker Swarm"
    docker swarm init
fi

# Generate a random password and update root password if requested
if [ "$change_password" -eq 1 ]; then
    new_password=$(openssl rand -base64 12)
    echo "root:$new_password" | sudo chpasswd
    echo "Root password has been changed."
else
    echo "Root password change was not requested."
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

# Install Cockpit from backports
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

# Install htop
if ! command -v htop &> /dev/null; then
    echo "htop is not installed. Installing htop..."
    sudo apt install htop -y
    echo "htop has been installed."
else
    echo "htop is already installed."
fi

## Swarmpit
# Check if this node is a manager and then install Swarmpit
if docker node inspect self --format '{{ .Spec.Role }}' 2>/dev/null | grep -qw "manager"; then
    echo "This node is a manager. Installing Swarmpit."
    docker run -it --rm \
      --name swarmpit-installer \
      --volume /var/run/docker.sock:/var/run/docker.sock \
      -e INTERACTIVE=0 \
      -e STACK_NAME=swarmpit \
      -e APP_PORT=65003 \
      swarmpit/install:edge
else
    echo "Warning: This node is not a manager. Swarmpit cannot be installed here and will be skipped."
fi

# Run docker-compose.yml
echo "Running docker-compose..."
docker build -t custom-jenkins .
docker-compose -f docker-compose.yml up -d --build

# Register the server with the backend
curl -X POST "${url}" \
    -H "Content-Type: application/json" \
    -d "{\"ip\": \"$serverip\", \"password\": \"$new_password\", \"project\": \"$project\", \"servername\": \"$servername\", \"domain\": \"$domain\"}"
