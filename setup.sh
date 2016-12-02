#!/bin/bash

sudo apt install -y git make jq apt-transport-https ca-certificates dnsutils

# Install docker
sudo apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual
sudo apt install -y linux-image-extra-$(uname -r) linux-image-extra-virtual
sudo apt install -y docker-enginer

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
if [[ ! \( -d $HOME/go \) ]];
  mkdir $HOME/go
fi
export GOPATH=$HOME/go
go get github.com/pachyderm/pachyderm
cd $GOPATH/github.com/pachyderm/pachyderm
go get ./...
