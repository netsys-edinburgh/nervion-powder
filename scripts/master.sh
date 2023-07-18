#!/bin/bash
#set -u
#set -x

SCRIPTDIR=$(dirname "$0")
WORKINGDIR='/local/repository'
username=$(id -nu)
HOME=/users/$(id -un)
usergid=$(id -ng)
experimentid=$(hostname|cut -d '.' -f 2)
projectid=$usergid

sudo chown ${username}:${usergid} ${WORKINGDIR}/ -R
cd $WORKINGDIR
# Redirect output to log file
exec >> ${WORKINGDIR}/deploy.log
exec 2>&1

KUBEHOME="${WORKINGDIR}/kube"
mkdir -p $KUBEHOME
export KUBECONFIG=$KUBEHOME/admin.conf

# make SSH shells play nice
sudo chsh -s /bin/bash $username
echo "export KUBECONFIG=${KUBECONFIG}" > $HOME/.profile

# add repositories
# Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
sudo add-apt-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
# Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# Update apt lists
sudo apt-get update

# Install pre-reqs
sudo apt-get -y install build-essential libffi-dev python python-dev  \
python-pip automake autoconf libtool indent vim tmux ctags xgrep

# pre-reqs for installing docker
sudo apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

# docker
sudo apt-get -y install docker-ce docker-ce-cli containerd.io

# learn from this: https://blog.csdn.net/yan234280533/article/details/75136630
# more info should see: https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
sudo apt-get -y install kubelet=1.21.3-00 kubeadm=1.21.3-00 kubectl=1.21.3-00 kubernetes-cni golang-go jq

sudo docker version

# Solving issues with cgroup-drivers
#echo '{"exec-opts": ["native.cgroupdriver=systemd"]}' | sudo tee /etc/docker/daemon.json
#sudo systemctl restart docker

sudo swapoff -a
sudo kubeadm init --config=config/kubeadm-config.yaml

# result will be like:  kubeadm join 155.98.36.111:6443 --token i0peso.pzk3vriw1iz06ruj --discovery-token-ca-cert-hash sha256:19c5fdee6189106f9cb5b622872fe4ac378f275a9d2d2b6de936848215847b98

# allow sN to log in with shared key
# see http://docs.powderwireless.net/advanced-topics.html
geni-get key > ${HOME}/.ssh/id_rsa
chmod 600 ${HOME}/.ssh/id_rsa
ssh-keygen -y -f ${HOME}/.ssh/id_rsa > ${HOME}/.ssh/id_rsa.pub
grep -q -f ${HOME}/.ssh/id_rsa.pub ${HOME}/.ssh/authorized_keys || cat ${HOME}/.ssh/id_rsa.pub >> ${HOME}/.ssh/authorized_keys

# https://github.com/kubernetes/kubernetes/issues/44665
sudo cp /etc/kubernetes/admin.conf $KUBEHOME/
sudo chown ${username}:${usergid} $KUBEHOME/admin.conf

# Install Flannel. See https://github.com/coreos/flannel
sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# use this to enable autocomplete
source <(kubectl completion bash)

# Install dashboard: https://github.com/kubernetes/dashboard
# v3 of kubernetes-dashboard has many software dependencies like Nginx Ingress and the set up process
# changes drastically. v2 serves the exact same functionality with a slightly more straightforward setup,
# so we will use the latest v2 (2.7.0) recommended YAML file as a base.
# It has been modified to allow HTTP access and to allow admin login without credentials. More details in
# the file itself.
echo "Launching Kubernetes Dashboard..."
sudo kubectl apply -f config/test/kubernetes-dashboard.yaml
 
# run the proxy to make the dashboard portal accessible from outside
echo "Running proxy at port 8080..."
sudo kubectl proxy -p 8080 --address='0.0.0.0' --accept-hosts='^*$' &

# jid for json parsing.
export GOPATH=${WORKINGDIR}/go/gopath
mkdir -p $GOPATH
export PATH=$PATH:$GOPATH/bin
sudo go get -u github.com/simeji/jid/cmd/jid
sudo go build -o /usr/bin/jid github.com/simeji/jid/cmd/jid

# install static cni plugin
sudo go get -u github.com/containernetworking/plugins/plugins/ipam/static
sudo go build -o /opt/cni/bin/static github.com/containernetworking/plugins/plugins/ipam/static

# install helm
echo "Installing Helm"
wget https://get.helm.sh/helm-v3.1.0-linux-amd64.tar.gz
tar xf helm-v3.1.0-linux-amd64.tar.gz
sudo cp linux-amd64/helm /usr/local/bin/helm

source <(helm completion bash)

# Wait till the slave nodes get joined and update the kubelet daemon successfully
# number of slaves + 1 master
node_cnt=$(($(/local/repository/scripts/geni-get-param computeNodeCount) + 1))
# 1 node per line - header line
joined_cnt=$(( `kubectl get nodes | wc -l` - 1 ))
echo "Total nodes: $node_cnt Joined: ${joined_cnt}"
while [ $node_cnt -ne $joined_cnt ]
do 
    joined_cnt=$(( `kubectl get nodes |wc -l` - 1 ))
    sleep 1
done
echo "All nodes joined"

# Display for the end-user where the Kubernetes dashboard is, using our public
# hostname that we can get from ipinfo.io - this is based on an assumption that
# the machine would have a public hostname.
echo "Kubernetes is ready at: http://$(curl ipinfo.io -s | jq -r .hostname):8080/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/workloads?namespace=default"

# Also make the link display on every SSH login too, for convenience:
cat <<ASD >> /users/${username}/.ssh/rc
echo "\033[34m==================\033[0m"
echo "\033[1mCoreKube Dashboard:\033[0m http://$(curl -s ipinfo.io | jq -r .hostname):8080/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/workloads?namespace=default"
echo "  When prompted for authentication, press \"Skip\" to use the built-in admin account."
echo "  \033[31;1mWarning:\033[0m This deployment is for research purposes only. Having a publicly accessible admin Kubernetes dashboard like this is \033[31mdangerous\033[0m for anything else."
echo "\033[34m==================\033[0m"
ASD

#Deploy metrics server
sudo kubectl create -f config/test/metrics-server.yaml
# Deploy emulator
sudo kubectl create -f config/deployment.yaml

# Log all the traffic on the Nervion master node
#sudo tcpdump -i any -w ~/tcpdump.pcap &

# to know how much time it takes to instantiate everything.
echo "Setup DONE!"
date
