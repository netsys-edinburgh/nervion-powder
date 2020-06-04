#!/usr/bin/env python

kube_description= \
"""
Emulator demo
"""
kube_instruction= \
"""
Not instructions yet
"""

#
# Standard geni-lib/portal libraries
#
import geni.portal as portal
import geni.rspec.pg as rspec
import geni.rspec.emulab as elab
import geni.rspec.igext as IG
import geni.urn as URN



#
# PhantomNet extensions.
#
import geni.rspec.emulab.pnext as PN

#
# Globals
#
class GLOBALS(object):
    OAI_DS = "urn:publicid:IDN+emulab.net:phantomnet+ltdataset+oai-develop"
    OAI_SIM_DS = "urn:publicid:IDN+emulab.net:phantomnet+dataset+PhantomNet:oai"
    UE_IMG  = URN.Image(PN.PNDEFS.PNET_AM, "PhantomNet:ANDROID444-STD")
    ADB_IMG = URN.Image(PN.PNDEFS.PNET_AM, "PhantomNet:UBUNTU14-64-PNTOOLS")
    OAI_EPC_IMG = URN.Image(PN.PNDEFS.PNET_AM, "PhantomNet:UBUNTU16-64-OAIEPC")
    OAI_ENB_IMG = URN.Image(PN.PNDEFS.PNET_AM, "PhantomNet:OAI-Real-Hardware.enb1")
    OAI_SIM_IMG = URN.Image(PN.PNDEFS.PNET_AM, "PhantomNet:UBUNTU14-64-OAI")
    OAI_CONF_SCRIPT = "/usr/bin/sudo /local/repository/bin/config_oai.pl"
    NUC_HWTYPE = "nuc5300"
    UE_HWTYPE = "nexus5"

def connectOAI_DS(node):
    # Create remote read-write clone dataset object bound to OAI dataset
    bs = request.RemoteBlockstore("ds-%s" % node.name, "/opt/oai")
    bs.dataset = GLOBALS.OAI_DS
    bs.Site('EPC')
    bs.rwclone = True
    # Create link from node to OAI dataset rw clone
    node_if = node.addInterface("dsif_%s" % node.name)
    bslink = request.Link("dslink_%s" % node.name)
    bslink.addInterface(node_if)
    bslink.addInterface(bs.interface)
    bslink.vlan_tagging = True
    bslink.best_effort = True

#
# This geni-lib script is designed to run in the PhantomNet Portal.
#
pc = portal.Context()

#
# Profile parameters.
#

sim_hardware_types = ['d430','d740']

pc.defineParameter("computeNodeCount", "Number of slave/compute nodes",
                   portal.ParameterType.INTEGER, 1)
pc.defineParameter("useVMs", "Use virtual machines (true) or raw PCs (false)",
                   portal.ParameterType.BOOLEAN, True)
pc.defineParameter("nodeType", "Type of node to use", portal.ParameterType.NODETYPE, "d430")

params = pc.bindParameters()

#
# Give the library a chance to return nice JSON-formatted exception(s) and/or
# warnings; this might sys.exit().
#
pc.verifyParameters()

#
# Create our in-memory model of the RSpec -- the resources we're going
# to request in our experiment, and their configuration.
#
request = pc.makeRequestRSpec()

tour = IG.Tour()
tour.Description(IG.Tour.TEXT,kube_description)
tour.Instructions(IG.Tour.MARKDOWN,kube_instruction)
request.addTour(tour)


epclink = request.Link("s1-lan")


epc1 = request.XenVM('epc')
epc1.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU18-64-STD'
epc1.Site('EPC')
epclink.addNode(epc1)


## Add OAI EPC (HSS, MME, SPGW) node.
#epc = request.RawPC("epc2")
#epc.disk_image = GLOBALS.OAI_EPC_IMG
#epc.Site('EPC')
#epc.addService(rspec.Execute(shell="sh", command="/usr/bin/sudo /local/repository/bin/config_oai.pl -r EPC"))
#connectOAI_DS(epc)
#epclink.addNode(epc)

# Node kube-server
if params.useVMs:
    kube_m = request.XenVM('master')
    kube_m.cores = 4
    kube_m.ram = 1024 * 8
    kube_m.routable_control_ip = True
else:
    kube_m = request.RawPC('master')
    kube_m.hardware_type = params.nodeType
# kube_m.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU16-64-STD'
kube_m.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU18-64-STD'
kube_m.Site('Nervion')
epclink.addNode(kube_m)
#iface0 = kube_m.addInterface('interface-0')

master_command = "/local/repository/scripts/master.sh"

kube_m.addService(rspec.Execute(shell="bash", command="/local/repository/scripts/master.sh"))

#slave_ifaces = []
for i in range(1,params.computeNodeCount+1):
    if params.useVMs:
        kube_s = request.XenVM('slave'+str(i))
        kube_s.cores = 4
        kube_s.ram = 1024 * 8
        kube_s.routable_control_ip = True
    else:
        kube_s = request.RawPC('slave'+str(i))
        kube_s.hardware_type = params.nodeType
    kube_s.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU18-64-STD'
    kube_s.Site('Nervion')
    epclink.addNode(kube_s)
    kube_s.addService(rspec.Execute(shell="bash", command="/local/repository/scripts/slave.sh"))

epclink.link_multiplexing = True
epclink.vlan_tagging = True
epclink.best_effort = True

#
# Print and go!
#
pc.printRequestRSpec(request)