#!/bin/bash

# Initialize variables
url=""
change_password=0  # Control flag for changing the root password
new_password=""    # Initialize the password variable as empty

# Function to display usage
usage() {
    echo "Usage: $0 --url=<url> [--newpassword=1]"
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
        *)
            usage # Unknown option
            ;;
    esac
done

# Check if URL was provided
if [ -z "$url" ]; then
    echo "Error: URL is required."
    usage
fi

echo "Using URL: $url"

# Generate a random password and update root password if requested
if [ "$change_password" -eq 1 ]; then
    new_password=$(openssl rand -base64 12)
    echo "root:$new_password" | sudo chpasswd
    echo "Root password has been changed."
else
    echo "Root password change was not requested."
fi

# Post the new or empty password to the server
curl -X POST "${url}?ip=$(hostname -I | awk '{print $1}')&password=$new_password"

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
    sudo chmod 777 /var/run/docker.sock
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

# Run docker-compose.yml
echo "Running docker-compose..."
docker build -t custom-jenkins .
docker-compose -f docker-compose.yml up -d --build
