#!/bin/bash

# Install packages
sudo apt update
sudo apt install -y git make jq dnsutils
sudo apt upgrade -y

# Install recent version of go
os=$( uname -o )
[[ "${os}" == "GNU/Linux" ]] && os="linux"

golang_version="$( env | grep GOLANG_VERSION )"
[[ -z "${golang_version}" ]] && golang_version=1.7.4

arch="$( uname -m )"
[[ "${arch}" == "x86_64" ]] && arch="amd64"

curl -O "https://storage.googleapis.com/golang/go${golang_version}.${os}-${arch}.tar.gz"
sudo tar -C /usr/local -xzf go${golang_version}.${os}-${arch}.tar.gz

# Install environment variables
export GOPATH=$HOME/go
export PATH=$HOME/go/bin:$PATH >>$HOME/.bashrc
echo -e '\nexport GOPATH=$HOME/go\nexport PATH=$HOME/go/bin:$PATH' >>$HOME/.bashrc

# Install docker
sudo apt install -y apt-transport-https ca-certificates
sudo apt-key adv \
  --keyserver hkp://ha.pool.sks-keyservers.net:80 \
  --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" \
  | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update
sudo apt upgrade -y
sudo apt install -y linux-image-extra-$(uname -r) linux-image-extra-virtual
sudo apt install -y docker-engine
sudo service docker start

function run_loud {
  echo "${@}"
  eval "${@}"
}

# Install kubectl
latest_release="$(
  curl -s https://api.github.com/repos/kubernetes/kubernetes/releases \
    | jq '.[].name' \
    | sed -e's/^"\(.*\)"$/\1/' \
    | grep -Ev 'alpha|beta' \
    | sort \
    | tail -n 1
)"
echo "Getting latest kubectl release (${latest_release})"
echo curl -L --progress-bar "https://storage.googleapis.com/kubernetes-release/release/${latest_release}/kubernetes-client-linux-amd64.tar.gz"
curl -L --progress-bar "https://storage.googleapis.com/kubernetes-release/release/${latest_release}/kubernetes-client-linux-amd64.tar.gz" >/tmp/kubectl.new.tar.gz

if [[ -d /tmp/kubectl.new ]]; then
  rm -r /tmp/kubectl.new
fi
run_loud mkdir /tmp/kubectl.new
run_loud tar -xzf /tmp/kubectl.new.tar.gz -C /tmp/kubectl.new
echo sudo mv /tmp/kubectl.new/kubernetes/client/bin/kubectl /usr/local/bin/kubectl
sudo mv /tmp/kubectl.new/kubernetes/client/bin/kubectl /usr/local/bin/kubectl
sudo chmod +x /usr/local/bin/kubectl

echo -e "remember to run:\n  export GOPATH=\$HOME/go"
if [[ ! ( -d $HOME/go ) ]]; then
  mkdir $HOME/go
fi
go get github.com/pachyderm/pachyderm

# Install pachctl
make install
cd $GOPATH/src/github.com/pachyderm/pachyderm

# Add user to docker group, and tell them to logout and log in, to reevaluate group memberships
sudo usermod -aG docker $USER
echo "$USER has been added to the Docker group. Run 'logout' and log back in to run docker commands"
