#!/bin/bash

# Script to set up Chaotic AUR repository

# Check if script is run with sudo/root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with sudo or as root" 
   exit 1
fi

# Function to handle errors
handle_error() {
    echo "Error: $1"
    exit 1
}

# Repository key details
REPO_KEY="3056513887B78AEB"
KEYSERVER="keyserver.ubuntu.com"

# Chaotic AUR mirror URLs
KEYRING_URL="https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst"
MIRRORLIST_URL="https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst"

# Step 1: Receive and sign the repository key
echo "Receiving repository key..."
pacman-key --recv-key "$REPO_KEY" --keyserver "$KEYSERVER" || handle_error "Failed to receive repository key"

echo "Locally signing the repository key..."
pacman-key --lsign-key "$REPO_KEY" || handle_error "Failed to locally sign the repository key"

# Step 2: Download and install keyring and mirrorlist
echo "Downloading and installing Chaotic AUR keyring..."
curl -LO "$KEYRING_URL" || handle_error "Failed to download keyring package"
pacman -U --noconfirm chaotic-keyring.pkg.tar.zst || handle_error "Failed to install keyring package"
rm chaotic-keyring.pkg.tar.zst

echo "Downloading and installing Chaotic AUR mirrorlist..."
curl -LO "$MIRRORLIST_URL" || handle_error "Failed to download mirrorlist package"
pacman -U --noconfirm chaotic-mirrorlist.pkg.tar.zst || handle_error "Failed to install mirrorlist package"
rm chaotic-mirrorlist.pkg.tar.zst

# Step 3: Add repository to pacman.conf
echo "Configuring pacman.conf..."
if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
    cat << EOF >> /etc/pacman.conf

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
    echo "Chaotic AUR repository added to pacman.conf"
else
    echo "Chaotic AUR repository already exists in pacman.conf"
fi

# Step 4: Update package databases
echo "Updating package databases..."
pacman -Sy || handle_error "Failed to update package databases"

echo "Chaotic AUR repository setup completed successfully!"

# Optional: Clean up any downloaded packages
# Uncomment the following line if you want to ensure cleanup
# rm -f chaotic-keyring.pkg.tar.zst chaotic-mirrorlist.pkg.tar.zst

exit 0
