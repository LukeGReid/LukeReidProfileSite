#!/bin/bash
#This script is designed to setup the development environment and all of it's requirements on a single development machine.
#This is the first iteration of the application setup as a proof-of-concept before tools are split, containerized, and move to cloud services.
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

#Setup dependencies
sudo apt update
sudo apt -y install ca-certificates curl gnupg lsb-release gpg software-properties-common apt-transport-https

###Add package sources. Note that this method of downloading GPG keys is susceptible to mitm attacks. Using /usr/share/keyrings for security according to the debian wiki https://wiki.debian.org/DebianRepository/UseThirdParty
declare -A appSourceList=( \
    ["docker"]="https://download.docker.com/linux/ubuntu/gpg|https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    ["postgresql"]="https://www.postgresql.org/media/keys/ACCC4CF8.asc|http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
    ["hashicorp"]="https://apt.releases.hashicorp.com/gpg|https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    ["elasticsearch"]="https://artifacts.elastic.co/GPG-KEY-elasticsearch|https://artifacts.elastic.co/packages/8.x/apt stable main" \
    ["nodejs"]="https://deb.nodesource.com/gpgkey/nodesource.gpg.key|https://deb.nodesource.com/node_16.x $(lsb_release -c -s) main"
)
for APPNAME in "${!appSourceList[@]}"; do
    IFS='|'; read -a valueArray <<< "${appSourceList[$key]}"; unset IFS;
    CURRENTGPGKEYSOURCE="${valueArray[0]}"
    CURRENTAPTSOURCE="${valueArray[1]}"
    CURRENTGPGKEYFILE="/usr/share/keyrings/$APPNAME-archive-keyring.gpg"
    CURRENTAPTSOURCEFILE="/etc/apt/sources.list.d/$APPNAME.list"
    if [ ! -f "$CURRENTGPGKEYFILE" ]; then
        curl -fsSL "$CURRENTGPGKEYSOURCE" | sudo gpg --dearmor -o "$CURRENTGPGKEYFILE"
        gpg --no-default-keyring --keyring "$APPNAME" --fingerprint
    fi

    if [ ! -f "$CURRENTAPTSOURCEFILE" ]; then
        echo "deb [arch=$(dpkg --print-architecture) signed-by=$CURRENTGPGKEYFILE] $CURRENTAPTSOURCE" | sudo tee "$CURRENTAPTSOURCEFILE"
    fi
done
#Ansible
sudo add-apt-repository --yes --update ppa:ansible/ansible

###Install primary apps
sudo apt update && \
sudo apt install -y \
docker-ce docker-ce-cli containerd.io docker-compose-plugin `#Docker` \
postgresql libpq-dev `#Postgres` \
vault terraform `#Hashicorp` \
ansible `#Ansible` \
elasticsearch kibana apm-server `#Elasticstack - elasticsearch needs to be manually started the first time` \
nodejs `#NodeJS` \
golang-go `#Go` 

#Sass (through NPM)
sudo npm install --location=global sass
#Ansible community
ansible-galaxy collection install community.general

#Setup libraries, tools, and other dependencies stack
#Opentelemetry
sudo pip3 install virtualenvwrapper
pip3 install opentelemetry-api opentelemetry-sdk

#Environment Configuration
#Add pythonvirtualenvironment setup to bashrc if it doesn't exist already.
if ! grep -q "export VIRTUALENVWRAPPER" ~/.bashrc; then
    cat "$SCRIPT_DIR/PythonVirtualEnvironmentSetup" >> ~/.bashrc
fi