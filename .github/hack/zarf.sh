#!/usr/bin/env bash

set -u
set -o pipefail

rm -rf   .direnv/bin
mkdir -p .direnv/bin

export K3S_VERSION=$(yq '.package.create.set.k3s_version' zarf-config.yaml)
export K3SUP_VERSION=$(yq '.package.create.set.k3sup_version' zarf-config.yaml)
declare -a ARCH=("" "-arm64")

for arch in "${ARCH[@]}"; do
  echo "::debug::message='downloading k3s$arch at version $K3S_VERSION'"
  curl ${GITHUB_TOKEN:+" -u \":$GITHUB_TOKEN\""} -s -L -o ./.direnv/bin/k3s$arch https://github.com/k3s-io/k3s/releases/download/$K3S_VERSION/k3s$arch

  chmod +x .direnv/bin/k3s$arch

  export sha=$(sha256sum .direnv/bin/k3s$arch | awk '{ print $1 }')
  echo "::debug::sha='$sha'"

  export yq_sha=""
  if [ "$arch" = "" ]; then
    yq_sha=$(printf '.package.create.set.k3s_sha_amd = "%s"' "$sha")
  else
    yq_sha=$(printf '.package.create.set.k3s_sha_arm = "%s"' "$sha")
  fi
  echo "::debug::yq_sha='$yq_sha'"

  yq -i "$yq_sha" zarf-config.yaml

  echo "::debug::message='downloading  k3sup$arch  at version $K3SUP_VERSION'"
  curl ${GITHUB_TOKEN:+" -u \":$GITHUB_TOKEN\""} -s -L -o ./.direnv/bin/k3sup$arch https://github.com/alexellis/k3sup/releases/download/$K3SUP_VERSION/k3sup$arch

  chmod +x .direnv/bin/k3sup$arch

  export sha=$(sha256sum .direnv/bin/k3sup$arch | awk '{ print $1 }')
  echo "::debug::sha='$sha'"

  export yq_sha=""
  if [ "$arch" = "" ]; then
    yq_sha=$(printf '.package.create.set.k3sup_sha_amd = "%s"' "$sha")
  else
    yq_sha=$(printf '.package.create.set.k3sup_sha_arm = "%s"' "$sha")
  fi
  echo "::debug::yq_sha='$yq_sha'"

  yq -i "$yq_sha" zarf-config.yaml
done

rm -rf   files
mkdir -p files

echo "::debug::pulling air-gap image list"
curl ${GITHUB_TOKEN:+" -u \":$GITHUB_TOKEN\""} -s -L -o files/air-gap.txt https://github.com/k3s-io/k3s/releases/download/$K3S_VERSION/k3s-images.txt

echo "::debug::pulling k3s.service and updating to be an agent"
curl ${GITHUB_TOKEN:+" -u \":$GITHUB_TOKEN\""} -s -L -o files/k3s-agent.service https://raw.githubusercontent.com/k3s-io/k3s/refs/tags/$K3S_VERSION/k3s.service
sed -i 's!/usr/local/bin/k3s server!/var/lib/rancher/k3s/bin/k3s agent --write-kubeconfig-mode=700 --write-kubeconfig /root/.kube/config ###ZARF_VAR_K3S_ARGS###!g' files/k3s-agent.service

echo "::debug::pulling k3s.service and updating to be an server"
curl ${GITHUB_TOKEN:+" -u \":$GITHUB_TOKEN\""} -s -L -o files/k3s-server.service https://raw.githubusercontent.com/k3s-io/k3s/refs/tags/$K3S_VERSION/k3s.service
sed -i 's!/usr/local/bin/k3s server!/var/lib/rancher/k3s/bin/k3s server --write-kubeconfig-mode=700 --write-kubeconfig /root/.kube/config ###ZARF_VAR_K3S_ARGS###!g' files/k3s-server.service
