import pymongo
import sys


json_string = {
	"imsi":"208930000000000",
	"security":
		{"k":"00000000 00000000 00000000 00000000",
		"amf":"8000",
		"op_type":0,
		"op_value":"00000000 00000000 00000000 00000000",
		"op":'',
		"opc":"66E94BD4 EF8A2C3B 884CFA59 CA342B2E"},
		"ambr":
			{"downlink":1024000,
			"uplink":1024000},
		"pdn":[{"apn":"internet","qos":{"qci":9,"arp":{"priority_level":8,"pre_emption_capability":1,"pre_emption_vulnerability":1}}},{"apn":"oai.ipv4","qos":{"qci":9,"arp":{"priority_level":8,"pre_emption_capability":1,"pre_emption_vulnerability":1}},"ambr":{},"pgw":{}}]}


myclient = pymongo.MongoClient("mongodb://localhost/nextepc")
mydb = myclient["nextepc"]
mycol = mydb['subscribers']

for i in range(int(sys.argv[1])):
	json_string["imsi"] = '20893' + "{:010d}".format(i+1)
	tmp = json_string.copy()
	mycol.insert_one(tmp)

print('Done!')