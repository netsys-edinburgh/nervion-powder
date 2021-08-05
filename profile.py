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
    MSIMG = "urn:publicid:IDN+emulab.net+image+PhantomNet:mobilestream-v1"

def connectOAI_DS(node):
    # Create remote read-write clone dataset object bound to OAI dataset
    bs = rspec.RemoteBlockstore("ds-%s" % node.name, "/opt/oai")
    bs.dataset = GLOBALS.OAI_DS
    bs.Site('Core')
    bs.rwclone = True
    # Create link from node to OAI dataset rw clone
    node_if = node.addInterface("dsif_%s" % node.name)
    bslink = rspec.Link("dslink_%s" % node.name)
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

pc.defineParameter("computeNodeCount", "Number of slave/compute nodes",
                   portal.ParameterType.INTEGER, 1)
pc.defineParameter("EPC", "EPC implementation",
                   portal.ParameterType.STRING,"OAI",[("OAI","Open Air Inrterface"),("srsLTE","srsLTE"), ("MobileStream", "MobileStream"), ("NextEPC", "NextEPC"), ("free5GC", "free5GC"), ("Open5GS", "Open5GS"), ("Test", "Test")])
pc.defineParameter("Hardware", "EPC hardware",
                   portal.ParameterType.STRING,"d430",[("d430","d430"),("d710","d710"), ("d820", "d820"), ("pc3000", "pc3000")])
pc.defineParameter("multi", "Multiplexer (True or False)",
                   portal.ParameterType.BOOLEAN, True)
pc.defineParameter("cores", "Number of cores",
                   portal.ParameterType.STRING,"4",[("4","4"),("6","6"), ("8", "8"), ("10", "10"), ("12", "12")],
                   longDescription="Number of cores of each Nervion node.",
                   advanced=True)
pc.defineParameter("ram", "RAM size",
                   portal.ParameterType.STRING,"4",[("4","4"),("8","8"), ("12", "12"), ("16", "16"), ("20", "20"), ("24", "24"), ("32", "32")],
                   longDescription="RAM size (GB)",
                   advanced=True)
pc.defineParameter("ck_nodes", "Number of slave/compute nodes for the Test Core",
                   portal.ParameterType.INTEGER, 1, advanced=True)


params = pc.bindParameters()

#
# Give the library a chance to return nice JSON-formatted exception(s) and/or
# warnings; this might sys.exit().
#
pc.verifyParameters()


if params.EPC == "OAI":
    rspec = pc.makeRequestRSpec()
    epc = rspec.RawPC("epc")
    epc.disk_image = GLOBALS.OAI_EPC_IMG
    epc.addService(PG.Execute(shell="sh", command="/usr/bin/sudo /local/repository/bin/config_oai.pl -r EPC"))
    connectOAI_DS(epc)
elif params.EPC == "srsLTE":
    rspec = pc.makeRequestRSpec()
    epc = rspec.RawPC("epc")
    epc.disk_image = GLOBALS.OAI_EPC_IMG
    epc.addService(PG.Execute(shell="sh", command="/usr/bin/sudo /local/repository/scripts/srslte.sh"))
elif params.EPC == "MobileStream":
    rspec = PG.Request()
    epc = rspec.RawPC("node0")
    epc.disk_image = GLOBALS.MSIMG
elif params.EPC == "NextEPC":
    rspec = PG.Request()
    epc = rspec.RawPC("epc")
    epc.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU18-64-STD'
    epc.addService(PG.Execute(shell="sh", command="/usr/bin/sudo /local/repository/scripts/nextepc.sh"))
elif params.EPC == "Open5GS":
    rspec = PG.Request()
    epc = rspec.RawPC("epc")
    epc.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU18-64-STD'
    epc.addService(PG.Execute(shell="sh", command="/usr/bin/sudo /local/repository/scripts/open5gs.sh"))
