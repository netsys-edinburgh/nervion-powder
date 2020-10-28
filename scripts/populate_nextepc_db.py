import pymongo
import sys


json_string = {
	"imsi":"208930000000000",
	"security":
		{"k":"3F3F473F 2F3FD094 3F3F3F3F 097C6862",
		"amf":"8000",
		"op_type":0,
		"op_value":"00000000 00000000 00000000 00000000",
		"op":'',
		"opc":"E9BE7FB8 9BB01978 E67972CA 8580079E"},
		"ambr":
			{"downlink":1024000,
			"uplink":1024000},
		"pdn":[{"apn":"internet","qos":{"qci":9,"arp":{"priority_level":8,"pre_emption_capability":1,"pre_emption_vulnerability":1}}},{"apn":"oai.ipv4","qos":{"qci":9,"arp":{"priority_level":8,"pre_emption_capability":1,"pre_emption_vulnerability":1}},"ambr":{},"pgw":{}}]}


myclient = pymongo.MongoClient("mongodb://localhost/nextepc")
mydb = myclient["nextepc"]
mycol = mydb['subscribers']

for i in range(1, int(sys.argv[1]) + 1):
	json_string["imsi"] = '20893' + "{:010d}".format(i+1)
	tmp = json_string.copy()
	mycol.insert_one(tmp)

print('Done!')