# Nervion: A Cloud Native RAN Emulator for Scalable and Flexible Mobile Core Evaluation

Nervion is a cloud-native RAN emulator designed to perform large-scale mobile core network evaluations. Nervion provides maximum flexibility by allowing the emulation of virtually any RAN scenario along with the customization of the control and data plane workload of every emulated UE. Nervion leverages Kubernetes as an orchestrator not only to ease use of multiple machines (in a cluster) to emulate tens of thousands of UEs but also to provide portability (i.e., it can be deployed in any Kubernetes cluster). We have developed a prototype implementation of Nervion that can be used to evaluate standard-compliant 4G and 5G core networks.

For more details about the Nervion system, please refer to the [*Nervion Paper*](https://www.research.ed.ac.uk/en/publications/nervion-a-cloud-native-ran-emulator-for-scalable-and-flexible-mob) published in [ACM MobiCom'21](https://www.sigmobile.org/mobicom/2021/index.html).

# Nervion Powder Profile

Nervion is currently accessible through the [Powder platform](https://powderwireless.net/). We have published a Powder Profile that allows evaluating six different target core network implementations with Nervion. A detailed how-to guide of using Nervion over Powder can be found [here](/doc/powder.md).

# Source Code

This repository contains the source code of the Nervion's Powder Profile released under the MIT license.

Source code of Nervion will also be made available upon request. For getting access to it, please contact *jon.larrea@ed.ac.uk*.

# Sponsorship

If you find Nervion useful, please consider sponsoring my work.
