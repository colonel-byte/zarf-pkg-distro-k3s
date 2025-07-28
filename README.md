# Zarf `distro-k3s`

This is a very simple zarf package that bundles all the images, binaries, and systemd files for boot-strapping `k3s` inside an air-gapped network.

## Components

- `binary`
    - **required**
    - Validates that the system meets k8s stands for nodes
    - Stages the `k3s` binary at `/var/lib/rancher/k3s/bin/k3s`
    - Crates symbolic links for the following:
        - `/var/lib/rancher/k3s/bin/kubectl`
        - `/var/lib/rancher/k3s/bin/ctr`
        - `/var/lib/rancher/k3s/bin/crictl`
- `server`
    - **optional**
    - Create the systemd service file for starting a server
    - Create symbolic link that enables the service to run during startup
    - Additional `k3s` args can be passed doing the following:
        - `zarf package deploy --component="server" --set k3s_args="--disable traefik"`
        - See official [`server`](https://docs.k3s.io/cli/server) args
- `agent`
    - **optional**
    - Create the systemd service file for starting an agent
    - Create symbolic link that enables the service to run during startup
    - Additional `k3s` args can be passed doing the following:
        - `zarf package deploy --component="agent" --set k3s_args="--token abc123"`
        - See official [`agent`](https://docs.k3s.io/cli/agent) args
- `images`
    - **required**
    - Caches required offline images for initial `k3s` deployment at `/var/lib/k0s/images`
