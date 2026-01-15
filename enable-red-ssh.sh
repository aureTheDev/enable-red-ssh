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
    printf "${COLOR_RED}[!] Exemple: sudo %s${COLOR_RESET}\n" "$0" >&2
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

# Change PS1 shell prompt (pour l'utilisateur effectif: root si lancé via sudo)
echo "PS1='\[\e[1;31m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '" >> ~/.bashrc
handle_result $? "Update shell prompt"

# Prompt user to add public key
echo -e "${COLOR_GREEN}Please paste your public key:${COLOR_RESET}"
read -r PUBLIC_KEY

# -------------------------------------------------------------------
# Add public key to root's authorized_keys
# -------------------------------------------------------------------
mkdir -p /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

echo "$PUBLIC_KEY" >> /root/.ssh/authorized_keys
handle_result $? "Add public key to /root/.ssh/authorized_keys"

# -------------------------------------------------------------------
# Add public key to invoking user's authorized_keys
# -------------------------------------------------------------------
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)

    if [ -z "$USER_HOME" ]; then
        printf "${COLOR_RED}[!] Unable to determine home directory for user %s${COLOR_RESET}\n" "$SUDO_USER" >&2
    else
        mkdir -p "$USER_HOME/.ssh"
        chmod 700 "$USER_HOME/.ssh"
        touch "$USER_HOME/.ssh/authorized_keys"
        chmod 600 "$USER_HOME/.ssh/authorized_keys"

        echo "$PUBLIC_KEY" >> "$USER_HOME/.ssh/authorized_keys"

        chown -R "$SUDO_USER":"$SUDO_USER" "$USER_HOME/.ssh"
        handle_result $? "Add public key to $SUDO_USER's ~/.ssh/authorized_keys"
    fi
fi

echo -e "${COLOR_GREEN}Public key has been added to the appropriate locations.${COLOR_RESET}"
