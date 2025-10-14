#!/bin/bash

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_RESET='\033[0m'

# -------------------------------------------------------------------
# Function to display header
# -------------------------------------------------------------------
header_info() {
    clear
    printf "${COLOR_RED}"
    cat <<"EOF"
███████╗███╗   ██╗ █████╗ ██████╗ ██╗     ███████╗    ██████╗ ███████╗██████╗     ███████╗███████╗██╗  ██╗
██╔════╝████╗  ██║██╔══██╗██╔══██╗██║     ██╔════╝    ██╔══██╗██╔════╝██╔══██╗    ██╔════╝██╔════╝██║  ██║
█████╗  ██╔██╗ ██║███████║██████╔╝██║     █████╗      ██████╔╝█████╗  ██║  ██║    ███████╗███████╗███████║
██╔══╝  ██║╚██╗██║██╔══██║██╔══██╗██║     ██╔══╝      ██╔══██╗██╔══╝  ██║  ██║    ╚════██║╚════██║██╔══██║
███████╗██║ ╚████║██║  ██║██████╔╝███████╗███████╗    ██║  ██║███████╗██████╔╝    ███████║███████║██║  ██║
╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝    ╚═╝  ╚═╝╚══════╝╚═════╝     ╚══════╝╚══════╝╚═╝  ╚═╝               
EOF
    printf "${COLOR_RESET}\n"
}

# -------------------------------------------------------------------
# Function to handle command results
# -------------------------------------------------------------------
handle_result() {
    if [ "$1" -ne 0 ]; then
        printf "${COLOR_RED}[!] Error during step: %s${COLOR_RESET}\n" "$2" >&2
        exit 1
    else
        printf "${COLOR_GREEN}[+] %s: Success${COLOR_RESET}\n" "$2"
    fi
}

# Display header
header_info

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    printf "${COLOR_RED}[!] This script must be run as root.${COLOR_RESET}\n" >&2
    exit 1
fi

cat <<EOF > /etc/ssh/sshd_config.d/custom.conf
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
EOF
handle_result $? "Write SSH configuration to /etc/ssh/sshd_config.d/custom.conf"

# Restart SSH service
systemctl restart sshd
handle_result $? "Restart SSH service"

echo -e "${COLOR_GREEN}Password authentication has been disabled for SSH.${COLOR_RESET}"

# Change PS1 shell prompt
echo "PS1='\[\e[1;31m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '" >> ~/.bashrc
handle_result $? "Update shell prompt"

# Prompt user to add public key
echo -e "${COLOR_GREEN}Please paste your public key:${COLOR_RESET}"
read -r PUBLIC_KEY

# Add public key to root's authorized_keys
mkdir -p /root/.ssh
echo "$PUBLIC_KEY" >> /root/.ssh/authorized_keys
handle_result $? "Add public key to /root/.ssh/authorized_keys"

# Add public key to current user's authorized_keys
mkdir -p ~/.ssh
echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
handle_result $? "Add public key to ~/.ssh/authorized_keys"

echo -e "${COLOR_GREEN}Public key has been added to the appropriate locations.${COLOR_RESET}"