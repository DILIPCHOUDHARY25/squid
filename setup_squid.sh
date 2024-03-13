#!/bin/bash

# Prompt the user for the number of proxies
read -p "Enter the number of proxies you want to create: " NUM_PROXIES

# Validate the input
if ! [[ "$NUM_PROXIES" =~ ^[1-9][0-9]*$ ]]; then
    echo "Invalid input. Please enter a positive integer for the number of proxies."
    exit 1
fi

# Define port range
PORT_RANGE="10001-30000"

# Update the system
sudo yum update -y

# Install Squid
sudo yum install squid -y

# Backup the original Squid configuration file
sudo mv /etc/squid/squid.conf /etc/squid/squid.conf.bak

# Create a new Squid configuration file
sudo tee /etc/squid/squid.conf > /dev/null <<EOF
# Add common Squid configuration here
EOF

# Adjust firewall settings
sudo firewall-cmd --zone=public --permanent --add-port=$PORT_RANGE/tcp
sudo firewall-cmd --reload

# Enable and start Squid service
sudo systemctl enable squid
sudo systemctl start squid

# Create a Squid password file
SQUID_PASSWD_FILE="/etc/squid/passwd"
sudo touch $SQUID_PASSWD_FILE

# Generate multiple IPs, ports, usernames, and passwords
for ((i=1; i<=$NUM_PROXIES; i++))
do
    # Prompt the user for the desired IP range
    read -p "Enter the starting IP for Proxy $i: " STARTING_IP

    # Validate the input
    if ! [[ "$STARTING_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo "Invalid input. Please enter a valid IP address."
        exit 1
    fi

    IP="$STARTING_IP"
    PORT=$((10000 + i))
    USERNAME=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 5)  # Generate a random 5-character alphanumeric username
    PASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 5)  # Generate a random 5-character alphanumeric password

    # Append proxy configuration to Squid file
    echo "http_port $IP:$PORT" | sudo tee -a /etc/squid/squid.conf > /dev/null
    echo "acl proxy$i proxy_auth $USERNAME" | sudo tee -a /etc/squid/squid.conf > /dev/null
    echo "http_access allow proxy$i" | sudo tee -a /etc/squid/squid.conf > /dev/null

    # Add user to Squid password file
    echo "$USERNAME:$PASSWORD" | sudo htpasswd -i -c $SQUID_PASSWD_FILE -

    # Display proxy information
    echo "Proxy $i:"
    echo "IP: $IP"
    echo "Port: $PORT"
    echo "Username: $USERNAME"
    echo "Password: $PASSWORD"
    echo "-------------------------"
done

# Display Squid proxy information
echo "Squid Proxy Server is now running with $NUM_PROXIES proxies."
echo "Port Range: $PORT_RANGE"
echo "Squid password file: $SQUID_PASSWD_FILE"
