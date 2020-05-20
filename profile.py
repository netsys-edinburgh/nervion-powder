kube_description= \
"""
Emulator demo

"""
kube_instruction= \
"""
Not instructions yet
"""

# Import the Portal object.
import geni.portal as portal
# Import the ProtoGENI library.
import geni.rspec.pg as pg
# Import the Emulab specific extensions.
import geni.rspec.emulab as emulab
import geni.rspec.igext as IG
import geni.rspec.pg as RSpec
import geni.urn as URN

#
# PhantomNet extensions.
#
import geni.rspec.emulab.pnext as PN

# Create a portal object,
pc = portal.Context()

# leared this from: https://www.emulab.net/portal/show-profile.php?uuid=f6600ffd-e5a7-11e7-b179-90e2ba22fee4
pc.defineParameter("computeNodeCount", "Number of slave/compute nodes",
                   portal.ParameterType.INTEGER, 1)
pc.defineParameter("useVMs", "Use virtual machines (true) or raw PCs (false)",
                   portal.ParameterType.BOOLEAN, True)
pc.defineParameter("nodeType", "Type of node to use", portal.ParameterType.NODETYPE, "d430")

params = pc.bindParameters()

# Create a Request object to start building the RSpec.
request = pc.makeRequestRSpec()


#rspec = RSpec.Request()
tour = IG.Tour()
tour.Description(IG.Tour.TEXT,kube_description)
tour.Instructions(IG.Tour.MARKDOWN,kube_instruction)
request.addTour(tour)

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
kube_m.Site('Site 1')
iface0 = kube_m.addInterface('interface-0')

master_command = "/local/repository/scripts/master.sh"

#kube_m.addService(pg.Execute(shell="bash", command=master_command))

slave_ifaces = []
for i in range(1,params.computeNodeCount+1):
    if params.useVMs:
        kube_s = request.XenVM('slave'+str(i))
        kube_s.cores = 4
        kube_s.ram = 1024 * 8
        kube_s.routable_control_ip = True
    else:
        kube_s = request.RawPC('slave'+str(i))
        kube_s.hardware_type = params.nodeType
    # kube_s.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU16-64-STD'
    kube_s.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU18-64-STD'
    kube_s.Site('Site 1')
    slave_ifaces.append(kube_s.addInterface('interface-'+str(i)))
#    kube_s.addService(pg.Execute(shell="bash", command="/local/repository/scripts/slave.sh"))


# Create a Node for the EPC
if params.useVMs:
    epc_node = request.XenVM('epc')
    epc_node.cores = 4
    epc_node.ram = 1024 * 8
    epc_node.routable_control_ip = True
else:
    epc_node = request.RawPC('epc')
    epc_node.hardware_type = params.nodeType
epc_node.disk_image = URN.Image(PN.PNDEFS.PNET_AM, "PhantomNet:UBUNTU16-64-OAIEPC")
epc_node.Site('Site 1')
epc_iface = epc_node.addInterface('interface-'+str(params.computeNodeCount+1))
epc_node.addService(rspec.Execute(shell="sh", command="/usr/bin/sudo /local/repository/bin/config_oai.pl -r EPC"))


# Link link-m
link_m = request.Link('link-0')
link_m.Site('undefined')
# Adding interfaces
link_m.addInterface(iface0)
link_m.addInterface(epc_iface)
for i in range(params.computeNodeCount):
    link_m.addInterface(slave_ifaces[i])

# Print the generated rspec
pc.printRequestRSpec(request)
