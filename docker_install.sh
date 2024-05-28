#!/bin/bash

IP_ADDRESS="{IP used for ssh}"
PACKAGE_FOLDER="/opt/docker/install_package"
PACKAGE_NAME="docker_packages_with_dependencies.tar.gz"

scp ./$PACKAGE_NAME $IP_ADDRESS:/tmp

# SSH into the server
ssh "$IP_ADDRESS" << EOF
sudo su
echo "1. Creating folder $PACKAGE_FOLDER"
mkdir -p $PACKAGE_FOLDER

echo "2. Moving package to $PACKAGE_FOLDER"
mv /tmp/$PACKAGE_NAME $PACKAGE_FOLDER

echo "3. Untar the file"
tar -xzvf $PACKAGE_FOLDER/$PACKAGE_NAME -C $PACKAGE_FOLDER

echo "4. Yum install the packages"
yum -y --disablerepo="*" install $PACKAGE_FOLDER/docker_packages/*.rpm --verbose

echo "5. Cleaning up $PACKAGE_FOLDER/$PACKAGE_NAME"
rm -rf $PACKAGE_FOLDER/$PACKAGE_NAME

echo "6. Enable and start Docker"
sudo systemctl enable docker
sudo systemctl start docker

echo "7. Verify the installation"
sudo docker --version

EOF


