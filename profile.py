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
import geni.rspec.pg as PG
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
    OAI_SRS_EPC = URN.Image(PN.PNDEFS.PNET_AM, "PhantomNet:srsEPC-OAICN")
    OAI_CONF_SCRIPT = "/usr/bin/sudo /local/repository/bin/config_oai.pl"
    MSIMG = "urn:publicid:IDN+emulab.net+image+PhantomNet:mobilestreamV1.node0"

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
# Create our in-memory model of the RSpec -- the resources we're going
# to request in our experiment, and their configuration.
#
rspec = PG.Request()

#
# Profile parameters.
#

pc.defineParameter("computeNodeCount", "Number of slave/compute nodes",
                   portal.ParameterType.INTEGER, 1)
pc.defineParameter("EPC", "OpenAirInterface, srsLTE or MobileStream",
                   portal.ParameterType.INTEGER, 1)
pc.defineParameter("EPC", "EPC implementation",
                   portal.ParameterType.STRING,"OAI",[("OAI","Open Air Inrterface"),("srsLTE","srsLTE"), ("MobileStream", "MobileStream")])

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
rspec.addTour(tour)


#epclink = request.Link("s1-lan")
usevms = 0
net_d = rspec.EPClan(PN.EPCLANS.NET_D, vmlan = usevms)


netmask="255.255.255.0"



if params.EPC == "OAI":
    epc = rspec.RawPC("epc")
    epc.disk_image = GLOBALS.OAI_EPC_IMG
    epc.Site('EPC')
    epc.addService(PG.Execute(shell="sh", command="/usr/bin/sudo /local/repository/bin/config_oai.pl -r EPC"))
    connectOAI_DS(epc)
elif params.EPC == "srsLTE":
    epc = rspec.RawPC("epc")
    epc.disk_image = GLOBALS.OAI_EPC_IMG
    epc.Site('EPC')
    epc.addService(PG.Execute(shell="sh", command="/usr/bin/sudo /local/repository/scripts/srslte.sh"))
    connectOAI_DS(epc)
elif params.EPC == "MobileStream":
    epc = rspec.RawPC("node0")
    epc.disk_image = GLOBALS.MSIMG
    epc.hardware_type = "d430"
    #epc.Site('EPC')

#epclink.addNode(epc)
cintf = net_d.addMember(epc)
caddr = PG.IPv4Address("192.168.4.80", netmask)
cintf.addAddress(caddr)

multiplexer = rspec.XenVM('multiplexer')
multiplexer.cores = 4
multiplexer.ram = 1024 * 8
multiplexer.routable_control_ip = True
multiplexer.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU18-64-STD'
#multiplexer.Site('Nervion')
multiplexer.addService(PG.Execute(shell="bash", command="python /local/repository/scripts/nervion_mp.py 10.10.1.2 10.10.1.1"))
#epclink.addNode(multiplexer)
cintf = net_d.addMember(multiplexer)
caddr = PG.IPv4Address("192.168.4.81", netmask)
cintf.addAddress(caddr)

# Node kube-server
kube_m = rspec.XenVM('master')
kube_m.cores = 4
kube_m.ram = 1024 * 8
kube_m.routable_control_ip = True
kube_m.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU18-64-STD'
#kube_m.Site('Nervion')
#epclink.addNode(kube_m)
cintf = net_d.addMember(kube_m)
caddr = PG.IPv4Address("192.168.4.82", netmask)
cintf.addAddress(caddr)

master_command = "/local/repository/scripts/master.sh"

kube_m.addService(PG.Execute(shell="bash", command="/local/repository/scripts/master.sh"))

#slave_ifaces = []
for i in range(1,params.computeNodeCount+1):
    kube_s = rspec.XenVM('slave'+str(i))
    kube_s.cores = 4
    kube_s.ram = 1024 * 8
    kube_s.routable_control_ip = True
    kube_s.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU18-64-STD'
    #kube_s.Site('Nervion')
    #epclink.addNode(kube_s)
    cintf = net_d.addMember(kube_s)
    caddr = PG.IPv4Address("192.168.4." + str(i+83), netmask)
    cintf.addAddress(caddr)
    kube_s.addService(PG.Execute(shell="bash", command="/local/repository/scripts/slave.sh"))

#epclink.link_multiplexing = True
#epclink.vlan_tagging = True
#epclink.best_effort = True

net_d.link_multiplexing = True
net_d.vlan_tagging = True
net_d.best_effort = True

#
# Print and go!
#
pc.printRequestRSpec(rspec)