#!/bin/bash

DOCKER_DEB=docker-engine-1.13.1.deb
OCP_TAR=openshift-origin-client-tools-v3.11.0.tar.gz

wget https://ftp.yandex.ru/mirrors/docker/pool/main/d/docker-engine/docker-engine_1.13.1-0~ubuntu-xenial_amd64.deb -O $DOCKER_DEB
wget https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz -O $OCP_TAR

sed -i 's/archive.ubuntu.com/free.nchc.org.tw/g' /etc/apt/sources.list

apt-get update
apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    libltdl7

cat <<EOF >> /etc/cloud/templates/hosts.debian.tmpl
192.168.64.1 nexus.docker.internal
127.0.0.1 ocp.docker.internal
EOF

cat <<EOF >> /etc/hosts
192.168.64.1 nexus.docker.internal
127.0.0.1 ocp.docker.internal
EOF

dpkg -i $DOCKER_DEB

mkdir $HOME/ocp
tar zxvf $OCP_TAR -C $HOME/ocp
mv $HOME/ocp/kubectl /usr/local/bin
mv $HOME/ocp/oc /usr/local/bin

rm $DOCKER_DEB
rm $OCP_TAR
rm -rf $HOME/ocp

cat <<EOF > $HOME/start_ocp.sh
#!/bin/sh

oc cluster up --skip-registry-check=true --public-hostname="ocp.docker.internal"
EOF

chown ubuntu:ubuntu $HOME/start_ocp.sh
chmod +x $HOME/start_ocp.sh