elif params.EPC == "free5GC":
    rspec = PG.Request()
    epc = rspec.RawPC("epc")
    epc.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU18-64-STD'
elif params.EPC == "Test":
    rspec = PG.Request()
    ck_master = rspec.XenVM('masterck')
    ck_master.cores = 4
    ck_master.ram = 1024 * 8
    ck_master.routable_control_ip = True
    ck_master.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU18-64-STD'
    ck_master.Site('CK')
    ck_master.addService(PG.Execute(shell="bash", command="/local/repository/scripts/ck_master.sh"))


tour = IG.Tour()
tour.Description(IG.Tour.TEXT,kube_description)
tour.Instructions(IG.Tour.MARKDOWN,kube_instruction)
rspec.addTour(tour)

netmask="255.255.255.0"

epclink = rspec.Link("s1-lan")

if params.EPC == 'Test':
    iface = ck_master.addInterface()
    iface.addAddress(PG.IPv4Address("192.168.4.80", netmask))
    epclink.addInterface(iface)
else:
    epc.hardware_type = params.Hardware
    epc.Site('Core')
    iface = epc.addInterface()
    iface.addAddress(PG.IPv4Address("192.168.4.80", netmask))
    epclink.addInterface(iface)

# CK Slaves
if params.EPC == 'Test':
    for i in range(0,params.ck_nodes):
        ck_s = rspec.XenVM('ck_slave'+str(i))
        ck_s.cores = int(params.cores)
        ck_s.ram = 1024 * int(params.ram)
        ck_s.routable_control_ip = True
        ck_s.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU18-64-STD'
        ck_s.Site('CK')
        iface = ck_s.addInterface()
        iface.addAddress(PG.IPv4Address("192.168.4." + str(79-i), netmask))
        epclink.addInterface(iface)
        ck_s.addService(PG.Execute(shell="bash", command="/local/repository/scripts/ck_slave.sh"))


# MULTIPLEXER
if params.multi == True:    
    multiplexer = rspec.XenVM('multiplexer')
    multiplexer.cores = 2
    multiplexer.ram = 1024 * 4
    multiplexer.routable_control_ip = True
    multiplexer.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU18-64-STD'
    multiplexer.Site('Nervion')
    iface = multiplexer.addInterface()
    iface.addAddress(PG.IPv4Address("192.168.4.81", netmask))
    epclink.addInterface(iface)
    multiplexer.addService(PG.Execute(shell="bash", command="/local/repository/scripts/multiplexer/run.sh"))


# Nervion Master
kube_m = rspec.XenVM('master')
kube_m.cores = 4
kube_m.ram = 1024 * 8
#kube_m = rspec.RawPC("master")
#kube_m.hardware_type = params.Hardware
kube_m.routable_control_ip = True
kube_m.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU18-64-STD'
kube_m.Site('Nervion')
iface = kube_m.addInterface()
iface.addAddress(PG.IPv4Address("192.168.4.82", netmask))
epclink.addInterface(iface)
kube_m.addService(PG.Execute(shell="bash", command="/local/repository/scripts/master.sh"))

# Nervion Slaves
for i in range(0,params.computeNodeCount):
    kube_s = rspec.XenVM('slave'+str(i))
    kube_s.cores = int(params.cores)
    kube_s.ram = 1024 * int(params.ram)
    #kube_s = rspec.RawPC('slave'+str(i))
    #kube_s.hardware_type = params.Hardware
    kube_s.routable_control_ip = True
    kube_s.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU18-64-STD'
    kube_s.Site('Nervion')
    iface = kube_s.addInterface()
    iface.addAddress(PG.IPv4Address("192.168.4." + str(i+83), netmask))
    epclink.addInterface(iface)
    kube_s.addService(PG.Execute(shell="bash", command="/local/repository/scripts/slave.sh"))



epclink.link_multiplexing = True
epclink.vlan_tagging = True
epclink.best_effort = True



#
# Print and go!
#
pc.printRequestRSpec(rspec)
