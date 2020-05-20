# Honours Project repository

Repository containing any code relevant to my honours project (undergraduate thesis) at the University of Edinburgh. The project aim initially was to look at the security aspects of network slicing in the 5G core network, but is currently in a state of flux and this repository will be updated as and when the goal settles down.

This repository acts as the backing repository for a POWDER profile (see the [POWDER docs](http://docs.powderwireless.net/creating-profiles.html#\(part._repo-based-profiles\))). If left as is, it will create an environment with the following parameters:

 - One master node and N slave nodes (configurable in profile)
   - Can also select VM or raw PC
 - Latest Kubernetes from http://apt.kubernetes.io/kubernetes-xenial
 - Kubeadm initiated cluster
 - Kubernetes Dashboard v1.10.1
 - jid for json parsing
 - helm v3.1.0
   - `stable` repo from https://kubernetes-charts.storage.googleapis.com
 - Latest metrics-server from helm `stable` repo
 - The `hpa_controller/deploy` deployment

## POWDER configuration guide

First, fork this repository (or clone and upload to hosting service of your choice). Then create a new profile in POWDER as described in the [docs](http://docs.powderwireless.net/creating-profiles.html#\(part._repo-based-profiles\)) with the URL of your forked repository. From there, change the appropriate files in this repository to create your new profile. Important files are described below.

It's worth noting that this repository will be cloned into `/local/repository` on all nodes in your cluster.

### `profile.py`

This contains a [`geni-lib`](https://docs.powderwireless.net/geni-lib/) description of the hardware in the experiment. If you want to change network topology, type of machine available or specifications of each machine, this is the file to do it in. The [POWDER docs](http://docs.powderwireless.net/geni-lib.html) have some good information on using `geni-lib` although the actual [API documentation](https://docs.powderwireless.net/geni-lib/) is a bit sparse.

You can debug this script locally by running `python profile.py` as long as you have previously installed `geni-lib` (`pip install geni-lib`).

### `scripts/master.sh` and `scripts/slave.sh`

These files contain bash installation scripts that are run on startup of each of the nodes. `master.sh`  is the script run on the master node and `slave.sh` is the script run on all slave nodes. These install required packages, set up the kubernetes cluster and deploy the applications. `master.sh` contains most of the setup and is used as the primary node you `ssh` into.

### `config/kubeadm-config.yaml`

This file contains configuration passed to `kubeadm init`. You can find help on available options at the links below:

 - [kubeadm init - Kubernetes](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/)
 - [API docs](https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta2)

This file contains the below lines:

``` yaml
controllerManager:
  extraArgs:
    horizontal-pod-autoscaler-downscale-stabilization: "10s"
```

This is specific to the HPA controller experiments and should be removed for most other Kubernetes configurations.

### `config/metrics-server-values.yaml`

These are values passed to the helm template for `metrics-server`. Help can be found at the below links.

 - [charts/stable/metrics-server (Helm repo)](https://github.com/helm/charts/tree/master/stable/metrics-server)
 - [kubernetes-sigs/metrics-server (Kubernetes repo)](https://github.com/kubernetes-sigs/metrics-server)

## Experiments

The below folders each contain code for a specific experiment to do with this project and a README for that experiment.

### `replication_controller`

This folder contains code that attempts to measure the time it takes for each loop of the replication controller in Kubernetes to run. It does this by measuring the time it takes to restart a Python script that keeps killing itself.

### `hpa_controller`

The Horizontal Pod Autoscaler (HPA) is a kubernetes controller that will create/destroy pods based on their CPU usage. This experiment aims to detect the time it takes for the HPA to run its control loop by measuring the time it takes for a new pod to be created/old pod to die. By measuring this, hopefully information about the Kubernetes cluster that wasn't otherwise available will be revealed.
