import pymongo
import sys

ue_template = { 'imsi': '208930000000001', 
                'pdn': [
                        {'apn': 'internet',
                        'pcc_rule': [], 
                        'ambr': {
                                'downlink': 1024000, 
                                'uplink': 1024000}, 
                        'qos': {
                                'qci': 9, 
                                'arp': {'priority_level': 8, 'pre_emption_vulnerability': 1, 'pre_emption_capability': 1}}, 
                        'type': 2}], 
                'ambr': {'downlink': 1024000, 'uplink': 1024000},
                'subscribed_rau_tau_timer': 12,
                'network_access_mode': 2,
                'subscriber_status': 0,
                'access_restriction_data': 32,
                'security': {'k': '465B5CE8 B199B49F AA5F0A2E E238A6BC', 'amf': '8000', 'op': None, 'opc': 'E8ED289D EBA952E4 283B54E8 8E6183CA', 'sqn': 320}, 
                '__v': 0}

cli = pymongo.MongoClient("mongodb://localhost/open5gs")

db = cli['open5gs']

col = db['subscribers']

for i in range(int(sys.argv[1])):
        ue_template['imsi'] = '20893' + "{:010d}".format(i+1)
        tmp = ue_template.copy()
        col.insert_one(tmp)

print('Done!')