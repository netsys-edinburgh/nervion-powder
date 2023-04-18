# Nervion: A Cloud Native RAN Emulator for Scalable and Flexible Mobile Core Evaluation

Nervion is a cloud-native RAN emulator designed to perform large-scale mobile core network evaluations. Nervion provides maximum flexibility by allowing the emulation of virtually any RAN scenario along with the customization of the control and data plane workload of every emulated UE. Nervion leverages Kubernetes as an orchestrator not only to ease use of multiple machines (in a cluster) to emulate tens of thousands of UEs but also to provide portability (i.e., it can be deployed in any Kubernetes cluster). We have developed a prototype implementation of Nervion that can be used to evaluate standard-compliant 4G and 5G core networks.

For more details about the Nervion system, please refer to the [*Nervion Paper*](https://www.research.ed.ac.uk/en/publications/nervion-a-cloud-native-ran-emulator-for-scalable-and-flexible-mob) published in [ACM MobiCom'21](https://www.sigmobile.org/mobicom/2021/index.html).

# Nervion Powder Profile

Nervion is currently accessible through the [Powder platform](https://powderwireless.net/). We have published a Powder Profile that allows evaluating six different target core network implementations with Nervion. A detailed how-to guide of using Nervion over Powder can be found [here](/doc/powder.md).

# Source Code

This repository contains the source code of the Nervion's Powder Profile released under the MIT license.

Source code of Nervion will also be made available upon request. For getting access to it, please contact *jon.larrea@ed.ac.uk*.

# Cite Nervion
```
@inproceedings{10.1145/3447993.3483248,
author = {Larrea, Jon and Marina, Mahesh K. and Van der Merwe, Jacobus},
title = {Nervion: A Cloud Native RAN Emulator for Scalable and Flexible Mobile Core Evaluation},
year = {2021},
isbn = {9781450383424},
publisher = {Association for Computing Machinery},
address = {New York, NY, USA},
url = {https://doi.org/10.1145/3447993.3483248},
doi = {10.1145/3447993.3483248},
abstract = {Given the wide interest on mobile core systems and their pivotal role in the operations of current and future mobile network services, we focus on the issue of their effective evaluation, considering the radio access network (RAN) emulation methodology. While there exist a number of different RAN emulators, following different paradigms, they are limited in their scalability and flexibility, and moreover there is no one commonly accepted RAN emulator. Motivated by this, we present Nervion, a scalable and flexible RAN emulator for mobile core system evaluation that takes a novel cloud-native approach. Nervion embeds innovations to enable scalability via abstractions and RAN element containerization, and additionally supports an even more scalable control-plane only mode. It also offers ample flexibility in terms of realizing arbitrary RAN emulation scenarios, mapping them to compute clusters, and evaluating diverse core system designs. We develop a prototype implementation of Nervion that supports 4G and 5G standard compliant RAN emulation and integrate it into the Powder platform to benefit the research community. Our experimental evaluations validate its correctness and demonstrate its scalability relative to representative set of existing RAN emulators. We also present multiple case studies using Nervion that highlight its flexibility to support diverse types of mobile core evaluations.},
booktitle = {Proceedings of the 27th Annual International Conference on Mobile Computing and Networking},
pages = {736–748},
numpages = {13},
keywords = {evaluation, RAN emulation, cloud native, mobile core systems},
location = {New Orleans, Louisiana},
series = {MobiCom '21}
}
```

# Sponsorship

If you find Nervion useful, please consider sponsoring my work.
[:heart: Sponsor on GitHub](https://github.com/sponsors/j0lama)
