#!/bin/bash

# Step 1: Download and run Squid installation script
wget https://raw.githubusercontent.com/serverok/squid-proxy-installer/master/squid3-install.sh
chmod +x squid3-install.sh
sudo ./squid3-install.sh

# Step 2: Prompt user for port number
read -p "Enter the port number for Squid proxy: " PORT

# Step 3: Generate random username and password
USERNAME=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 5)
PASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 5)

# Step 4: Add user to Squid password file
echo "$USERNAME:$PASSWORD" | sudo htpasswd -i -c /etc/squid/passwd -

# Step 5: Add port to Squid configuration
sudo sed -i "/http_port 3128/a http_port $PORT" /etc/squid/squid.conf

# Step 6: Adjust firewall settings
sudo firewall-cmd --permanent --add-port=$PORT/tcp
sudo firewall-cmd --reload

# Step 7: Restart Squid service
sudo systemctl restart squid

# Display Squid proxy information
echo "Squid Proxy Server is now running."
echo "Port: $PORT"
echo "Username: $USERNAME"
echo "Password: $PASSWORD"
echo "-------------------------"

# Display IP addresses
echo "Your IP addresses:"
curl -s ifconfig.me
