#!/bin/bash

# Prompt the user for the number of proxies
read -p "Enter the number of proxies you want to create: " NUM_PROXIES

# Validate the input
if ! [[ "$NUM_PROXIES" =~ ^[1-9][0-9]*$ ]]; then
    echo "Invalid input. Please enter a positive integer for the number of proxies."
    exit 1
fi

# Obtain the external IP address
STARTING_IP=$(curl -s ifconfig.me)

# Validate the input
if ! [[ "$STARTING_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo "Unable to retrieve a valid external IP address. Exiting."
    exit 1
fi

# Define port range
PORT_START=10001
PORT_END=$((PORT_START + NUM_PROXIES - 1))

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
sudo firewall-cmd --zone=public --permanent --add-port=$PORT_START-$PORT_END/tcp
sudo firewall-cmd --reload

# Enable and start Squid service
sudo systemctl enable squid
sudo systemctl start squid

# Create a Squid password file
SQUID_PASSWD_FILE="/etc/squid/passwd"
sudo touch $SQUID_PASSWD_FILE

# Generate multiple ports, usernames, and passwords
for ((i=0; i<$NUM_PROXIES; i++))
do
    PORT=$((PORT_START + i))
    USERNAME=$(openssl rand -hex 3 | tr -d '[:xdigit:]')  # Generate a random 5-character alphanumeric username
    PASSWORD=$(openssl rand -hex 3 | tr -d '[:xdigit:]')  # Generate a random 5-character alphanumeric password

    # Append proxy configuration to Squid file
    echo "http_port $STARTING_IP:$PORT" | sudo tee -a /etc/squid/squid.conf > /dev/null
    echo "acl proxy$i proxy_auth $USERNAME" | sudo tee -a /etc/squid/squid.conf > /dev/null
    echo "http_access allow proxy$i" | sudo tee -a /etc/squid/squid.conf > /dev/null

    # Add user to Squid password file
    echo "$USERNAME:$PASSWORD" | sudo htpasswd -i -c $SQUID_PASSWD_FILE -

    # Display proxy information
    echo "Proxy $((i+1)):"
    echo "IP: $STARTING_IP"
    echo "Port: $PORT"
    echo "Username: $USERNAME"
    echo "Password: $PASSWORD"
    echo "-------------------------"
done

# Display Squid proxy information
echo "Squid Proxy Server is now running with $NUM_PROXIES proxies."
echo "Port Range: $PORT_START-$PORT_END"
echo "Squid password file: $SQUID_PASSWD_FILE"
