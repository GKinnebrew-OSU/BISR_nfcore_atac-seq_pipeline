#!/usr/bin/env bash

# Setup script for installing Nextflow on OSC
# Run this script once to install Nextflow and configure your environment

set -e  # Exit on error

echo "=== Installing Nextflow on OSC ==="

# Create bin directory if it doesn't exist
mkdir -p ~/bin
cd ~/bin

# Download Nextflow
echo "Downloading Nextflow..."
curl -s https://get.nextflow.io | bash

# Make executable (should already be)
chmod +x nextflow

# Add to PATH in ~/.bashrc if not already there
if ! grep -q 'export PATH=$HOME/bin:$PATH' ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Added by Nextflow setup script" >> ~/.bashrc
    echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
    echo "Added Nextflow to PATH in ~/.bashrc"
fi

# Source the updated bashrc
source ~/.bashrc

# Test installation
echo ""
echo "=== Testing Nextflow installation ==="
~/bin/nextflow -version

echo ""
echo "=== Installation complete! ==="
echo "Please run: source ~/.bashrc"
echo "Or log out and log back in for PATH changes to take effect."
echo ""
echo "Nextflow installed at: ~/bin/nextflow"
echo "Container cache: \$HOME/nextflow_images (configured in osc.config)"
