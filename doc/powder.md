# Nervion Powder Profile Overview

Nervion is integrated with the [Powder Platform](https://powderwireless.net/). Here you will find a detailed guide on how to set up Nervion on Powder using the official [Nervion Powder Profile](https://github.com/j0lama/nervion-powder).

For any issues with Nervion on Powder or suggestions, you can contact us at jon.larrea@ed.ac.uk or via the issues section in the [Nervion Powder Profile repository](https://github.com/j0lama/nervion-powder).

# Profile Instantiation

In order to use Nervion, you first need to log in [Powder](https://www.powderwireless.net/login.php). Once you have logged in, you will be redirected to the User Dashboard. If you click in the *Experiment* box (Top-left corner), a drop-down menu will pop up. From that menu, you have to click on the option named "Start Experiment". Now you will need to find the Nervion profile. To do that, click in the "Change Profile" and, using the Search bar, select the profile named "Nervion" by clicking on the "Select Profile" button with the profile selected on the left side. Now, the selected profile should be the Nervion profile. To continue with the instantiation, click on the "Next" button.

Now you have to configure some parameters of the Nervion setup in the Parameterize window:

![Nervion Parameters configuration](/doc/images/parameters.png)

The parameters you can configure in that window are outlined below:

- **Number of slave/compute nodes**: Number of VMs that will be part of the Kubernetes cluster for Nervion.
- **EPC implementation**: Core Network you want to use. Currently, there are six different core networks: four 4G cores (OAI, srsEPC, NextEPC and MobileStream) and two 5G cores (Free5GC and Open5GS).  In case you want to deploy there any other core network, there is another option named "Empty" that deploys an empty machine.
- **EPC hardware**: Type of hardware you want to use in the Core machine. You can get details about each type and its availability [here](https://www.powderwireless.net/resinfo.php).
- **Multiplexer (True or False)**: The Multiplexer is an artefact required by the data plane of most of the core networks. You can disable it if you are not going to use the data plane.
- **(Advanced) Number of cores**: Number of cores of each VM that will be part of the Kubernetes cluster.
- **(Advanced) RAM Size**: RAM Size of each VM that will be part of the Kubernetes cluster.

Once you're done with the parameters, you have to click on "Next" to proceed with the instantiation. Now you need to select the name of the experiment and the Cluster location for Nervion and the Core. You can use the same values used in the image below. 

![Experiment General configuration](/doc/images/parameters2.png)

After configuring the name and locations of the experiment, you have to click on "Next" to proceed to the final step (Scheduling). Unless you need to extend the experiment or schedule it in a specific time frame, you can finalize the instantiation by clicking on "Finish".



# Profile Usage

Once the experiment is ready, you can ssh to all the VMs and machines that are used by clicking "List View". Under List View, you will see a table of all the machines (VMs and physical machines), some information about each machine and the SSH command to access each of them. 

Each experiment must have one machine for the core and one machine named "master" for the master node of the Kubernetes cluster used by Nervion. If the Multiplexer parameter has been selected during the instantiation, another machine named "multiplexer" would be in the list. Finally, there would be a set of slave machines that match with the number of nodes for the cluster that you have selected during the instantiation. The image below shows the List View of an experiment with the multiplexer and only one slave node:

![1-node Nervion experiment](/doc/images/ssh.png)

Installing Kubernetes in the master node and the slave nodes, and deploying Nervion takes some time (5-10 mins). You can check the state of the installation in the master node or in any slave node by ssh'ing to the desired machine and running the following command:
```bash
cat /local/repository/deploy.log
```

Once the Kubernetes installation is done, you can check the state of Nervion by running the following command from the master node:
```bash
kubectl get services
```
If Nervion is ready, the output of the command above should be similar to this:

![kubectl command output](/doc/images/kubectl.png)

#### Running the core

Once the Nervion is ready, it is time to configure the core network before starting the experiment. As mentioned before, this Powder profile contains 6 different core networks that are ready to be evaluated with Nervion ([OAI](https://openairinterface.org/), [srsEPC](https://docs.srslte.com/en/rfsoc/index.html), [NextEPC](https://nextepc.org/), [MobileStream](https://www.flux.utah.edu/paper/277), [Free5GC](https://www.free5gc.org/), and [Open5GS](https://open5gs.org/)). Two of them -- srsEPC and NextEPC -- are automatically deployed when the core machine boots the first time; however, OAI, MobileStream, Free5GC, and Open5GS require the user to manually run some commands to deploy them. You can check if the core is running by listing the process with *ps -ax*.

To run OAI Core Network run the following commands:
```bash
cd /local/repository/bin/
sudo ./run_epc.sh
```

To deploy MobileStream run the following commands:
```bash
cd /local/repository/bin/
sudo bash patch_mobilestream.sh
cd /opt/mobilestream-conext/mobilestreamconext/testbed/storm/
sudo bash setup_mobilestream.sh
cd /opt/mobilestream-conext/mobilestreamconext/MobileStream-Java/
sudo bash run-stateless-control-plane.sh 1 2
```
If you have any problem with MobileStream, please refer to its [original profile](https://gitlab.flux.utah.edu/junguk/mobilestream-profile).

To deploy Free5GC, you will need to run two scripts. The first command will install a custom kernel and the core machine will be rebooted. Then you will need to run the second script.
```bash
# First script
cd /local/repository/scripts/
sudo ./free5gc_stage1.sh
# This script restarts the machine

# Second script
cd /local/repository/scripts/
sudo ./free5gc_stage2.sh
```

To deploy Open5GS, run the following command:
```bash
cd /local/repository/scripts/
sudo ./open5gs_run.sh
```

Once the selected core is running, you can open a new ssh session and run *tcpdump* to get the traffic.

#### Running Nervion

At this point, Nervion should be ready in the Kubernetes cluster, and the core should be running in the core machine. In order to configure Nervion, you need to access the Nervion Controller Web Interface. The Web Interface can be accessed through the master node URL on port 34567. The master node URL can be obtained from the master node SSH command (the part after the @). In the example shown above, the Web Interface can be accessed at ***pcvm606-2.emulab.net:34567***. The Nervion Controler Web Interface looks like this:

![Nervion Controller Web Interface](/doc/images/nervion_controller.png)

In this Powder profile, every core network uses the IP ***192.168.4.80*** (even the empty machine), so the field "MME/AMF IP Address" has to be filled with that IP. You can use a different IP if your core network is not deployed in Powder. Like the core machine, the multiplexer machine always uses the same IP (***192.168.4.81***).

The Control-Plane Mode provides better scalability by disabling the Data-Plane. If this mode is enabled, each UE is no longer a single UE and can reproduce multiple UEs using multi-threading. By default, the number of threads per UE is 100, but this value can be modified through the Web Interface.

The Nervion configuration file (JSON format) is where the RAN architecture and behaviour are specified. A complete guide on the Configuration files can be found [here](/profiles.md). Each of the core networks provided in this profile has its own peculiarities in terms of encryptions keys and MMC/MNC; therefore, we provide a basic configuration file for each core. Each example executes a single UE with one eNB/gNB. These files can be modified following the [Nervion profiles guide](/profiles.md).

- [OAI](https://github.com/j0lama/nervion-powder/blob/master/profiles/config_oai.json)
- [srsEPC](https://github.com/j0lama/nervion-powder/blob/master/profiles/config_srsepc.json)
- [NextEPC](https://github.com/j0lama/nervion-powder/blob/master/profiles/config_nextepc.json)
- [MobileStream](https://github.com/j0lama/nervion-powder/blob/master/profiles/config_mobilestream.json)
- [Free5GC](https://github.com/j0lama/nervion-powder/blob/master/profiles/config_free5gc.json)
- [Open5GS](https://github.com/j0lama/nervion-powder/blob/master/profiles/config_open5gs.json)

Nervion has been containerized in a Docker image with a set of traffic generators (iperf, ping, etc.). However, if another specific tool is needed, you can create a custom Docker image using the official Nervion images as base image. If that is the case, the Slave Docker Image option allows you to specify the Docker image that is going to be used. All the images have to be available at [DockerHub](https://hub.docker.com/). Nervion has two official Docker images:
- **Nervion 4G**: j0lama/ran_slave:latest ([Link](https://hub.docker.com/repository/docker/j0lama/ran_slave))
- **Nervion 5G**: j0lama/ran_slave_5g:latest ([Link](https://hub.docker.com/repository/docker/j0lama/ran_slave_5g))

The latest parameter that can be configured is the refresh time of the web interface that will show the status of each UE and each eNB.

Once all the parameters have been configured, click on "Submit" to start the experiment. The experiment screen shows the state of every UE and eNB with some of the parameters specified in the Nervion configuration file, and it looks like this:

![Experiment screen](/doc/images/nervion_experiment.png)

You can restart the experiment at any time by clicking on "Restart". This action will redirect you back to the configuration screen, and all the pods (UEs and eNBs) will be deleted.



