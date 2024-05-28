#!/bin/bash

# Set architecture (change to 'i386' for 32-bit systems)
ARCH="x86_64"

# Create a directory for Docker packages and their dependencies
mkdir -p docker_packages
cd docker_packages

# Add the Docker repository
sudo yum-config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo

# Ensure yumdownloader and repoquery are installed
sudo yum install -y yum-utils

# List of Docker packages to download
packages=(
    "docker-ce"
    "docker-ce-cli"
    "containerd.io"
    "docker-compose-plugin"
    "container-selinux"
    "fuse3-libs"
    "fuse-overlayfs" 
    "iptables"
    "libslirp" 
    "slirp4netns" 
    "docker-scan-plugin" 
    "docker-ce-rootless-extras"
)

# Function to download packages with retries
download_package() {
    local package_url=$1
    local package_name=$(basename $package_url)
    local retries=5

    for ((i=1; i<=retries; i++)); do
        echo "Attempting to download $package_name (try $i/$retries)..."
        yumdownloader --destdir=. --archlist=$ARCH $package_url
        if [ -f "$package_name" ] && [ "$(stat -c%s "$package_name")" -gt 8192 ]; then
            echo "$package_name downloaded successfully."
            return 0
        else
            echo "Download failed or file size too small for $package_name. Retrying..."
            rm -f "$package_name"
        fi
    done

    echo "Failed to download $package_name after $retries attempts."
    echo "$package_name" >> download_failures.log
    return 1
}

# Download the packages and their dependencies
for package in "${packages[@]}"; do
    yumdownloader --resolve --destdir=. --archlist=$ARCH $package
    # Get the list of dependencies
    dependencies=$(repoquery --requires --resolve --archlist=$ARCH $package)
    # Download each dependency
    for dependency in $dependencies; do
        download_package $dependency
    done
done

# Create a tarball of the downloaded packages
tar -czvf docker_packages_with_dependencies.tar.gz *.rpm

# Move the tarball to your home directory or any preferred location
mv docker_packages_with_dependencies.tar.gz ~/

# Clean up
cd ..
rm -rf docker_packages

echo "Docker packages and dependencies downloaded and compressed into docker_packages_with_dependencies.tar.gz"
echo "Check download_failures.log for any packages that failed to download."
