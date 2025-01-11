#!/bin/bash

set -e  # Exit on any command failure

# Log message function
log_msg() {
    local status=$1
    local message=$2
    if [ "$status" -eq 0 ]; then
        echo "$message is successful"
    else
        echo "$message failed"
    fi
}

# Function to deploy frontend
deploy_frontend() {
    echo "Deploying Frontend..."
    sudo apt update && log_msg $? "1. apt update"
    sudo apt install -y apache2 && log_msg $? "2. apt install apache2"
    sudo chown -R www-data:www-data /var/www/html && log_msg $? "3. chown"
    sudo chmod -R 755 /var/www/html && log_msg $? "4. chmod"
    sudo systemctl restart apache2 && log_msg $? "5. restart apache2"

    cd /var/www/html || { echo "6. cd to /var/www/html failed"; exit 1; }
    sudo rm index.html
    sudo cp /tmp/UI.tar . && log_msg $? "7. cp UI.tar"
    sudo tar -xvf UI.tar && log_msg $? "8. extract UI.tar"
    sudo rm UI.tar && log_msg $? "9. remove UI.tar"

    echo "Enabling reverse proxy modules..."
    sudo a2enmod proxy && log_msg $? "10. enable proxy"
    sudo a2enmod proxy_http && log_msg $? "11. enable proxy_http"

    echo "Configuring reverse proxy..."
    sudo bash -c 'cat > /etc/apache2/sites-available/000-default.conf' <<EOF
<VirtualHost *:80>
    ServerName 3.106.52.156

    ProxyPass /chat http://127.0.0.1:8080/chat
    ProxyPassReverse /chat http://127.0.0.1:8080/chat

    DocumentRoot /var/www/html
    <Directory /var/www/html>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
    log_msg $? "12. update default site configuration"

    sudo chmod 644 /etc/apache2/sites-available/000-default.conf && log_msg $? "13. chmod configuration"
    echo "Frontend deployed successfully!"
}

# Function to deploy backend
deploy_backend() {
    echo "Deploying Backend..."
    cd / || { echo "cd to root failed"; exit 1; }
    
    # Avoid sudo su; use sudo for specific commands
    sudo rm -rf /home/ubuntu/anaconda3
    sudo rm -rf /kaviwebdesign

    for file in BACKEND.tar DB.tar; do
        sudo cp /tmp/$file /kaviwebdesign/ && log_msg $? "copy $file"
    done

    cd /kaviwebdesign
    sudo cp /tmp/operator_menu.sh . && log_msg $? "copy operator_menu.sh"
    sudo chmod 777 operator_menu.sh && log_msg $? "chmod operator_menu.sh"
    sudo tar -xvf BACKEND.tar && log_msg $? "extract BACKEND.tar"
    sudo tar -xvf DB.tar && log_msg $? "extract DB.tar"
    sudo rm BACKEND.tar DB.tar && log_msg $? "remove tar files"

    sudo apt update && log_msg $? "apt update"

    # Install and verify Anaconda
    sudo cp /tmp/Anaconda3-2024.10-1-Linux-aarch64.sh /kaviwebdesign/BACKEND
    sudo chmod +x /kaviwebdesign/BACKEND/Anaconda3-2024.10-1-Linux-aarch64.sh
    /kaviwebdesign/BACKEND/Anaconda3-2024.10-1-Linux-aarch64.sh -b -p /home/ubuntu/anaconda3 && log_msg $? "install Anaconda"

    /home/ubuntu/anaconda3/bin/conda init && log_msg $? "conda init"
    source ~/.bashrc
    conda --version

    conda env create -f /kaviwebdesign/BACKEND/environment.yml && log_msg $? "create Conda environment"
    echo "Backend deployed successfully!"
}

# Function for utility operations
utility_operations() {
    echo "Running Utility..."
    cd /kaviwebdesign || { echo "cd to /kaviwebdesign failed"; exit 1; }
    ./operator_menu.sh && log_msg $? "execute operator_menu.sh"
    echo "Utility executed successfully!"
}

# Display menu
while true; do
    echo -e "\nSelect an option:"
    echo "1. Deploy Frontend"
    echo "2. Deploy Backend"
    echo "3. Utility"
    echo "4. Exit"
    read -rp "Enter your choice: " choice

    case $choice in
        1) deploy_frontend ;;
        2) deploy_backend ;;
        3) utility_operations ;;
        4) echo "Exiting..."; break ;;
        *) echo "Invalid choice. Please select again." ;;
    esac
done
