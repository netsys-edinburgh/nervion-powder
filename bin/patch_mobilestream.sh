
echo 'Patching Java code...'
sudo sed -i 's/b.bind(this.port)/b.bind("192.168.4.80",this.port)/g' /opt/mobilestream-conext/mobilestreamconext/MobileStream-Java/src/jvm/mobilestream/blocks/sctp/SctpConnection.java


cd /opt/mobilestream-conext/mobilestreamconext/MobileStream-Java/src/jvm/
sudo bash JNIHeader.sh


echo 'Patching C++ code...'
for value in {1..6}
do
	sed -i -e '240d' /opt/mobilestream-conext/mobilestreamconext/MobileStream-C++/mobilestream/src/block/mobility_mgt.cc
done

sed -i -e '20s/INTEGRITY_ALGORITHM_ID_128_EIA1/INTEGRITY_ALGORITHM_ID_128_EIA2/' /opt/mobilestream-conext/mobilestreamconext/MobileStream-C++/mobilestream/src/block/integrity.cc
sed -i -e '29s/INTEGRITY_ALGORITHM_ID_128_EIA2/INTEGRITY_ALGORITHM_ID_128_EIA1/' /opt/mobilestream-conext/mobilestreamconext/MobileStream-C++/mobilestream/src/block/integrity.cc

rm /opt/mobilestream-conext/mobilestreamconext/MobileStream-C++/mobilestream/src/block/*-e

echo 'Populating HSS DB with 4096 UEs...'
cd /opt/mobilestream-conext/mobilestreamconext/testbed/hss/
sudo rm LTE_fdd_enodeb.user_db
sudo rm ../storm/LTE_fdd_enodeb.user_db
sudo bash provision.sh 100000
sudo cp LTE_fdd_enodeb.user_db ../storm/

cd /opt/mobilestream-conext/mobilestreamconext/MobileStream-C++/build/
sudo cmake ../
sudo make -j4

cd /opt/mobilestream-conext/mobilestreamconext/MobileStream-Java
sudo bash compile-app.sh